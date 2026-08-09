import os
import threading
from pathlib import Path
from typing import Any

import numpy as np
from paddleocr import PaddleOCRVL

from services.ocr_content_normalizer import (
    OcrContentNormalizer,
)

from services.braille_translation_service import (
    BrailleTranslationService,
)


class PaddleOcrVlService:
    """Reusable PaddleOCR-VL document recognition service."""

    FORMULA_BLOCK_TYPES = frozenset(
        {
            "display_formula",
            "inline_formula",
            "formula",
        }
    )

    def __init__(self) -> None:
        self.pipeline_version = os.getenv(
            "PADDLEOCR_PIPELINE_VERSION",
            "v1.6",
        )

        self.device = os.getenv(
            "PADDLEOCR_DEVICE",
            "gpu:0",
        )

        self.model_name = (
            "PaddleOCR-VL-"
            f"{self.pipeline_version.lstrip('v')}"
        )

        # Prevent simultaneous requests from exhausting
        # the available 6 GB GPU memory.
        self._inference_lock = threading.Lock()

        self._braille_translator = (
            BrailleTranslationService()
        )

        self._pipeline = PaddleOCRVL(
            pipeline_version=self.pipeline_version,
            device=self.device,
            engine="paddle",
            vl_rec_backend="native",
            use_layout_detection=True,
            use_doc_orientation_classify=False,
            use_doc_unwarping=False,
            use_queues=False,
        )

    def scan_document(
        self,
        image_path: Path,
    ) -> dict[str, Any]:
        if not image_path.is_file():
            raise ValueError(
                "The uploaded image could not be found."
            )

        with self._inference_lock:
            predictions = self._pipeline.predict(
                input=str(image_path),
                use_layout_detection=True,
                use_queues=False,
            )

        if not predictions:
            raise ValueError(
                "No document content was recognized."
            )

        pages = [
            self._serialize_page(result)
            for result in predictions
        ]

        ordered_blocks = [
            block
            for page in pages
            for block in page["blocks"]
        ]

        return {
            "success": True,
            "model": self.model_name,
            "pipeline_version": self.pipeline_version,
            "device": self.device,
            "page_count": len(pages),
            "blocks": ordered_blocks,
            "pages": pages,
        }

    def _serialize_page(
        self,
        result: Any,
    ) -> dict[str, Any]:
        json_result = result.json
        result_data = json_result.get(
            "res",
            json_result,
        )

        raw_blocks = result_data.get(
            "parsing_res_list",
            [],
        )

        blocks = [
            self._serialize_block(block)
            for block in raw_blocks
        ]

        return {
            "page_index": result_data.get(
                "page_index"
            ),
            "width": result_data.get("width"),
            "height": result_data.get("height"),
            "blocks": blocks,
        }

    def _serialize_block(
        self,
        block: dict[str, Any],
    ) -> dict[str, Any]:
        block_type = str(
            block.get(
                "block_label",
                "unknown",
            )
        ).strip()

        raw_content = str(
            block.get(
                "block_content",
                "",
            )
        ).strip()

        normalized_content = (
            OcrContentNormalizer.normalize(
                content=raw_content,
                block_type=block_type,
            )
        )

        is_formula = (
            block_type in self.FORMULA_BLOCK_TYPES
        )

        braille_result = (
            self._braille_translator.translate_block(
                normalized_content,
                is_formula=is_formula,
            )
        )

        return {
            "id": block.get("block_id"),
            "order": block.get("block_order"),
            "type": block_type,

            # Retained for compatibility with the current
            # Flutter model and existing API consumers.
            "content": normalized_content,

            # Original PaddleOCR-VL output for debugging,
            # validation, and traceability.
            "raw_content": raw_content,

            # Clean content used by previews and future
            # UEB/Nemeth translation.
            "normalized_content": normalized_content,

            "bbox": self._to_builtin(
                block.get("block_bbox")
            ),
            "polygon_points": self._to_builtin(
                block.get(
                    "block_polygon_points"
                )
            ),
           "is_text": block_type == "text",
            "is_formula": is_formula,

            # Liblouis translation result.
            "braille_content": braille_result["content"],
            "braille_code": braille_result["code"],
            "braille_success": braille_result["success"],
            "braille_error": braille_result["error"],
        }

    def _to_builtin(
        self,
        value: Any,
    ) -> Any:
        if isinstance(value, np.ndarray):
            return value.tolist()

        if isinstance(value, np.generic):
            return value.item()

        if isinstance(value, dict):
            return {
                key: self._to_builtin(item)
                for key, item in value.items()
            }

        if isinstance(value, (list, tuple)):
            return [
                self._to_builtin(item)
                for item in value
            ]

        return value