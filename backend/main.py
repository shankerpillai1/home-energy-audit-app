from fastapi import FastAPI
from login import app as login_app
from server import app as leakage_app

app = FastAPI(title="Combined Home Energy API")

app.mount("/auth", login_app)
app.mount("/leakage", leakage_app)

@app.get("/")
def root():
    return {"status": "running combined server"}