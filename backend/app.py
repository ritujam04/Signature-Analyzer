from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import cv2
import numpy as np
from scipy.stats import entropy
from sklearn.preprocessing import StandardScaler
import joblib
import base64
import io
from PIL import Image
import os
import sys

# Verify numpy is working
print(f"NumPy version: {np.__version__}")
print(f"Python version: {sys.version}")

app = FastAPI(title="Signature Analyzer API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Get the directory where app.py is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Build full paths to model files
MODEL_PATH = os.path.join(BASE_DIR, 'entropy_model_final.joblib')
SCALER_PATH = os.path.join(BASE_DIR, 'scaler.joblib')

# Global variables for model and scaler
model = None
scaler = None

# Check if files exist before loading
if not os.path.exists(MODEL_PATH):
    print(f"WARNING: Model file not found at: {MODEL_PATH}")
if not os.path.exists(SCALER_PATH):
    print(f"WARNING: Scaler file not found at: {SCALER_PATH}")

# Load the trained model and scaler with error handling
try:
    print(f"Loading model from: {MODEL_PATH}")
    model = joblib.load(MODEL_PATH)
    print("✓ Model loaded successfully")
except Exception as e:
    print(f"✗ Failed to load model: {e}")
    print(f"Model file exists: {os.path.exists(MODEL_PATH)}")

try:
    print(f"Loading scaler from: {SCALER_PATH}")
    scaler = joblib.load(SCALER_PATH)
    print("✓ Scaler loaded successfully")
except Exception as e:
    print(f"✗ Failed to load scaler: {e}")
    print(f"Scaler file exists: {os.path.exists(SCALER_PATH)}")


class ImageRequest(BaseModel):
    image: str


class PredictionResponse(BaseModel):
    prediction: int
    flexibility: str
    is_forceful: bool
    confidence: float
    probabilities: dict
    features: dict


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    scaler_loaded: bool
    numpy_version: str
    opencv_version: str


def extract_entropy_features(img_array):
    """Extract features from image array"""
    # Convert to grayscale if needed
    if len(img_array.shape) == 3:
        img = cv2.cvtColor(img_array, cv2.COLOR_BGR2GRAY)
    else:
        img = img_array
    
    # Threshold and find contours
    _, thresh = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if len(contours) < 5:
        return None

    # Compute alignment entropy
    y_coords = [cv2.boundingRect(c)[1] for c in contours]
    if len(y_coords) == 0:
        return None
    y_hist, _ = np.histogram(y_coords, bins=10, density=True)
    align_entropy = entropy(y_hist + 1e-10)

    # Compute slant variance
    slants = []
    for c in contours:
        moments = cv2.moments(c)
        if moments['mu02'] != 0 and abs(moments['mu20'] - moments['mu02']) > 1e-6:
            slant = 0.5 * np.arctan(2 * moments['mu11'] / (moments['mu20'] - moments['mu02']))
            slants.append(slant)
    slant_var = np.var(slants) if slants else 0

    # Compute spacing std
    centers = [cv2.boundingRect(c)[0] + cv2.boundingRect(c)[2]/2 for c in contours]
    spaces = np.diff(sorted(centers))
    space_std = np.std(spaces) if len(spaces) > 0 else 0

    return np.array([align_entropy, slant_var, space_std])


@app.get("/")
async def home():
    return {
        "message": "Signature Analyzer API",
        "endpoints": {
            "/health": "GET - Check API health",
            "/predict": "POST - Analyze signature image",
            "/docs": "GET - API documentation (Swagger UI)"
        }
    }


@app.get("/health", response_model=HealthResponse)
async def health():
    return {
        "status": "healthy" if (model is not None and scaler is not None) else "degraded",
        "model_loaded": model is not None,
        "scaler_loaded": scaler is not None,
        "numpy_version": np.__version__,
        "opencv_version": cv2.__version__
    }


@app.post("/predict", response_model=PredictionResponse)
async def predict(request: ImageRequest):
    # Check if models are loaded
    if model is None or scaler is None:
        raise HTTPException(
            status_code=503,
            detail="Models not loaded. Please check server logs."
        )
    
    try:
        # Decode base64 image
        image_data = base64.b64decode(request.image)
        image = Image.open(io.BytesIO(image_data))
        img_array = np.array(image)
        
        # Extract features
        features = extract_entropy_features(img_array)
        
        if features is None:
            raise HTTPException(
                status_code=400,
                detail="Could not extract features. Please ensure the signature is clear and has at least 5 characters/strokes."
            )
        
        # Scale features using the loaded scaler
        features_scaled = scaler.transform([features])
        
        # Make prediction
        prediction = model.predict(features_scaled)[0]
        probability = model.predict_proba(features_scaled)[0]
        
        # Interpret results
        # 0 = In-Person (High Flexibility - Natural)
        # 1 = Web Form (Low Flexibility - Forceful/Consistent)
        
        result = {
            "prediction": int(prediction),
            "flexibility": "High (Natural)" if prediction == 0 else "Low (Forceful)",
            "is_forceful": bool(prediction == 1),
            "confidence": float(max(probability) * 100),
            "probabilities": {
                "natural": float(probability[0] * 100),
                "forceful": float(probability[1] * 100)
            },
            "features": {
                "alignment_entropy": float(features[0]),
                "slant_variance": float(features[1]),
                "spacing_std": float(features[2])
            }
        }
        
        return result
        
    except base64.binascii.Error:
        raise HTTPException(status_code=400, detail="Invalid base64 image data")
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*50)
    print("🚀 Starting Signature Analyzer API Server")
    print("="*50)
    print(f"📁 Working directory: {BASE_DIR}")
    print(f"📦 Model loaded: {model is not None}")
    print(f"📦 Scaler loaded: {scaler is not None}")
    print(f"🔢 NumPy version: {np.__version__}")
    print(f"📷 OpenCV version: {cv2.__version__}")
    print("="*50)
    print("Server running on: http://0.0.0.0:7860")
    print("Press CTRL+C to stop")
    print("="*50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=7860)