from flask import Flask, request, jsonify
from recognize_math import recognize
import os

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route("/")
def home():
    return "TactileLens AI Server is Running!"

@app.route("/recognize", methods=["POST"])
def recognize_equation():

    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files["image"]

    image_path = os.path.join(UPLOAD_FOLDER, image.filename)
    image.save(image_path)

    result = recognize(image_path)

    return jsonify({
        "latex": result
    })

if __name__ == "__main__":
    app.run(debug=True)