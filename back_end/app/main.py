from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import get_settings
from utils.firebase_admin import initialize_firebase
from api.v1 import auth, users, vitals, activities, alerts, sessions, nutrition
import uvicorn

settings = get_settings()

# Initialize Firebase
initialize_firebase()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    debug=settings.DEBUG,
    description="HealthTrack Backend API for multi-user health monitoring with cloud sync"
)

# CORS - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(vitals.router, prefix="/api/v1/vitals", tags=["Vitals"])
app.include_router(activities.router, prefix="/api/v1/activities", tags=["Activities"])
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])
app.include_router(sessions.router, prefix="/api/v1/sessions", tags=["Sessions"])
app.include_router(nutrition.router, prefix="/api/v1/nutrition", tags=["Nutrition"])

@app.get("/")
def root():
    return {
        "message": "HealthTrack API",
        "version": settings.VERSION,
        "status": "running"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "healthtrack-api"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)