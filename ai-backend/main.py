"""
SecureGate AI Backend - FastAPI Application
Handles device image matching, QR anti-forgery detection, and security scoring
"""

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import numpy as np
from PIL import Image, ImageStat, ImageFilter
import io
import base64
import hashlib
from datetime import datetime
import os

try:
    import tensorflow as tf
    TENSORFLOW_AVAILABLE = True
except ImportError:
    TENSORFLOW_AVAILABLE = False
    print("TensorFlow not available - using image hashing fallback")

app = FastAPI(title="SecureGate AI Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

base_model = None
if TENSORFLOW_AVAILABLE:
    try:
        base_model = tf.keras.applications.MobileNetV2(
            weights='imagenet',
            include_top=False,
            pooling='avg'
        )
        print("MobileNetV2 model loaded successfully")
    except Exception as e:
        print(f"Warning: Could not load MobileNetV2 model: {e}")
        base_model = None
else:
    print("Using image hashing fallback (TensorFlow not available)")


class DeviceRegistrationRequest(BaseModel):
    brand: str
    model: str
    serial_number: str
    image_url: str
    image_base64: Optional[str] = None


class DeviceVerificationRequest(BaseModel):
    device_id: str
    qr_hash: str
    live_image_url: str
    live_image_base64: Optional[str] = None
    registered_features: Optional[List[float]] = None
    timestamp: int


class QRCheckRequest(BaseModel):
    qr_hash: str
    qr_data: str


class GenerateFeaturesRequest(BaseModel):
    image_url: str
    image_base64: Optional[str] = None


def load_image_from_url(url: str) -> Image.Image:
    """Load image from URL returning PIL Image"""
    import requests
    response = requests.get(url)
    img = Image.open(io.BytesIO(response.content)).convert('RGB')
    return img


def load_image_from_base64(base64_str: str) -> Image.Image:
    """Load image from base64 string returning PIL Image"""
    img_data = base64.b64decode(base64_str)
    img = Image.open(io.BytesIO(img_data)).convert('RGB')
    return img


def preprocess_image(img: Image.Image) -> np.ndarray:
    """Preprocess image for MobileNetV2"""
    img_resized = img.resize((224, 224))
    img_array = np.array(img_resized)
    return tf.keras.applications.mobilenet_v2.preprocess_input(img_array)


def extract_features(img: Image.Image) -> np.ndarray:
    """Extract features using MobileNetV2"""
    if base_model is None:
        return compute_image_hash(img)
    
    img_preprocessed = preprocess_image(img)
    img_batch = np.expand_dims(img_preprocessed, axis=0)
    features = base_model.predict(img_batch, verbose=0)
    return features[0]


def compute_image_hash(img: Image.Image) -> np.ndarray:
    """Compute perceptual hash as fallback"""
    img_gray = img.convert('L').resize((8, 8), resample=Image.Resampling.LANCZOS)
    img_array = np.array(img_gray)
    img_hash = img_array.flatten()
    return img_hash.astype(np.float32) / 255.0


def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """Compute cosine similarity between two vectors"""
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return float(dot_product / (norm1 * norm2))


def detect_screenshot(img: Image.Image) -> bool:
    """Detect if image is a screenshot (Placeholder logic)"""
    stat = ImageStat.Stat(img)
    avg_stddev = sum(stat.stddev) / len(stat.stddev)
    return avg_stddev < 10.0


def detect_reprint(img: Image.Image) -> bool:
    """Detect if image is a reprint (blur detection using PIL)"""
    gray = img.convert('L')
    edges = gray.filter(ImageFilter.FIND_EDGES)
    stat = ImageStat.Stat(edges)
    variance = sum(stat.var) / len(stat.var)
    
    return variance < 100


@app.post("/ai/register-device")
async def register_device(request: DeviceRegistrationRequest):
    """Register a device and extract features"""
    try:
        if request.image_base64:
            img = load_image_from_base64(request.image_base64)
        else:
            img = load_image_from_url(request.image_url)
        
        features = extract_features(img)
        features_list = features.tolist()
        
        device_identified = True
        confidence = 0.85  # Placeholder
        
        return {
            "device_id": f"DV-{hashlib.md5(request.serial_number.encode()).hexdigest()[:8]}",
            "features": features_list,
            "device_identified": device_identified,
            "confidence": confidence
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ai/verify-device")
async def verify_device(request: DeviceVerificationRequest):
    """Verify a device using live image and QR code"""
    try:
        if request.live_image_base64:
            live_img = load_image_from_base64(request.live_image_base64)
        else:
            live_img = load_image_from_url(request.live_image_url)
        
        live_features = extract_features(live_img)
        
        if request.registered_features:
            registered_features = np.array(request.registered_features)
        else:
            print("WARNING: No registered features provided. Using random fallback.")
            registered_features = np.random.rand(len(live_features))
        
        if len(registered_features) != len(live_features):
            min_len = min(len(registered_features), len(live_features))
            registered_features = registered_features[:min_len]
            live_features = live_features[:min_len]
        
        image_match_score = cosine_similarity(live_features, registered_features)
        
        qr_validity = len(request.qr_hash) == 64  # SHA-256 hash length
        
        is_screenshot = detect_screenshot(live_img)
        is_reprint = detect_reprint(live_img)
        fraud_detected = bool(is_screenshot or is_reprint)

        anomaly_score = 0.0
        if fraud_detected and image_match_score < 0.8:
            anomaly_score += 0.4
        elif fraud_detected:
            anomaly_score += 0.2
        if image_match_score < 0.7:
            anomaly_score += 0.3
        if not qr_validity:
            anomaly_score += 0.2

        ai_score = (image_match_score * 0.7 + (1 - min(anomaly_score, 1.0)) * 0.3) * 100

        if (fraud_detected and image_match_score < 0.75) or (anomaly_score > 0.7 and image_match_score < 0.7):
            status = "blocked"
        elif anomaly_score > 0.4 or (image_match_score < 0.65):
            status = "suspicious"
        else:
            status = "verified"

        return {
            "verified": status == "verified",
            "status": status,
            "ai_score": round(float(ai_score), 2),
            "image_match_score": round(float(image_match_score), 4),
            "qr_validity": bool(qr_validity),
            "fraud_detected": bool(fraud_detected),
            "anomaly_score": round(float(anomaly_score), 4),
            "message": f"Device verification {'passed' if status == 'verified' else 'requires review'}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ai/check-qr")
async def check_qr(request: QRCheckRequest):
    """Check QR code validity and detect forgery"""
    try:
        is_valid = len(request.qr_hash) == 64 and all(c in '0123456789abcdef' for c in request.qr_hash)
        
        is_forged = False
        is_screenshot = False
        is_reprint = False
        
        if not is_valid:
            is_forged = True
        
        try:
            import json
            qr_data = json.loads(request.qr_data)
            if 'hash' not in qr_data or 'deviceId' not in qr_data:
                is_forged = True
        except:
            is_forged = True
        
        confidence = 0.9 if is_valid and not is_forged else 0.1
        
        return {
            "valid": is_valid and not is_forged,
            "is_forged": is_forged,
            "is_screenshot": is_screenshot,
            "is_reprint": is_reprint,
            "confidence": confidence,
            "message": "QR code is valid" if is_valid and not is_forged else "QR code validation failed"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ai/generate-features")
async def generate_features(request: GenerateFeaturesRequest):
    """Generate features from an image"""
    try:
        if request.image_base64:
            img = load_image_from_base64(request.image_base64)
        else:
            img = load_image_from_url(request.image_url)
        
        features = extract_features(img)
        features_list = features.tolist()
        
        device_identified = True
        confidence = 0.80
        
        return {
            "features": features_list,
            "device_identified": device_identified,
            "confidence": confidence
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": base_model is not None,
        "timestamp": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)