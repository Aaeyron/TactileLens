"""Liblouis through its C API, the way the app's JNI bridge calls it.

liblouis_bridge.cpp calls lou_translateString once per string with the
table list "<tables>/unicode.dis,<tables>/<table>", mode 0, no typeforms.
This does the same with the app's own tables
(frontend/third_party/liblouis/tables) and the Liblouis library the AI
service uses (ai_service/vendor/liblouis, or LIBLOUIS_LIBRARY).

The PC library may be the 32-bit widechar build (lou_charSize() == 4) while
the phone uses 16 bits; for Basic Multilingual Plane text, which covers all
Braille cells and worksheet text, the results are the same.
"""

import ctypes
import os
import sys
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
APP_TABLES = REPO / "frontend" / "third_party" / "liblouis" / "tables"

UEB_G2 = "en-ueb-g2.ctb"  # Braille 2 (contracted)
UEB_G1 = "en-ueb-g1.ctb"  # Braille 1 (uncontracted)
NEMETH = "en-us-mathtext.ctb"


class LiblouisUnavailable(RuntimeError):
    """The Liblouis library or the app's tables are not on this machine."""


def _library_path() -> Path:
    configured = os.environ.get("LIBLOUIS_LIBRARY")

    if configured:
        return Path(configured)

    root = Path(
        os.environ.get("LIBLOUIS_ROOT", REPO / "ai_service" / "vendor" / "liblouis")
    )

    if sys.platform == "win32":
        return root / "bin" / "liblouis.dll"

    return root / "lib" / "liblouis.so"


@lru_cache(maxsize=1)
def _library():
    path = _library_path()

    if not path.is_file() or not (APP_TABLES / UEB_G2).is_file():
        raise LiblouisUnavailable(f"Liblouis not found ({path}, {APP_TABLES})")

    library = ctypes.CDLL(str(path))
    char_size = library.lou_charSize()
    widechar = ctypes.c_uint32 if char_size == 4 else ctypes.c_uint16

    for name in ("lou_translateString", "lou_backTranslateString"):
        getattr(library, name).argtypes = [
            ctypes.c_char_p,
            ctypes.POINTER(widechar),
            ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(widechar),
            ctypes.POINTER(ctypes.c_int),
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_int,
        ]

    library.lou_version.restype = ctypes.c_char_p

    return library, widechar


def available() -> bool:
    try:
        _library()
    except (LiblouisUnavailable, OSError):
        return False

    return True


def version() -> str:
    library, _ = _library()
    return library.lou_version().decode()


def _call(function_name: str, text: str, table: str) -> str:
    library, widechar = _library()
    tables = f"{APP_TABLES / 'unicode.dis'},{APP_TABLES / table}".encode()
    codes = [ord(character) for character in text]
    length = len(codes)
    capacity = max(1024, length * 16 + 256)

    source = (widechar * max(length, 1))(*codes)
    target = (widechar * capacity)()
    in_length = ctypes.c_int(length)
    out_length = ctypes.c_int(capacity)

    ok = getattr(library, function_name)(
        tables,
        source,
        ctypes.byref(in_length),
        target,
        ctypes.byref(out_length),
        None,
        None,
        0,
    )

    if not ok:
        raise RuntimeError(f"{function_name} failed for {text!r}")

    if in_length.value != length:
        raise RuntimeError(f"{function_name} stopped early for {text!r}")

    return "".join(chr(target[index]) for index in range(out_length.value))


def translate(text: str, table: str) -> str:
    """One call, as LiblouisNative.translate() does (trimmed input)."""

    text = text.strip()
    return _call("lou_translateString", text, table).rstrip("\r\n") if text else ""


def back_translate(braille: str, table: str) -> str:
    braille = braille.strip()
    return _call("lou_backTranslateString", braille, table) if braille else ""
