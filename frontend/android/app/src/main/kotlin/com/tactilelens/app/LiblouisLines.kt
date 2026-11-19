package com.tactilelens.app

/** Line handling around Liblouis (no native code, so it can be tested). */
object LiblouisLines {
    /**
     * Translates each line of [content] with [translateLine] and joins the
     * results with line breaks, like the server's lou_translate, which
     * reads its input line by line. Blank lines are dropped (OCR text has
     * none after reflow).
     */
    fun translateLineByLine(
        content: String,
        translateLine: (String) -> String,
    ): String {
        return content
            .split('\n')
            .map { line -> line.trim() }
            .filter { line -> line.isNotEmpty() }
            .joinToString("\n") { line -> translateLine(line) }
    }
}
