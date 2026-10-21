import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from services.braille_translation_service import (
    BrailleTranslationService,
    translator_executable,
)

AI_SERVICE_DIRECTORY = Path(__file__).resolve().parent.parent

_PADDLE_INSTALLED = importlib.util.find_spec("paddleocr") is not None


class PaddleImportTests(unittest.TestCase):
    def test_service_module_imports_without_paddle(self):
        # A fresh interpreter, so no other test can have imported it.
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                "-c",
                "import sys, services.paddleocr_vl_service; "
                "print('paddleocr' in sys.modules)",
            ],
            cwd=AI_SERVICE_DIRECTORY,
            capture_output=True,
            text=True,
            check=True,
        )

        self.assertEqual(result.stdout.strip(), "False")

    @unittest.skipIf(_PADDLE_INSTALLED, "PaddleOCR is installed here")
    def test_local_engine_without_paddle_explains_what_is_missing(self):
        from services.paddleocr_vl_service import PaddleOcrVlService

        try:
            BrailleTranslationService()
        except FileNotFoundError:
            self.skipTest("Liblouis runtime not installed")

        with self.assertRaises(ImportError) as context:
            PaddleOcrVlService()

        self.assertIn("paddleocr and paddlepaddle", str(context.exception))


class LiblouisExecutableTests(unittest.TestCase):
    def test_windows_uses_the_bundled_exe(self):
        self.assertEqual(
            translator_executable(Path("C:/liblouis"), platform_name="nt"),
            Path("C:/liblouis") / "bin" / "lou_translate.exe",
        )

    def test_linux_uses_lou_translate_under_the_root(self):
        self.assertEqual(
            translator_executable(Path("/usr"), platform_name="posix"),
            Path("/usr") / "bin" / "lou_translate",
        )

    def test_a_configured_path_wins(self):
        configured = os.path.join(tempfile.gettempdir(), "lou_translate")

        self.assertEqual(
            translator_executable(
                Path("/usr"),
                platform_name="posix",
                configured_path=configured,
            ),
            Path(configured).resolve(),
        )


def _fake_liblouis(root: Path, executable_name: str) -> None:
    tables = root / "share" / "liblouis" / "tables"
    tables.mkdir(parents=True)

    for table in ("unicode.dis", "en-ueb-g2.ctb", "en-us-mathtext.ctb"):
        (tables / table).write_text("", encoding="utf-8")

    (root / "bin").mkdir()
    (root / "bin" / executable_name).write_text("", encoding="utf-8")


class LiblouisStartupTests(unittest.TestCase):
    def test_startup_fails_clearly_when_the_program_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _fake_liblouis(root, "some_other_program")

            with mock.patch.dict(os.environ, {"LIBLOUIS_TRANSLATE": ""}):
                with self.assertRaises(FileNotFoundError) as context:
                    BrailleTranslationService(liblouis_root=root)

        self.assertIn("Liblouis translator", str(context.exception))
        self.assertIn("lou_translate", str(context.exception))

    def test_startup_uses_liblouis_translate_from_the_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _fake_liblouis(root, "custom_translate")
            custom = root / "bin" / "custom_translate"

            with mock.patch.dict(
                os.environ,
                {"LIBLOUIS_TRANSLATE": str(custom)},
            ):
                service = BrailleTranslationService(liblouis_root=root)

        self.assertEqual(service._executable, custom.resolve())

    def test_startup_fails_clearly_when_a_table_is_missing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            name = "lou_translate.exe" if os.name == "nt" else "lou_translate"
            _fake_liblouis(root, name)
            (root / "share" / "liblouis" / "tables" / "en-us-mathtext.ctb").unlink()

            with mock.patch.dict(os.environ, {"LIBLOUIS_TRANSLATE": ""}):
                with self.assertRaises(FileNotFoundError) as context:
                    BrailleTranslationService(liblouis_root=root)

        self.assertIn("Nemeth math table", str(context.exception))


if __name__ == "__main__":
    unittest.main()
