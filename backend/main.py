from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import numpy as np
import onnxruntime as ort
import joblib
import os
from datetime import datetime
from collections import deque, defaultdict
from supabase import create_client, Client
from feature_extractor import extract_features

app = FastAPI(title="SmartCalm API", version="2.0.0")
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

sess       = ort.InferenceSession("model/smartcalm_mlp.onnx")
scaler     = joblib.load("model/mlp_scaler.pkl")
LABELS     = {0: "Calm", 1: "Mild", 2: "High"}
LABELS_INV = {"Calm": 0, "Mild": 1, "High": 2}

WINDOW_SIZE = 60
buffers: dict = {}
prediction_counter: dict = {}

class SensorReading(BaseModel):
    device_id: str
    user_id:   str
    timestamp: str
    bvp:       float
    eda:       float
    temp:      float
    acc_x:     float
    acc_y:     float
    acc_z:     float

class PredictionResponse(BaseModel):
    device_id:     str
    user_id:       str
    timestamp:     str
    reading_id:    Optional[str] = None
    stress_level:  str
    stress_code:   int
    confidence:    float
    probabilities: dict
    heart_rate:    Optional[float] = None
    skin_temp:     Optional[float] = None
    skin_response: Optional[float] = None
    movement:      Optional[float] = None
    window_size:   int
    ready:         bool

class CalmSessionStart(BaseModel):
    user_id:       str
    reading_id:    Optional[str] = None
    stress_level:  str
    activity_type: str
    activity_name: Optional[str] = None

class CalmSessionEnd(BaseModel):
    session_id:       str
    duration_seconds: int
    completed:        bool

class JournalEntry(BaseModel):
    user_id:      str
    reading_id:   Optional[str] = None
    stress_level: Optional[str] = None
    content:      str

class UserPreferences(BaseModel):
    user_id:                str
    alerts_enabled:         Optional[bool] = None
    wearable_feedback:      Optional[bool] = None
    preferred_calm_sound:   Optional[str] = None
    preferred_calm_actions: Optional[List[str]] = None

@app.get("/")
def root():
    return {"status": "SmartCalm API is running 🟢", "version": "2.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict", response_model=PredictionResponse)
def predict(reading: SensorReading):
    if reading.device_id not in buffers:
        buffers[reading.device_id] = deque(maxlen=WINDOW_SIZE)

    buffers[reading.device_id].append({
        "bvp": reading.bvp, "eda": reading.eda, "temp": reading.temp,
        "acc_x": reading.acc_x, "acc_y": reading.acc_y, "acc_z": reading.acc_z,
    })
    buf = buffers[reading.device_id]

    if len(buf) < WINDOW_SIZE:
        return PredictionResponse(
            device_id=reading.device_id, user_id=reading.user_id,
            timestamp=reading.timestamp, stress_level="Unknown",
            stress_code=-1, confidence=0.0,
            probabilities={"Calm": 0.0, "Mild": 0.0, "High": 0.0},
            window_size=len(buf), ready=False
        )

    features        = extract_features(list(buf))
    features_scaled = scaler.transform(features.reshape(1, -1)).astype(np.float32)
    logits          = sess.run(["logits"], {"features": features_scaled})[0]
    probs           = softmax(logits[0])
    pred            = int(np.argmax(probs))

    bvp_vals  = [r["bvp"]  for r in buf]
    eda_vals  = [r["eda"]  for r in buf]
    temp_vals = [r["temp"] for r in buf]
    acc_vals  = [np.sqrt(r["acc_x"]**2 + r["acc_y"]**2 + r["acc_z"]**2) for r in buf]
    buffers[reading.device_id].clear()

    skin_temp     = safe_float(np.mean(temp_vals), 1)
    skin_response = safe_float(np.mean(eda_vals), 3)
    movement      = safe_float(np.mean(acc_vals), 3)

    try:
        peaks = np.where(np.diff(np.sign(np.diff(bvp_vals))) < 0)[0]
        heart_rate = round(60.0 * 4.0 / np.mean(np.diff(peaks)), 1) if len(peaks) > 1 else None
        if heart_rate and (np.isnan(heart_rate) or np.isinf(heart_rate) or heart_rate <= 0 or heart_rate > 300):
            heart_rate = None
    except:
        heart_rate = None

    prediction_counter[reading.device_id] = prediction_counter.get(reading.device_id, 0) + 1
    should_save = True

    reading_id = None
    if should_save:
        try:
            res = supabase.table("stress_readings").insert({
                "user_id":       reading.user_id,
                "device_id":     reading.device_id,
                "timestamp":     datetime.utcnow().isoformat(),
                "stress_level":  LABELS[pred],
                "stress_code":   pred,
                "confidence":    round(float(probs[pred]), 4),
                "prob_calm":     round(float(probs[0]), 4),
                "prob_mild":     round(float(probs[1]), 4),
                "prob_high":     round(float(probs[2]), 4),
                "heart_rate":    heart_rate,
                "skin_temp":     skin_temp,
                "skin_response": skin_response,
                "movement":      movement,
            }).execute()
            reading_id = res.data[0]["id"] if res.data else None
        except Exception as e:
            print(f"⚠️ Supabase insert failed: {e}")

    return PredictionResponse(
        device_id=reading.device_id, user_id=reading.user_id,
        timestamp=reading.timestamp, reading_id=reading_id,
        stress_level=LABELS[pred], stress_code=pred,
        confidence=round(float(probs[pred]), 4),
        probabilities={
            "Calm": round(float(probs[0]), 4),
            "Mild": round(float(probs[1]), 4),
            "High": round(float(probs[2]), 4),
        },
        heart_rate=heart_rate, skin_temp=skin_temp,
        skin_response=skin_response, movement=movement,
        window_size=WINDOW_SIZE, ready=True
    )

@app.post("/calm-session/start")
def start_calm_session(data: CalmSessionStart):
    try:
        res = supabase.table("calm_sessions").insert({
            "user_id":       data.user_id,
            "reading_id":    data.reading_id,
            "stress_level":  data.stress_level,
            "activity_type": data.activity_type,
            "activity_name": data.activity_name,
            "started_at":    datetime.utcnow().isoformat(),
        }).execute()
        return {"session_id": res.data[0]["id"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/calm-session/end")
def end_calm_session(data: CalmSessionEnd):
    try:
        supabase.table("calm_sessions").update({
            "duration_seconds": data.duration_seconds,
            "completed":        data.completed,
            "ended_at":         datetime.utcnow().isoformat(),
        }).eq("id", data.session_id).execute()
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/journal")
def save_journal(entry: JournalEntry):
    try:
        res = supabase.table("journal_entries").insert({
            "user_id":      entry.user_id,
            "reading_id":   entry.reading_id,
            "stress_level": entry.stress_level,
            "content":      entry.content,
        }).execute()
        return {"entry_id": res.data[0]["id"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/journal/{user_id}")
def get_journal(user_id: str, limit: int = 20):
    try:
        res = supabase.table("journal_entries").select("*")\
            .eq("user_id", user_id).order("created_at", desc=True).limit(limit).execute()
        return {"entries": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/reports/{user_id}")
def get_reports(user_id: str):
    try:
        readings = supabase.table("stress_readings").select("*")\
            .eq("user_id", user_id).order("timestamp", desc=True).limit(500).execute().data
        sessions = supabase.table("calm_sessions").select("*")\
            .eq("user_id", user_id).order("started_at", desc=True).limit(100).execute().data

        if not readings:
            return {"summary": {}, "distribution": {}, "timeline": [],
                    "episodes": [], "insights": [], "sessions": []}

        stress_codes  = [r["stress_code"] for r in readings if r["stress_code"] >= 0]
        stress_labels = [r["stress_level"] for r in readings]
        distribution  = {
            "Calm": stress_labels.count("Calm"),
            "Mild": stress_labels.count("Mild"),
            "High": stress_labels.count("High"),
        }

        daily = defaultdict(list)
        for r in readings:
            day = r["timestamp"][:10]
            daily[day].append(r["stress_code"])
        timeline = [
            {"date": d, "avg_stress": round(float(np.mean(v)), 2)}
            for d, v in sorted(daily.items())
        ][-7:]

        episodes        = []
        current_episode = None
        calm_streak     = 0

        for r in reversed(readings):
            if r["stress_code"] >= 1:
                calm_streak = 0
                if current_episode is None:
                    current_episode = {
                        "start":    r["timestamp"],
                        "level":    r["stress_level"],
                        "readings": 1,
                        "peak":     r["stress_code"],
                    }
                else:
                    current_episode["readings"] += 1
                    if r["stress_code"] > current_episode["peak"]:
                        current_episode["peak"]  = r["stress_code"]
                        current_episode["level"] = r["stress_level"]
            else:
                calm_streak += 1
                if calm_streak >= 12 and current_episode:
                    current_episode["end"] = r["timestamp"]
                    try:
                        start = datetime.fromisoformat(current_episode["start"].replace("Z", "+00:00").replace(" ", "T"))
                        end   = datetime.fromisoformat(current_episode["end"].replace("Z", "+00:00").replace(" ", "T"))
                        current_episode["duration_minutes"] = round(
                            (end - start).total_seconds() / 60, 1)
                    except:
                        current_episode["duration_minutes"] = 0
                    episodes.append(current_episode)
                    current_episode = None
                    calm_streak     = 0

        if current_episode:
            current_episode["duration_minutes"] = 0
            episodes.append(current_episode)

        insights = []
        total    = len(stress_labels)
        if total > 0:
            high_pct = distribution["High"] / total
            calm_pct = distribution["Calm"] / total
            mild_pct = distribution["Mild"] / total

            if high_pct > 0.3:
                insights.append("You've had frequent high stress episodes recently.")
            if calm_pct > 0.6:
                insights.append("You're mostly calm — great job managing stress!")
            if mild_pct > 0.4:
                insights.append("You've been experiencing mild stress frequently. Try some breathing exercises.")
            if len(episodes) > 5:
                insights.append(f"You've had {len(episodes)} stress episodes recently. Consider a break.")

            completed = [s for s in sessions if s.get("completed")]
            if completed:
                activity_counts = defaultdict(int)
                for s in completed:
                    activity_counts[s["activity_type"]] += 1
                most_used = max(activity_counts, key=activity_counts.get)
                insights.append(f"{most_used} is your most used calm activity.")

        return {
            "summary": {
                "avg_stress":     round(float(np.mean(stress_codes)), 2) if stress_codes else 0,
                "peak_stress":    LABELS.get(max(stress_codes), "Unknown") if stress_codes else "Unknown",
                "total_readings": total,
                "total_episodes": len(episodes),
            },
            "distribution": distribution,
            "timeline":     timeline,
            "episodes":     episodes[-10:],
            "insights":     insights,
            "sessions":     sessions[:20],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/user/{user_id}")
def get_user(user_id: str):
    try:
        res = supabase.table("users").select("*").eq("id", user_id).single().execute()
        return res.data
    except:
        raise HTTPException(status_code=404, detail="User not found")

@app.put("/user/preferences")
def update_preferences(prefs: UserPreferences):
    try:
        update_data = {k: v for k, v in prefs.dict().items()
                       if k != "user_id" and v is not None}
        supabase.table("users").update(update_data).eq("id", prefs.user_id).execute()
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/history/{user_id}")
def get_history(user_id: str, limit: int = 50):
    try:
        res = supabase.table("stress_readings").select("*")\
            .eq("user_id", user_id).order("timestamp", desc=True).limit(limit).execute()
        return {"records": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def softmax(x: np.ndarray) -> np.ndarray:
    e = np.exp(x - np.max(x))
    return e / e.sum()

def safe_float(value, decimals: int = 4):
    try:
        v = float(value)
        if np.isnan(v) or np.isinf(v):
            return None
        return round(v, decimals)
    except:
        return None