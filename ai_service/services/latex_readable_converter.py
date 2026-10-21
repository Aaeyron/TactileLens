"""Converts LaTeX from the formula model into readable Unicode math.

This is a Python port of the Flutter MathTextFormatter, so the online
(PaddleOCR-VL) and offline results show the same symbols. Keep the two
versions in sync: the same cases must pass in both test suites.

Examples:
    \\sqrt{x+9}=5          -> √(x + 9) = 5
    \\frac{3x+1}{x-2}      -> (3x + 1)/(x − 2)
    x^{n+1}                -> x^(n + 1)
    3x-4\\leq11            -> 3x − 4 ≤ 11
    \\sqrt[11]{x^{11}}=x   -> ¹¹√(x¹¹) = x
"""

import re


_SUP = {
    "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
    "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
    "+": "⁺", "−": "⁻", "-": "⁻", "n": "ⁿ", "i": "ⁱ",
}

_SUB = {
    "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
    "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
    "+": "₊", "−": "₋", "-": "₋", "a": "ₐ", "e": "ₑ",
    "o": "ₒ", "x": "ₓ", "i": "ᵢ", "j": "ⱼ", "k": "ₖ",
    "m": "ₘ", "n": "ₙ", "t": "ₜ",
}

_SYMBOLS = {
    "leq": "≤", "le": "≤", "leqslant": "≤",
    "geq": "≥", "ge": "≥", "geqslant": "≥",
    "neq": "≠", "ne": "≠", "lt": "<", "gt": ">",
    "approx": "≈", "equiv": "≡", "sim": "∼", "cong": "≅", "propto": "∝",
    "times": "×", "div": "÷", "cdot": "·", "ast": "*", "pm": "±", "mp": "∓",
    "infty": "∞", "sum": "∑", "prod": "∏", "int": "∫",
    "partial": "∂", "nabla": "∇",
    "degree": "°", "circ": "°", "prime": "′",
    "ldots": "…", "cdots": "…", "dots": "…", "vdots": "⋮",
    "to": "→", "rightarrow": "→", "longrightarrow": "→",
    "Rightarrow": "⇒", "Longrightarrow": "⇒", "implies": "⇒",
    "leftarrow": "←", "Leftarrow": "⇐", "leftrightarrow": "↔",
    "Leftrightarrow": "⇔", "iff": "⇔",
    "therefore": "∴", "because": "∵",
    "in": "∈", "notin": "∉", "ni": "∋",
    "subset": "⊂", "subseteq": "⊆", "supset": "⊃", "supseteq": "⊇",
    "cup": "∪", "cap": "∩", "emptyset": "∅", "varnothing": "∅",
    "forall": "∀", "exists": "∃", "neg": "¬", "land": "∧", "lor": "∨",
    "angle": "∠", "perp": "⊥", "parallel": "∥", "triangle": "△",
    "mid": "|", "vert": "|", "lvert": "|", "rvert": "|",
    "Vert": "‖", "lVert": "‖", "rVert": "‖",
    "langle": "⟨", "rangle": "⟩", "lfloor": "⌊", "rfloor": "⌋",
    "lceil": "⌈", "rceil": "⌉", "lbrace": "{", "rbrace": "}",
    "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
    "epsilon": "ε", "varepsilon": "ε", "zeta": "ζ", "eta": "η",
    "theta": "θ", "vartheta": "θ", "iota": "ι", "kappa": "κ",
    "lambda": "λ", "mu": "μ", "nu": "ν", "xi": "ξ", "pi": "π",
    "varpi": "π", "rho": "ρ", "sigma": "σ", "tau": "τ",
    "upsilon": "υ", "phi": "φ", "varphi": "φ", "chi": "χ",
    "psi": "ψ", "omega": "ω",
    "Gamma": "Γ", "Delta": "Δ", "Theta": "Θ", "Lambda": "Λ", "Xi": "Ξ",
    "Pi": "Π", "Sigma": "Σ", "Phi": "Φ", "Psi": "Ψ", "Omega": "Ω",
    "percent": "%",
}

_FUNCTIONS = frozenset({
    "sin", "cos", "tan", "sec", "csc", "cot", "sinh", "cosh", "tanh",
    "arcsin", "arccos", "arctan", "log", "ln", "exp", "lim", "max", "min",
    "det", "gcd", "lcm", "deg", "mod",
})

_SPACES = frozenset({
    "quad", "qquad", "space", "enspace", "thinspace", "medspace",
    "thickspace",
})

_IGNORED = frozenset({
    "left", "right", "big", "Big", "bigg", "Bigg", "bigl", "bigr", "Bigl",
    "Bigr", "biggl", "biggr", "Biggl", "Biggr", "middle", "displaystyle",
    "textstyle", "scriptstyle", "limits", "nolimits", "nonumber", "notag",
    "centering", "hline",
})

_TEXT_WRAPPERS = frozenset({
    "text", "textrm", "textit", "textbf", "textnormal", "mbox", "hbox",
    "textsf", "texttt",
})

_MATH_WRAPPERS = frozenset({
    "mathrm", "mathbf", "mathit", "mathsf", "mathtt", "boldsymbol", "bm",
    "operatorname", "overline", "underline", "bar", "hat", "vec", "tilde",
    "widehat", "widetilde", "overrightarrow", "dot", "ddot", "boxed",
    "cancel", "underbrace", "overbrace", "phantom",
})

_BLACKBOARD = {"R": "ℝ", "N": "ℕ", "Z": "ℤ", "Q": "ℚ", "C": "ℂ"}

_LINE_ENVIRONMENTS = frozenset({
    "aligned", "align", "align*", "split", "gathered", "gather", "eqnarray",
    "eqnarray*",
})

_ESCAPED = {
    "{": "{", "}": "}", "%": "%", "$": "$", "&": "&", "#": "#", "_": "_",
    "|": "‖", ",": " ", ";": " ", ":": " ", " ": " ", "!": "",
}

_ALWAYS_SPACED = "=<>≤≥≠≈≡∼≅∝→⇒⇐←↔⇔∈∉∋⊂⊆⊃⊇∪∩×÷·"
_SIGNS = "+−±∓"

_INTEGER = re.compile(r"^[+\-−]?[0-9]+$")
_SIMPLE = re.compile(r"^[0-9.]+$|^[A-Za-zα-ωΑ-Ω]$")
_BIG_DELIMITER = re.compile(r"^(big|Big|bigg|Bigg)[lr]?$")
_MATRIX = re.compile(r"^[pbBvV]?matrix$")
_OPERAND_END = re.compile(r"[A-Za-z0-9α-ωΑ-Ω)\]}′'!∞%.°…]")
_LATEX_HINT = re.compile(r"\\[A-Za-z]+|\\[()\[\]{}]|\$|[\^_]\{")
_MATH_IN_CHUNK = re.compile(r"\\[A-Za-z]|[\^_]\{|\\[{}]")
_LATEX_SCRIPT_OR_COMMAND = re.compile(r"\\[A-Za-z]|[\^_]")
_DISPLAY_MATH = re.compile(
    r"\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)"
)
_DOLLAR_INLINE = re.compile(r"\$([^$\n]+?)\$")
_SUP_SUB_CHARS = "".join(_SUP.values()) + "".join(_SUB.values())


# ==========================
# Public API
# ==========================

def contains_latex(text):
    """True when the text still contains something that looks like LaTeX."""
    return _LATEX_HINT.search(text) is not None


def latex_to_readable(latex):
    """Converts a whole LaTeX formula into readable Unicode math."""
    if not latex.strip():
        return ""

    readable = _pretty(_convert(_strip_delimiters(latex)))

    # Last safety net: never let a backslash reach the user.
    return readable.replace("\\", "")


def ensure_readable(text):
    """Converts only the LaTeX parts of mixed text.

    Text without LaTeX is returned unchanged, so "costs $5 today" and
    "√2" stay as they are.
    """
    if not text or not contains_latex(text):
        return text

    def display_replacement(match):
        inner = next(group for group in match.groups() if group is not None)
        return latex_to_readable(inner)

    result = _DISPLAY_MATH.sub(display_replacement, text)

    def inline_replacement(match):
        inner = match.group(1)
        if _LATEX_SCRIPT_OR_COMMAND.search(inner):
            return latex_to_readable(inner)
        return match.group(0)

    result = _DOLLAR_INLINE.sub(inline_replacement, result)

    # Convert whitespace-separated chunks that still hold LaTeX. Braces keep
    # "\\frac{x + 1}{2}" together as one chunk.
    output = []
    chunk = []
    depth = 0

    def flush():
        if not chunk:
            return
        value = "".join(chunk)
        output.append(
            latex_to_readable(value) if _MATH_IN_CHUNK.search(value) else value
        )
        chunk.clear()

    for c in result:
        if c == "{":
            depth += 1
        elif c == "}":
            depth = depth - 1 if depth > 0 else 0

        if depth == 0 and c.isspace():
            flush()
            output.append(c)
        else:
            chunk.append(c)

    flush()

    joined = "".join(output)
    joined = re.sub(r"\\([A-Za-z]+)", r"\1", joined)
    return joined.replace("\\", "")


# ==========================
# Character Helpers
# ==========================

def _is_letter(c):
    return len(c) == 1 and ("a" <= c <= "z" or "A" <= c <= "Z")


def _is_letter_or_digit(c):
    return _is_letter(c) or (len(c) == 1 and "0" <= c <= "9")


def _rtrim_spaces(value):
    return value.rstrip(" ")


# ==========================
# Parsing Helpers
# ==========================

def _read_braced(s, start, open_="{", close="}"):
    """Reads a group starting at `start`. Returns (inner text, next index).

    An unclosed group takes the rest of the string. Returns None when the
    character at `start` is not the opening delimiter.
    """
    if start >= len(s) or s[start] != open_:
        return None

    depth = 0
    i = start
    while i < len(s):
        c = s[i]

        if c == "\\":
            i += 2
            continue

        if c == open_:
            depth += 1
        elif c == close:
            depth -= 1
            if depth == 0:
                return s[start + 1:i], i + 1

        i += 1

    return s[start + 1:], len(s)


def _skip_spaces(s, i):
    index = i
    while index < len(s) and s[index].isspace():
        index += 1
    return index


def _read_argument(s, i):
    """Reads one command argument: a braced group, a command, or one char."""
    index = _skip_spaces(s, i)

    if index >= len(s):
        return "", index

    if s[index] == "{":
        return _read_braced(s, index)

    if s[index] == "\\" and index + 1 < len(s):
        if _is_letter(s[index + 1]):
            end = index + 1
            while end < len(s) and _is_letter(s[end]):
                end += 1
            return s[index:end], end

        return s[index:index + 2], index + 2

    return s[index], index + 1


def _find_environment_end(s, i, env):
    begin_tag = "\\begin{" + env + "}"
    end_tag = "\\end{" + env + "}"
    depth = 1
    index = i

    while index < len(s):
        if s.startswith(begin_tag, index):
            depth += 1
            index += len(begin_tag)
            continue

        if s.startswith(end_tag, index):
            depth -= 1
            if depth == 0:
                return s[i:index], index + len(end_tag)
            index += len(end_tag)
            continue

        index += 1

    return s[i:], len(s)


def _split_rows(body):
    """Splits an environment body on top-level \\\\ row breaks."""
    rows = []
    depth = 0
    start = 0
    i = 0

    while i < len(body):
        c = body[i]

        if c == "\\" and i + 1 < len(body):
            if body[i + 1] == "\\" and depth == 0:
                rows.append(body[start:i])
                i += 2
                start = i
                continue

            i += 2
            continue

        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1

        i += 1

    rows.append(body[start:])
    return rows


def _is_simple(value):
    return _SIMPLE.search(value) is not None


def _is_wrapped(value):
    if not value.startswith("(") or not value.endswith(")"):
        return False

    depth = 0
    for i, ch in enumerate(value):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0 and i < len(value) - 1:
                return False

    return True


def _wrap(value):
    trimmed = value.strip()
    if _is_simple(trimmed) or _is_wrapped(trimmed):
        return trimmed
    return f"({trimmed})"


def _script(kind, content):
    c = content.strip()

    if not c:
        return ""

    if kind == "^":
        # f^{\prime} is written f′, not f^′.
        if set(c) == {"′"}:
            return c
        if _INTEGER.search(c) or c in ("n", "i"):
            return "".join(_SUP.get(ch, ch) for ch in c)
        return "^" + c if len(c) == 1 else f"^({c})"

    if _INTEGER.search(c) or (len(c) == 1 and c in _SUB):
        return "".join(_SUB.get(ch, ch) for ch in c)
    return "_" + c if len(c) == 1 else f"_({c})"


def _unescape_text(text):
    if "\\" in text:
        return _convert(text, text_mode=True)
    return text.replace("~", " ")


# ==========================
# LaTeX to Linear Unicode
# (spacing is fixed later by _pretty)
# ==========================

def _convert(s, text_mode=False):
    out = []
    i = 0

    while i < len(s):
        c = s[i]

        if c == "\\":
            if i + 1 >= len(s):
                i += 1
                continue

            nxt = s[i + 1]

            if nxt == "\\":
                out.append("\n")
                i += 2
                continue

            if _is_letter(nxt):
                end = i + 1
                while end < len(s) and _is_letter(s[end]):
                    end += 1
                name = s[i + 1:end]
                i = _convert_command(s, end, name, out, text_mode)
                continue

            out.append(_ESCAPED.get(nxt, nxt))
            i += 2
            continue

        if c == "{":
            inner, after = _read_braced(s, i)
            out.append(_convert(inner, text_mode))
            i = after
            continue

        if c == "}":
            i += 1
            continue

        if c in "^_" and not text_mode:
            arg, after = _read_argument(s, i + 1)
            i = after
            out.append(_script(c, _convert(arg)))
            continue

        if c == "&":
            i += 1
            continue

        if c == "~":
            out.append(" ")
            i += 1
            continue

        if c.isspace():
            if text_mode:
                out.append(" ")
            i += 1
            continue

        if c == "-" and not text_mode:
            out.append("−")
            i += 1
            continue

        out.append(c)
        i += 1

    return "".join(out)


def _convert_command(s, start, name, out, text_mode):
    """Handles one \\name command. Returns the index after its arguments."""
    i = start

    if name in ("frac", "dfrac", "tfrac", "cfrac"):
        numerator, after_num = _read_argument(s, i)
        denominator, after_den = _read_argument(s, after_num)
        out.append(f"{_wrap(_convert(numerator))}/{_wrap(_convert(denominator))}")
        return after_den

    if name in ("binom", "dbinom", "tbinom"):
        n_value, after_n = _read_argument(s, i)
        k_value, after_k = _read_argument(s, after_n)
        out.append(f"C({_convert(n_value)},{_convert(k_value)})")
        return after_k

    if name == "sqrt":
        i = _skip_spaces(s, i)
        index = ""

        if i < len(s) and s[i] == "[":
            group, i = _read_braced(s, i, "[", "]")
            index = _convert(group).strip()

        argument, i = _read_argument(s, i)
        radicand = _convert(argument).strip()

        if index in ("", "2"):
            symbol = "√"
        elif index == "3":
            symbol = "∛"
        elif index == "4":
            symbol = "∜"
        elif re.fullmatch(r"[0-9]+", index) or index == "n":
            symbol = _script("^", index) + "√"
        else:
            symbol = f"√[{index}]"

        out.append(symbol)
        out.append(radicand if _is_simple(radicand) else f"({radicand})")
        return i

    if name in _IGNORED:
        if name in ("left", "right", "middle") or _BIG_DELIMITER.search(name):
            i = _skip_spaces(s, i)
            # "\left." and "\right." are invisible delimiters.
            if i < len(s) and s[i] == ".":
                i += 1
        return i

    if name in _TEXT_WRAPPERS:
        argument, i = _read_argument(s, i)
        out.append(_unescape_text(argument))
        return i

    if name == "mathbb":
        argument, i = _read_argument(s, i)
        value = argument.strip()
        out.append(_BLACKBOARD[value] if value in _BLACKBOARD else _convert(value))
        return i

    if name in _MATH_WRAPPERS:
        argument, i = _read_argument(s, i)
        out.append(_convert(argument, text_mode))
        return i

    if name == "begin":
        env_argument, i = _read_argument(s, i)
        env = env_argument.strip()

        if env in ("array", "tabular"):
            # Skip the column spec, e.g. {cc}.
            _, i = _read_argument(s, i)

        body, i = _find_environment_end(s, i, env)
        line_environment = env in _LINE_ENVIRONMENTS

        rows = []
        for row in _split_rows(body):
            if line_environment:
                # A space, not nothing: "\quad&Add" must not become the
                # unknown command "\quadAdd", which would drop the word.
                converted = _convert(row.replace("&", " ")).strip()
            else:
                converted = (
                    _convert(row.replace("&", "\u0001"))
                    .replace("\u0001", ", ")
                    .strip()
                )
            if converted:
                rows.append(converted)

        if _MATRIX.search(env):
            out.append("[" + "; ".join(rows) + "]")
        else:
            out.append("\n".join(rows))

        return i

    if name == "end":
        _, i = _read_argument(s, i)
        return i

    if name in _SPACES:
        out.append(" ")
        return i

    if name in ("hspace", "vspace", "label", "tag"):
        _, i = _read_argument(s, i)
        return i

    if name in _FUNCTIONS:
        out.append(name)
        following_index = _skip_spaces(s, i)
        following = s[following_index] if following_index < len(s) else ""
        if following and (_is_letter_or_digit(following) or following == "\\"):
            out.append(" ")
        return i

    symbol = _SYMBOLS.get(name)
    if symbol is not None:
        out.append(symbol)
        return i

    # Unknown (possibly hallucinated) command: keep its argument, drop the
    # command name.
    next_index = _skip_spaces(s, i)
    if next_index < len(s) and s[next_index] == "{":
        group, after = _read_braced(s, next_index)
        out.append(_convert(group, text_mode))
        return after

    return i


# ==========================
# Spacing
# ==========================

def _is_operand_end(out):
    """True when the text before a + or − ends with an operand.

    That makes the sign a binary operator ("x − 2") instead of a negative
    sign ("−2").
    """
    k = len(out) - 1
    while k >= 0 and out[k] == " ":
        k -= 1

    if k < 0:
        return False

    previous = out[k]

    if previous == "\n":
        return False

    if _OPERAND_END.search(previous) or previous in _SUP_SUB_CHARS:
        return True

    if previous == "|":
        # An even number of bars means this bar closes |x − 3|.
        line_start = out.rfind("\n", 0, k + 1) + 1
        bars = out[line_start:k + 1].count("|")
        return bars % 2 == 0

    return False


def _pretty(raw):
    out = ""

    for i, c in enumerate(raw):
        if c == " ":
            if out and not out.endswith(" ") and not out.endswith("\n"):
                out += " "
            continue

        if c == "\n":
            out = _rtrim_spaces(out) + "\n"
            continue

        if c in _ALWAYS_SPACED:
            out = _rtrim_spaces(out) + f" {c} "
            continue

        if c in _SIGNS:
            if _is_operand_end(out):
                out = _rtrim_spaces(out) + f" {c} "
            else:
                out += c
            continue

        if c == ",":
            # Keep thousands separators such as 1,000 together.
            thousands = (
                re.search(r"[0-9]$", _rtrim_spaces(out)) is not None
                and re.match(r"[0-9]{3}(?![0-9])", raw[i + 1:]) is not None
            )
            out = _rtrim_spaces(out) + ("," if thousands else ", ")
            continue

        if c in ")]":
            out = _rtrim_spaces(out) + c
            continue

        if out.endswith("( ") or out.endswith("[ "):
            out = _rtrim_spaces(out)

        out += c

    lines = []
    for line in out.split("\n"):
        line = re.sub(r" {2,}", " ", line)
        line = re.sub(r"([(\[]) ", r"\1", line)
        line = re.sub(r" ([)\],])", r"\1", line)
        line = line.strip()
        if line:
            lines.append(line)

    return "\n".join(lines)


def _strip_delimiters(value):
    text = re.sub(r"```(?:latex|math|tex)?", "", value).strip()

    pairs = [("$$", "$$"), ("\\[", "\\]"), ("\\(", "\\)"), ("$", "$")]

    for open_delimiter, close_delimiter in pairs:
        if (
            text.startswith(open_delimiter)
            and text.endswith(close_delimiter)
            and len(text) >= len(open_delimiter) + len(close_delimiter)
        ):
            return text[
                len(open_delimiter):len(text) - len(close_delimiter)
            ].strip()

    return text