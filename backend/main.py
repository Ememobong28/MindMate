from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeClassifier

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

# --- train a tiny synthetic model at startup ---
np.random.seed(42)
N = 400
df = pd.DataFrame({
    "hours_studied": np.random.uniform(0, 10, N),
    "sleep_hours":   np.random.uniform(3, 10, N),
    "mood_score":    np.random.choice([1, 2, 3], N),  # 1=sad,2=neutral,3=happy
})
df["stress_level"] = np.select(
    [
        (df["sleep_hours"] < 5) & (df["hours_studied"] > 6),   # high
        (df["sleep_hours"] >= 5) & (df["hours_studied"] > 4),  # medium
    ],
    [2, 1],
    default=0,
)
X = df[["hours_studied", "sleep_hours", "mood_score"]].values
y = df["stress_level"].values
model = DecisionTreeClassifier(max_depth=4, random_state=7).fit(X, y)

LABELS = {0: "Low", 1: "Medium", 2: "High"}
EMOJI  = {0: "🟢", 1: "🟡", 2: "🔴"}
TIPS = {
    0: ["Nice balance! Keep a consistent sleep schedule."],
    1: ["Aim for 7–8 hours of sleep tonight."],
    2: ["Take a 5-minute breathing break and prioritize sleep."],
}

class PredictIn(BaseModel):
    hours_studied: float
    sleep_hours: float
    mood: str  # "sad" | "neutral" | "happy"

def mood_to_score(m: str) -> int:
    return {"sad": 1, "neutral": 2, "happy": 3}.get((m or "").lower(), 2)

@app.post("/predict")
def predict(inp: PredictIn):
    x = np.array([[inp.hours_studied, inp.sleep_hours, mood_to_score(inp.mood)]])
    proba = model.predict_proba(x)[0]
    pred = int(proba.argmax())
    drivers = {
        "hours_studied": float(x[0,0]),
        "sleep_hours": float(x[0,1]),
        "mood_score": int(x[0,2]),
    }
    return {
        "stress_level": pred,
        "label": LABELS[pred],
        "emoji": EMOJI[pred],
        "confidence": round(float(proba[pred]), 3),
        "drivers": drivers,
        "tip": TIPS[pred][0],
    }

@app.get("/health")
def health():
    return {"ok": True}
