import numpy as np
from scipy import stats
from scipy.signal import find_peaks

def clean_float(v):
    try:
        f = float(v)
        if np.isnan(f) or np.isinf(f):
            return 0.0
        return f
    except:
        return 0.0

def extract_features(window: list) -> np.ndarray:
    bvp   = np.array([r["bvp"]   for r in window], dtype=np.float32)
    eda   = np.array([r["eda"]   for r in window], dtype=np.float32)
    temp  = np.array([r["temp"]  for r in window], dtype=np.float32)
    acc_x = np.array([r["acc_x"] for r in window], dtype=np.float32)
    acc_y = np.array([r["acc_y"] for r in window], dtype=np.float32)
    acc_z = np.array([r["acc_z"] for r in window], dtype=np.float32)
    acc_mag = np.sqrt(acc_x**2 + acc_y**2 + acc_z**2)
    features = []
    features += base_stats(eda)
    features += eda_specific(eda)
    features += base_stats(bvp)
    features += bvp_specific(bvp)
    features += base_stats(temp)
    features.append(clean_float(np.polyfit(np.arange(len(temp)), temp, 1)[0]))
    features += base_stats(acc_x)
    features.append(clean_float(np.polyfit(np.arange(len(acc_x)), acc_x, 1)[0]))
    features += base_stats(acc_y)
    features += base_stats(acc_z)
    features += base_stats(acc_mag)
    features.append(clean_float(np.sum(np.abs(acc_x) + np.abs(acc_y) + np.abs(acc_z))))
    return np.array(features, dtype=np.float32)

def base_stats(signal: np.ndarray) -> list:
    return [
        clean_float(np.mean(signal)),
        clean_float(np.std(signal)),
        clean_float(np.min(signal)),
        clean_float(np.max(signal)),
        clean_float(np.max(signal) - np.min(signal)),
        clean_float(stats.skew(signal)),
        clean_float(stats.kurtosis(signal)),
        clean_float(np.sqrt(np.mean(signal**2))),
        clean_float(np.percentile(signal, 75) - np.percentile(signal, 25)),
        clean_float(np.median(signal)),
    ]

def eda_specific(eda: np.ndarray) -> list:
    try:
        threshold = np.mean(eda) + 0.5 * np.std(eda)
        peaks, props = find_peaks(eda, height=threshold, distance=4)
        scr_count = len(peaks)
        scr_rate  = scr_count / (len(eda) / 4.0)
        mean_amp  = float(np.mean(props["peak_heights"])) if scr_count > 0 else 0.0
        return [clean_float(scr_count), clean_float(scr_rate), clean_float(mean_amp)]
    except:
        return [0.0, 0.0, 0.0]

def bvp_specific(bvp: np.ndarray) -> list:
    try:
        peaks, _ = find_peaks(bvp, distance=6)
        if len(peaks) < 2:
            return [0.0, 0.0, 0.0, 0.0, 0.0]
        rr      = np.diff(peaks) / 64.0 * 1000.0
        hr_mean = clean_float(60000.0 / np.mean(rr))
        sdnn    = clean_float(np.std(rr))
        rmssd   = clean_float(np.sqrt(np.mean(np.diff(rr)**2))) if len(rr) > 1 else 0.0
        nn50    = clean_float(np.sum(np.abs(np.diff(rr)) > 50))
        pnn50   = clean_float(nn50 / len(rr) * 100) if len(rr) > 0 else 0.0
        return [hr_mean, sdnn, rmssd, nn50, pnn50]
    except:
        return [0.0, 0.0, 0.0, 0.0, 0.0]