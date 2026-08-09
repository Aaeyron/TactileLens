import os
import subprocess
from pathlib import Path
from typing import Final


class BrailleTranslationError(Exception):
    """Raised when Liblouis cannot translate recognized content."""


class BrailleTranslationService:
    """Translates normalized OCR content using Liblouis."""

    UEB_CODE: Final[str] = "ueb"
    NEMETH_CODE: Final[str] = "nemeth"

    def __init__(
        self,
        liblouis_root: Path | None = None,
        timeout_seconds: float = 15.0,
    ) -> None:
        ai_service_directory = Path(__file__).resolve().parent.parent

        configured_root = os.getenv("LIBLOUIS_ROOT")

        if liblouis_root is not None:
            self._liblouis_root = liblouis_root.resolve()
        elif configured_root:
            self._liblouis_root = Path(configured_root).resolve()
        else:
            self._liblouis_root = (
                ai_service_directory
                / "vendor"
                / "liblouis"
            ).resolve()

        self._executable = (
            self._liblouis_root
            / "bin"
            / "lou_translate.exe"
        )

        self._tables_directory = (
            self._liblouis_root
            / "share"
            / "liblouis"
            / "tables"
        )

        self._display_table = (
            self._tables_directory
            / "unicode.dis"
        )

        self._ueb_table = (
            self._tables_directory
            / "en-ueb-g2.ctb"
        )

        # This table includes the Liblouis Nemeth definitions.
        self._nemeth_table = (
            self._tables_directory
            / "en-us-mathtext.ctb"
        )

        self._timeout_seconds = timeout_seconds

        self._validate_runtime()

    @property
    def is_ready(self) -> bool:
        return True

    def translate_text(self, content: str) -> str:
        """Translate English text into UEB Grade 2."""

        return self._translate(
            content=content,
            translation_table=self._ueb_table,
        )

    def translate_formula(self, content: str) -> str:
        """Translate normalized mathematical content into Nemeth."""

        return self._translate(
            content=content,
            translation_table=self._nemeth_table,
        )

    def translate_block(
        self,
        content: str,
        *,
        is_formula: bool,
    ) -> dict[str, object]:
        normalized_content = content.strip()

        if not normalized_content:
            return {
                "success": True,
                "code": (
                    self.NEMETH_CODE
                    if is_formula
                    else self.UEB_CODE
                ),
                "content": "",
                "error": None,
            }

        braille_code = (
            self.NEMETH_CODE
            if is_formula
            else self.UEB_CODE
        )

        try:
            if is_formula:
                braille_content = self.translate_formula(
                    normalized_content
                )
            else:
                braille_content = self.translate_text(
                    normalized_content
                )

            return {
                "success": True,
                "code": braille_code,
                "content": braille_content,
                "error": None,
            }
        except BrailleTranslationError as error:
            return {
                "success": False,
                "code": braille_code,
                "content": "",
                "error": str(error),
            }

    def _translate(
        self,
        *,
        content: str,
        translation_table: Path,
    ) -> str:
        source_content = content.strip()

        if not source_content:
            return ""

        environment = os.environ.copy()
        environment["LOUIS_TABLEPATH"] = str(
            self._tables_directory
        )

        command = [
            str(self._executable),
            "--forward",
            "--display-table",
            str(self._display_table),
            str(translation_table),
        ]

        try:
            completed_process = subprocess.run(
                command,
                input=f"{source_content}\n",
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="strict",
                cwd=str(self._tables_directory),
                env=environment,
                timeout=self._timeout_seconds,
                check=False,
                creationflags=getattr(
                    subprocess,
                    "CREATE_NO_WINDOW",
                    0,
                ),
            )
        except subprocess.TimeoutExpired as error:
            raise BrailleTranslationError(
                "Braille translation timed out."
            ) from error
        except OSError as error:
            raise BrailleTranslationError(
                "Liblouis could not be started."
            ) from error
        except UnicodeError as error:
            raise BrailleTranslationError(
                "Liblouis returned invalid Unicode output."
            ) from error

        if completed_process.returncode != 0:
            error_message = completed_process.stderr.strip()

            raise BrailleTranslationError(
                error_message
                or (
                    "Liblouis translation failed with exit "
                    f"code {completed_process.returncode}."
                )
            )

        return completed_process.stdout.rstrip("\r\n")

    def _validate_runtime(self) -> None:
        required_paths = {
            "Liblouis translator": self._executable,
            "Unicode display table": self._display_table,
            "UEB Grade 2 table": self._ueb_table,
            "Nemeth math table": self._nemeth_table,
        }

        missing_files = [
            f"{label}: {path}"
            for label, path in required_paths.items()
            if not path.is_file()
        ]

        if missing_files:
            formatted_files = "\n".join(missing_files)

            raise FileNotFoundError(
                "The Liblouis runtime is incomplete. "
                "Missing required files:\n"
                f"{formatted_files}"
            )