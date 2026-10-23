import unittest

from services.ocr.table_content_parser import TableContentParser

_TABLE = (
    "<table>"
    "<tr><td>Input</td><td>A</td><td>1</td></tr>"
    "<tr><td>Output</td><td>B</td><td></td></tr>"
    "<tr><td></td><td></td><td></td></tr>"
    "<tr></tr>"
    "</table>"
)


class TableContentParserTests(unittest.TestCase):
    def test_blank_cells_and_fully_blank_rows_are_kept(self):
        self.assertEqual(
            TableContentParser.parse(_TABLE),
            [["Input", "A", "1"], ["Output", "B", ""], ["", "", ""]],
        )

    def test_accessible_text_says_blank(self):
        rows = TableContentParser.parse(_TABLE)

        self.assertEqual(
            TableContentParser.to_accessible_text(rows),
            "Table\n"
            "Row 1: Input; A; 1\n"
            "Row 2: Output; B; blank\n"
            "Row 3: all blank\n"
            "End table",
        )

    def test_cell_order_is_kept_around_blanks(self):
        rows = TableContentParser.parse(
            "<table><tr><td></td><td>x</td><td></td><td>y</td></tr></table>"
        )

        self.assertEqual(rows, [["", "x", "", "y"]])
        self.assertEqual(
            TableContentParser.to_accessible_text(rows),
            "Table\nRow 1: blank; x; blank; y\nEnd table",
        )

    def test_header_cells_count_like_data_cells(self):
        rows = TableContentParser.parse(
            "<table><tr><th>Name</th><th></th></tr></table>"
        )

        self.assertEqual(rows, [["Name", ""]])

    def test_a_table_without_any_text_is_not_a_table(self):
        self.assertEqual(
            TableContentParser.parse("<table><tr><td></td></tr></table>"),
            [],
        )
        self.assertEqual(TableContentParser.to_accessible_text([]), "")

    def test_empty_input(self):
        self.assertEqual(TableContentParser.parse(""), [])
        self.assertEqual(TableContentParser.parse(None), [])


if __name__ == "__main__":
    unittest.main()
