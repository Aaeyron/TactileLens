"""The server makes every image upright before OCR (defence in depth).

The app already applies EXIF orientation once after capture or pick, but
any client can send a rotated image, so _prepare_image runs
ImageOps.exif_transpose before both engines. These tests use images with
each of the 8 EXIF orientations, generated here.
"""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

from services.ocr.paddleocr_vl_service import PaddleOcrVlService

ORIENTATION_TAG = 0x0112

# How the stored pixels relate to the upright image for each EXIF value,
# as a camera or another app writes them (a viewer applying the tag then
# shows the upright image).
STORE = {
    1: lambda im: im,
    2: lambda im: im.transpose(Image.Transpose.FLIP_LEFT_RIGHT),
    3: lambda im: im.transpose(Image.Transpose.ROTATE_180),
    4: lambda im: im.transpose(Image.Transpose.FLIP_TOP_BOTTOM),
    5: lambda im: im.transpose(Image.Transpose.TRANSPOSE),
    6: lambda im: im.transpose(Image.Transpose.ROTATE_90),
    7: lambda im: im.transpose(Image.Transpose.TRANSVERSE),
    8: lambda im: im.transpose(Image.Transpose.ROTATE_270),
}


def _upright(width=400, height=200):
    """Left half red, right half blue, top-left corner green."""
    image = Image.new("RGB", (width, height), (255, 0, 0))
    image.paste((0, 0, 255), (width // 2, 0, width, height))
    image.paste((0, 255, 0), (0, 0, width // 8, height // 4))
    return image


def _service():
    service = PaddleOcrVlService.__new__(PaddleOcrVlService)
    service.max_image_dimension = PaddleOcrVlService.DEFAULT_MAX_IMAGE_DIMENSION
    service.jpeg_quality = PaddleOcrVlService.DEFAULT_JPEG_QUALITY
    return service


def _near(pixel, expected, tolerance=70):
    return all(abs(a - b) <= tolerance for a, b in zip(pixel, expected))


class PrepareImageOrientationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)

    def _jpeg(self, name, image, orientation):
        path = Path(self.directory.name) / name
        exif = Image.Exif()
        exif[ORIENTATION_TAG] = orientation
        image.save(path, format="JPEG", quality=95, exif=exif)
        return path

    def test_all_eight_orientations_come_out_upright(self):
        service = _service()

        for orientation, store in STORE.items():
            with self.subTest(orientation=orientation):
                source = self._jpeg(
                    f"o{orientation}.jpg", store(_upright()), orientation
                )

                prepared = service._prepare_image(source)
                self.addCleanup(prepared.unlink, missing_ok=True)

                with Image.open(prepared) as result:
                    self.assertEqual(result.size, (400, 200))
                    rgb = result.convert("RGB")
                    self.assertTrue(_near(rgb.getpixel((10, 10)), (0, 255, 0)))
                    self.assertTrue(_near(rgb.getpixel((100, 150)), (255, 0, 0)))
                    self.assertTrue(_near(rgb.getpixel((300, 100)), (0, 0, 255)))
                    self.assertIn(result.getexif().get(ORIENTATION_TAG, 1), (1, None))

    def test_a_large_rotated_photo_is_upright_and_capped(self):
        service = _service()
        source = self._jpeg("big.jpg", STORE[6](_upright(3000, 1500)), 6)

        prepared = service._prepare_image(source)
        self.addCleanup(prepared.unlink, missing_ok=True)

        with Image.open(prepared) as result:
            self.assertEqual(result.size, (2000, 1000))
            self.assertTrue(
                _near(result.convert("RGB").getpixel((40, 40)), (0, 255, 0))
            )

    def test_default_cap_matches_the_app(self):
        # frontend AIService.onlineUploadMaxDimension uses the same value.
        self.assertEqual(PaddleOcrVlService.DEFAULT_MAX_IMAGE_DIMENSION, 2000)


if __name__ == "__main__":
    unittest.main()
