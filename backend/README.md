# SmartCalm — Backend API

![FastAPI](https://img.shields.io/badge/FastAPI-0.115-teal) ![ONNX](https://img.shields.io/badge/ONNX_Runtime-1.19-blue) ![Supabase](https://img.shields.io/badge/Supabase-Postgres-3ECF8E) ![Docker](https://img.shields.io/badge/Docker-ready-2496ED)

The SmartCalm backend: a FastAPI service that receives live sensor readings from the ESP32-S3 wristband, runs real-time stress classification using the trained ONNX model, logs results to Supabase, and serves the mobile app's history, journal, and analytics features.

## Features

- Real-time stress prediction (`/predict`) using a sliding 60-reading buffer per device
- ONNX Runtime inference — lightweight, fast, no PyTorch/TensorFlow dependency at serving time
- Automatic logging of every prediction to Supabase, including class probabilities, estimated heart rate, and derived signal summaries
- Calm-session tracking (start/end), journal entries, and per-user analytics reports with computed insights (stress episodes, weekly timeline, most-used calm activity)
- Row Level Security enforced at the database level — users can only access their own data
- Fully containerized with Docker for consistent deployment (currently deployed on Render)

## How It Works

1. The wristband firmware POSTs a sensor reading (BVP, EDA, TEMP, 3-axis ACC) to `/predict` every 250ms.
2. Readings are buffered per device until 60 are collected (a ~15s window at that rate).
3. Once full, `feature_extractor.py` converts the raw buffer into a feature vector, which is scaled and passed to the ONNX model.
4. The model returns class probabilities (Calm / Mild / High); the prediction, confidence, and derived signal summaries (heart rate, skin temp, etc.) are saved to Supabase and returned to the device.
5. The buffer clears and starts collecting the next window.
6. Separately, the mobile app calls `/reports/{user_id}`, `/history/{user_id}`, and `/journal/{user_id}` to display trends, past predictions, and journal entries.

## ⚠️ Known Issue — Feature Extraction Mismatch

`feature_extractor.py` (used here, at inference time) does **not** compute features identically to the pipeline used during model training (see `ml-model/notebooks/gan-final.ipynb`). Specifically:

- EDA slope is computed during training but not here
- BVP peak detection uses a different minimum-distance parameter (`distance=6` here vs. `distance=int(fs*0.4)`≈25 in training), affecting all heart-rate/HRV-derived features
- Accelerometer feature composition differs (this version omits `ACC_sma` used in training and adds an untrained slope/sum feature instead)

Both versions happen to produce 81 features, which is why this wasn't caught by a shape mismatch — but the *values* differ from what the model was trained on. This should be reconciled so `feature_extractor.py` exactly mirrors the training notebook's feature functions before this system is relied upon for accurate real-world predictions.

## Configuration

Supabase credentials are read from environment variables, never hardcoded:

1. Copy `.env.example` to `.env`
2. Fill in your real values:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-service-role-key
   ```
3. `.env` is git-ignored and never committed.

> **Note on the Supabase RLS policy:** `stress_readings` allows inserts from any authenticated caller (`WITH CHECK (true)`), rather than restricting inserts to `auth.uid() = user_id` like the other tables. This is intentional — the backend uses a service-role key to insert readings on behalf of devices, not the end user directly — but it means the insert policy alone doesn't restrict *who* a reading gets attributed to. Trust boundary here is the backend itself, not the database policy.

## Requirements

- fastapi==0.115.0
- uvicorn==0.30.6
- onnxruntime==1.19.2
- numpy==1.26.4
- scipy==1.13.1
- joblib==1.4.2
- supabase==2.15.1
- pydantic==2.8.2
- scikit-learn==1.6.1

## Database Schema

Defined in [`supabase_schema.sql`](supabase_schema.sql) — 4 tables (`users`, `stress_readings`, `calm_sessions`, `journal_entries`), all with Row Level Security enabled and indexed on the columns used for lookups/ordering (`user_id`, `timestamp`, `started_at`, `created_at`).

## How to Run

**Locally:**
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # then fill in real values
uvicorn main:app --host 0.0.0.0 --port 8000
```

**With Docker:**
```bash
cd backend
docker build -t smartcalm-api .
docker run -p 8000:8000 --env-file .env smartcalm-api
```

API will be available at `http://localhost:8000/`. Interactive docs (Swagger UI) at `http://localhost:8000/docs`.

## API Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/predict` | POST | Submit a sensor reading; returns stress prediction once buffer is full |
| `/calm-session/start` | POST | Start a calming activity session |
| `/calm-session/end` | POST | End a calming activity session |
| `/journal` | POST | Save a journal entry |
| `/journal/{user_id}` | GET | Retrieve journal entries |
| `/reports/{user_id}` | GET | Weekly summary, stress episodes, and insights |
| `/user/{user_id}` | GET | User profile |
| `/user/preferences` | PUT | Update user preferences |
| `/history/{user_id}` | GET | Raw prediction history |

## Future Improvements

- Reconcile `feature_extractor.py` with the training pipeline (see Known Issue above)
- Restrict CORS `allow_origins` to the actual app domain instead of `*`
- Replace in-memory prediction buffers with Redis or similar, so state survives restarts and works across multiple server instances
- Add automated tests comparing `feature_extractor.py` output against the training notebook's feature functions on sample data
