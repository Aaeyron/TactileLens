from pix2tex.cli import LatexOCR
from PIL import Image
import sys

# Load the model only once
model = LatexOCR()

def recognize(image_path):
    image = Image.open(image_path)
    result = model(image)
    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: python recognize_math.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    print(recognize(image_path))

if __name__ == "__main__":
    main()