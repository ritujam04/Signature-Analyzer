# Signature Analyzer

A comprehensive application for analyzing digital signatures combining machine learning backend with a Flutter mobile frontend.

## Project Structure

```
├── flutter_frontend/        # Flutter mobile application (iOS, Android, Web, Linux, macOS, Windows)
├── backend/                 # FastAPI Python backend for signature analysis
└── model_training/          # Machine learning model training and evaluation scripts
```

## Components

### Flutter Frontend (`flutter_frontend/`)
- Multi-platform mobile and desktop application built with Flutter
- Supports iOS, Android, Web, Linux, macOS, and Windows
- Provides user interface for signature analysis
- Real-time communication with FastAPI backend

### Backend (`backend/`)
- FastAPI-based REST API server
- Signature analysis using trained machine learning models
- Pre-trained models included:
  - Entropy model (`entropy_model_final.joblib`)
  - Scaler (`scaler.joblib`)
- Requirements: See `requirements.txt`

### Model Training (`model_training/`)
- Training scripts for machine learning models
- Data preprocessing and feature engineering
- Model evaluation and validation

## Getting Started

### Prerequisites
- Python 3.8+ (for backend)
- Flutter SDK (for frontend development)
- Docker (for containerized deployment)

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
python app.py
```

The API will be available at `http://localhost:8000`

### Frontend Setup
```bash
cd flutter_frontend
flutter pub get
flutter run
```

## Technologies Used

- **Frontend**: Flutter, Dart
- **Backend**: FastAPI, Python
- **ML**: Scikit-learn, Joblib
- **Deployment**: Docker

## License
MIT License

## Author
Rituja
