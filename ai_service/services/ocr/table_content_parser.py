from html.parser import HTMLParser


class _HtmlTableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)

        self.rows: list[list[str]] = []

        self._current_row: list[str] | None = None
        self._current_cell_parts: list[str] | None = None

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        normalized_tag = tag.lower()

        if normalized_tag == "tr":
            self._current_row = []

        if normalized_tag in {"td", "th"}:
            self._current_cell_parts = []

    def handle_data(self, data: str) -> None:
        if self._current_cell_parts is not None:
            self._current_cell_parts.append(data)

    def handle_endtag(self, tag: str) -> None:
        normalized_tag = tag.lower()

        if normalized_tag in {"td", "th"}:
            if self._current_row is None:
                self._current_row = []

            cell_content = " ".join(
                part.strip() for part in self._current_cell_parts or [] if part.strip()
            ).strip()

            self._current_row.append(cell_content)
            self._current_cell_parts = None

        if normalized_tag == "tr":
            if self._current_row:
                self.rows.append(self._current_row)

            self._current_row = None


class TableContentParser:
    # Read out in place of an empty cell, so a Braille reader knows the
    # cell is there (for example a space to write an answer).
    BLANK_CELL = "blank"

    ALL_BLANK_ROW = "all blank"

    @classmethod
    def parse(
        cls,
        content: str,
    ) -> list[list[str]]:
        if not isinstance(content, str) or not content.strip():
            return []

        parser = _HtmlTableParser()
        parser.feed(content)
        parser.close()

        # Rows whose cells are all empty are kept; only rows without
        # any cells are dropped.
        rows = [[cell.strip() for cell in row] for row in parser.rows if row]

        # A table with no text at all is not a table.
        if not any(cell for row in rows for cell in row):
            return []

        return rows

    @classmethod
    def to_accessible_text(
        cls,
        rows: list[list[str]],
    ) -> str:
        if not rows:
            return ""

        lines = ["Table"]

        for index, row in enumerate(rows, start=1):
            cells = [cell.strip() or cls.BLANK_CELL for cell in row]

            if not any(cell.strip() for cell in row):
                lines.append(f"Row {index}: {cls.ALL_BLANK_ROW}")
                continue

            lines.append(f"Row {index}: {'; '.join(cells)}")

        lines.append("End table")

        return "\n".join(lines)
