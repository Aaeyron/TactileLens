from flask import Flask, request, jsonify
from pix2tex.cli import LatexOCR
from PIL import Image

app = Flask(__name__)

# Load the AI model once when the server starts
model = LatexOCR()

@app.route("/")
def home():
    return "Pix2Tex AI Server is Running!"

@app.route("/recognize", methods=["POST"])
def recognize():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image_file = request.files["image"]

    try:
        image = Image.open(image_file.stream)

        image.save("received_image.png")
        print("Saved received image as received_image.png")

        latex = model(image)

        return jsonify({
            "success": True,
            "latex": latex
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)