import cv2
import numpy as np
import os
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, f1_score
from scipy.stats import entropy
from sklearn.preprocessing import StandardScaler

# Feature Extraction Function
def extract_entropy_features(img_path):
    img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    # Threshold and find contours (for characters)
    _, thresh = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if len(contours) < 5:  
        return None

    # Compute positions (y-coords for alignment)
    y_coords = [cv2.boundingRect(c)[1] for c in contours]  # y positions
    if len(y_coords) == 0:
        return None
    y_hist, _ = np.histogram(y_coords, bins=10, density=True)
    align_entropy = entropy(y_hist + 1e-10)  # Avoid log(0)

    # Slants 
    slants = []
    for c in contours:
        moments = cv2.moments(c)
        # Add check for division by zero before calculating slant
        if moments['mu02'] != 0 and abs(moments['mu20'] - moments['mu02']) > 1e-6:
            slant = 0.5 * np.arctan(2 * moments['mu11'] / (moments['mu20'] - moments['mu02']))
            slants.append(slant)
    slant_var = np.var(slants) if slants else 0

    # Spacing (x-diffs between centers)
    centers = [cv2.boundingRect(c)[0] + cv2.boundingRect(c)[2]/2 for c in contours]
    spaces = np.diff(sorted(centers))
    space_std = np.std(spaces) if len(spaces) > 0 else 0

    return np.array([align_entropy, slant_var, space_std])

# Load Data
def load_data(root_dir):
    features, labels = [], []
    for folder, label in [('In-Person', 0), ('Web Form', 1)]:
        dir_path = os.path.join(root_dir, folder)
        # Add check for directory existence
        if not os.path.isdir(dir_path):
            print(f"Warning: Directory not found: {dir_path}. Skipping.")
            continue
        for file in os.listdir(dir_path):
            if file.endswith('.jpg'):
                path = os.path.join(dir_path, file)
                feats = extract_entropy_features(path)
                if feats is not None:
                    features.append(feats)
                    labels.append(label)
    return np.array(features), np.array(labels)

# Prepare
root = '/content/drive/MyDrive/Ink & Identity/INK & Identity/INK & Identity/'
X, y = load_data(root)
if X.shape[0] == 0:
    raise ValueError("No valid features extracted from any image.")

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, stratify=y)

# Model
model = LogisticRegression()
model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, y_pred) * 100:.2f}%")
print(f"F1 Score: {f1_score(y_test, y_pred):.2f}")
