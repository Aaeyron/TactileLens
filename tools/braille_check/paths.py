"""The text a block goes through before Liblouis, on the phone and online.

On the phone (frontend/lib/services/ai/offline_ocr_service.dart):
  text block -> _reflowText -> _normalizeContent -> (MathTextFormatter.
  ensureReadable, which leaves text without LaTeX alone) -> one Liblouis
  call for Braille 2. Braille 1 is made line by line from the same text
  (braille_mode_translator.dart).
Online (ai_service): OcrContentNormalizer.normalize(content, "text") ->
  BrailleTranslationService.translate_text (lou_translate, line by line).
  Braille 1 of an online record is made on the phone, line by line, from
  the record's normalized text.

The two Dart steps are ported here line for line;
frontend/test/services/ai/offline_text_prep_reference_test.dart checks
the port against the real Dart code on the reference items.
"""

import re
import sys
from functools import lru_cache

from tools.braille_check import lou

_LIST_ITEM_START = re.compile(r"^(?:\(?\d{1,3}[.)]|\(?[a-zA-Z][.)]|[•\-–*])\s")
_STARTS_LOWERCASE = re.compile(r"^[a-z]")


def reflow_text(content: str) -> str:
    """OfflineOcrService._reflowText."""

    lines = [line.strip() for line in content.split("\n")]
    lines = [line for line in lines if line]

    if len(lines) < 2:
        return content.strip()

    result = lines[0]

    for line in lines[1:]:
        if _LIST_ITEM_START.search(line):
            result = f"{result}\n{line}"
        elif result.endswith("-") and _STARTS_LOWERCASE.search(line):
            result = result[:-1] + line
        else:
            result = f"{result} {line}"

    return result


def normalize_content(content: str) -> str:
    """OfflineOcrService._normalizeContent."""

    return (
        content.replace("−", "-").replace("–", "-").replace("—", "-").strip()
    )


def offline_text(content: str) -> str:
    """The text a phone text block sends to Liblouis."""

    return normalize_content(reflow_text(content))


def lines_of(text: str) -> list[str]:
    """BrailleModeTranslator._sourceLines."""

    return [line.strip() for line in text.split("\n") if line.strip()]


def braille1_from(text: str) -> str:
    """Braille 1 as the phone makes it: each line with en-ueb-g1.ctb."""

    return "\n".join(lou.translate(line, lou.UEB_G1) for line in lines_of(text))


def offline_braille2(content: str) -> str:
    return lou.translate(offline_text(content), lou.UEB_G2)


def offline_braille1(content: str) -> str:
    return braille1_from(offline_text(content))


@lru_cache(maxsize=1)
def _server():
    ai_service = str(lou.REPO / "ai_service")

    if ai_service not in sys.path:
        sys.path.insert(0, ai_service)

    from services.braille.braille_translation_service import (
        BrailleTranslationService,
    )
    from services.ocr.ocr_content_normalizer import OcrContentNormalizer

    return BrailleTranslationService(), OcrContentNormalizer


def server_text(content: str) -> str:
    _, normalizer = _server()
    return normalizer.normalize(content, "text")


def server_braille2(content: str) -> str:
    translator, _ = _server()
    return translator.translate_text(server_text(content))


def server_braille1(content: str) -> str:
    return braille1_from(server_text(content))


PATHS = {
    ("braille2", "offline"): offline_braille2,
    ("braille2", "online"): server_braille2,
    ("braille1", "offline"): offline_braille1,
    ("braille1", "online"): server_braille1,
}

TABLE = {"braille2": lou.UEB_G2, "braille1": lou.UEB_G1}
