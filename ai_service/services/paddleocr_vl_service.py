import os
import tempfile
import threading
import time
from pathlib import Path
from typing import Any

import numpy as np
from paddleocr import PaddleOCRVL
from PIL import Image, ImageOps

from services.braille_math_normalizer import (
    BrailleMathNormalizer,
)
from services.braille_translation_service import (
    BrailleTranslationService,
)
from services.ocr_content_normalizer import (
    OcrContentNormalizer,
)
from services.table_content_parser import (
    TableContentParser,
)


class PaddleOcrVlService:
    """Reusable and optimized PaddleOCR-VL recognition service."""

    FORMULA_BLOCK_TYPES = frozenset(
        {
            "display_formula",
            "inline_formula",
            "formula",
        }
    )

    TABLE_BLOCK_TYPES = frozenset(
        {
            "table",
        }
    )

    LATEX_FORMULA_MARKERS = (
        r"\frac",
        r"\sqrt",
        r"\sum",
        r"\int",
        r"\begin",
        r"\left",
        r"\right",
    )

    DEFAULT_MAX_IMAGE_DIMENSION = 2000
    DEFAULT_JPEG_QUALITY = 88

    def __init__(self) -> None:
        self.pipeline_version = os.getenv(
            "PADDLEOCR_PIPELINE_VERSION",
            "v1.6",
        )

        self.device = os.getenv(
            "PADDLEOCR_DEVICE",
            "gpu:0",
        )

        self.max_image_dimension = self._read_positive_integer(
            "PADDLEOCR_MAX_IMAGE_DIMENSION",
            self.DEFAULT_MAX_IMAGE_DIMENSION,
        )

        self.jpeg_quality = self._read_bounded_integer(
            "PADDLEOCR_JPEG_QUALITY",
            self.DEFAULT_JPEG_QUALITY,
            minimum=70,
            maximum=95,
        )

        self.debug_blocks = self._read_boolean(
            "PADDLEOCR_DEBUG_BLOCKS",
            default=False,
        )

        self.model_name = (
            "PaddleOCR-VL-"
            f"{self.pipeline_version.lstrip('v')}"
        )

        # Prevent concurrent requests from exhausting laptop GPU memory.
        self._inference_lock = threading.Lock()

        self._braille_translator = BrailleTranslationService()

        initialization_started = time.perf_counter()

        print(
            "Initializing PaddleOCR-VL "
            f"{self.pipeline_version} on {self.device}..."
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

        initialization_seconds = (
            time.perf_counter() - initialization_started
        )

        print(
            "PaddleOCR-VL initialized in "
            f"{initialization_seconds:.2f} seconds."
        )

    def scan_document(
        self,
        image_path: Path,
    ) -> dict[str, Any]:
        if not image_path.is_file():
            raise ValueError(
                "The uploaded image could not be found."
            )

        total_started = time.perf_counter()

        optimized_image_path: Path | None = None

        try:
            preprocessing_started = time.perf_counter()

            optimized_image_path = self._prepare_image(
                image_path
            )

            with Image.open(optimized_image_path) as optimized_image:
                processed_width, processed_height = optimized_image.size

            preprocessing_seconds = (
                time.perf_counter() - preprocessing_started
            )

            original_size = image_path.stat().st_size

            optimized_size = (
                optimized_image_path.stat().st_size
            )

            print(
                "Image preprocessing completed in "
                f"{preprocessing_seconds:.2f} seconds. "
                f"Original: {self._format_bytes(original_size)}, "
                f"optimized: {self._format_bytes(optimized_size)}."
            )

            inference_started = time.perf_counter()

            with self._inference_lock:
                predictions = list(
                    self._pipeline.predict(
                        input=str(optimized_image_path),
                        use_layout_detection=True,
                        use_queues=False,
                    )
                )

            inference_seconds = (
                time.perf_counter() - inference_started
            )

            print(
                "PaddleOCR-VL inference completed in "
                f"{inference_seconds:.2f} seconds."
            )

            if not predictions:
                raise ValueError(
                    "No document content was recognized."
                )

            serialization_started = time.perf_counter()

            pages = [
                self._serialize_page(
                    result,
                    fallback_page_index=index,
                    fallback_width=processed_width,
                    fallback_height=processed_height,
                )
                for index, result in enumerate(predictions)
            ]

            ordered_blocks = [
                block
                for page in pages
                for block in page["blocks"]
            ]

            serialization_seconds = (
                time.perf_counter() - serialization_started
            )

            total_seconds = (
                time.perf_counter() - total_started
            )

            print(
                "OCR serialization and Braille translation "
                f"completed in {serialization_seconds:.2f} "
                "seconds."
            )

            print(
                "Complete document scan finished in "
                f"{total_seconds:.2f} seconds with "
                f"{len(ordered_blocks)} recognized blocks."
            )

            return {
                "success": True,
                "model": self.model_name,
                "pipeline_version": self.pipeline_version,
                "device": self.device,
                "page_count": len(pages),
                "blocks": ordered_blocks,
                "pages": pages,
                "processing_time_ms": round(
                    total_seconds * 1000
                ),
                "timings": {
                    "preprocessing_ms": round(
                        preprocessing_seconds * 1000
                    ),
                    "inference_ms": round(
                        inference_seconds * 1000
                    ),
                    "serialization_ms": round(
                        serialization_seconds * 1000
                    ),
                },
            }
        finally:
            self._remove_temporary_image(
                optimized_image_path,
                original_image_path=image_path,
            )

    def _prepare_image(
        self,
        image_path: Path,
    ) -> Path:
        """
        Correct phone orientation and limit large camera images
        before PaddleOCR-VL inference.
        """

        temporary_file = tempfile.NamedTemporaryFile(
            prefix="tactilelens_ocr_",
            suffix=".jpg",
            delete=False,
        )

        temporary_path = Path(temporary_file.name)
        temporary_file.close()

        try:
            with Image.open(image_path) as source_image:
                corrected_image = ImageOps.exif_transpose(
                    source_image
                )

                rgb_image = corrected_image.convert("RGB")

                original_width, original_height = (
                    rgb_image.size
                )

                longest_side = max(
                    original_width,
                    original_height,
                )

                if longest_side > self.max_image_dimension:
                    scale = (
                        self.max_image_dimension
                        / longest_side
                    )

                    resized_width = max(
                        1,
                        round(original_width * scale),
                    )

                    resized_height = max(
                        1,
                        round(original_height * scale),
                    )

                    rgb_image = rgb_image.resize(
                        (
                            resized_width,
                            resized_height,
                        ),
                        Image.Resampling.LANCZOS,
                    )

                    print(
                        "OCR image resized from "
                        f"{original_width}x{original_height} "
                        f"to {resized_width}x{resized_height}."
                    )
                else:
                    print(
                        "OCR image retained at "
                        f"{original_width}x{original_height}."
                    )

                rgb_image.save(
                    temporary_path,
                    format="JPEG",
                    quality=self.jpeg_quality,
                    optimize=True,
                    progressive=False,
                )

            return temporary_path
        except Exception:
            temporary_path.unlink(missing_ok=True)
            raise

    def _serialize_page(
        self,
        result: Any,
        *,
        fallback_page_index: int,
        fallback_width: int,
        fallback_height: int,
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

        if not isinstance(raw_blocks, list):
            raw_blocks = []

        if self.debug_blocks:
            for index, block in enumerate(raw_blocks):
                if not isinstance(block, dict):
                    continue

                print(
                    "OCR BLOCK",
                    index,
                    {
                        "label": block.get("block_label"),
                        "content": block.get("block_content"),
                        "bbox": self._normalized_bbox(block),
                    },
                )

        blocks = [
            self._serialize_block(
                block,
                fallback_id=index,
                fallback_order=index,
            )
            for index, block in enumerate(raw_blocks)
            if isinstance(block, dict)
        ]

        return {
            "page_index": self._positive_integer_or_default(
                result_data.get("page_index"),
                fallback_page_index,
                allow_zero=True,
            ),
            "width": self._positive_integer_or_default(
                result_data.get("width"),
                fallback_width,
            ),
            "height": self._positive_integer_or_default(
                result_data.get("height"),
                fallback_height,
            ),
            "blocks": blocks,
        }

    def _serialize_block(
        self,
        block: dict[str, Any],
        *,
        fallback_id: int,
        fallback_order: int,
    ) -> dict[str, Any]:
        block_type = str(
            block.get(
                "block_label",
                "unknown",
            )
        ).strip().lower()

        raw_content = str(
            block.get(
                "block_content",
                "",
            )
        ).strip()

        is_table = (
            block_type in self.TABLE_BLOCK_TYPES
            or "<table" in raw_content.lower()
        )

        table_rows = (
            TableContentParser.parse(raw_content)
            if is_table
            else []
        )

        if is_table and table_rows:
            normalized_content = (
                TableContentParser.to_accessible_text(
                    table_rows
                )
            )
        else:
            normalized_content = (
                OcrContentNormalizer.normalize(
                    content=raw_content,
                    block_type=block_type,
                )
            )

        is_formula = (
            not is_table
            and (
                block_type in self.FORMULA_BLOCK_TYPES
                or any(
                    marker in raw_content
                    for marker in self.LATEX_FORMULA_MARKERS
                )
            )
        )

        if is_table:
            braille_source_content = normalized_content
        elif is_formula:
            braille_source_content = (
                BrailleMathNormalizer.normalize(
                    raw_content
                )
            )
        else:
            braille_source_content = normalized_content

        braille_result = self._braille_translator.translate_block(
            braille_source_content,
            is_formula=is_formula,
            is_table=is_table,
        )

        bounding_box = self._normalized_bbox(block)

        polygon_points = self._normalized_polygon(
            block,
            fallback_bbox=bounding_box,
        )

        return {
            "id": self._integer_or_default(
                block.get("block_id"),
                fallback_id,
            ),
            "order": self._integer_or_default(
                block.get("block_order"),
                fallback_order,
            ),
            "type": block_type,
            "content": normalized_content,
            "raw_content": raw_content,
            "normalized_content": normalized_content,
            "bbox": bounding_box,
            "polygon_points": polygon_points,
            "is_text": block_type == "text",
            "is_formula": is_formula,
            "is_table": is_table,
            "table_rows": table_rows,
            "braille_content": braille_result["content"],
            "braille_code": braille_result["code"],
            "braille_success": braille_result[
                "success"
            ],
            "braille_error": braille_result["error"],
        }

    def _normalized_bbox(
        self,
        block: dict[str, Any],
    ) -> list[float]:
        raw_bbox = self._to_builtin(
            block.get("block_bbox")
        )

        if isinstance(raw_bbox, list) and len(raw_bbox) >= 4:
            try:
                first_x = float(raw_bbox[0])
                first_y = float(raw_bbox[1])
                second_x = float(raw_bbox[2])
                second_y = float(raw_bbox[3])

                left = min(first_x, second_x)
                top = min(first_y, second_y)
                right = max(first_x, second_x)
                bottom = max(first_y, second_y)

                if right > left and bottom > top:
                    return [left, top, right, bottom]
            except (TypeError, ValueError):
                pass

        raw_polygon = self._to_builtin(
            block.get("block_polygon_points")
        )

        if isinstance(raw_polygon, list):
            valid_points: list[tuple[float, float]] = []

            for point in raw_polygon:
                if not isinstance(point, list) or len(point) < 2:
                    continue

                try:
                    valid_points.append(
                        (float(point[0]), float(point[1]))
                    )
                except (TypeError, ValueError):
                    continue

            if valid_points:
                x_values = [point[0] for point in valid_points]
                y_values = [point[1] for point in valid_points]

                left = min(x_values)
                top = min(y_values)
                right = max(x_values)
                bottom = max(y_values)

                if right > left and bottom > top:
                    return [left, top, right, bottom]

        return []

    def _normalized_polygon(
        self,
        block: dict[str, Any],
        *,
        fallback_bbox: list[float],
    ) -> list[list[float]]:
        raw_polygon = self._to_builtin(
            block.get("block_polygon_points")
        )

        normalized_points: list[list[float]] = []

        if isinstance(raw_polygon, list):
            for point in raw_polygon:
                if not isinstance(point, list) or len(point) < 2:
                    continue

                try:
                    normalized_points.append(
                        [float(point[0]), float(point[1])]
                    )
                except (TypeError, ValueError):
                    continue

        if normalized_points:
            return normalized_points

        if len(fallback_bbox) < 4:
            return []

        left, top, right, bottom = fallback_bbox

        return [
            [left, top],
            [right, top],
            [right, bottom],
            [left, bottom],
        ]

    @staticmethod
    def _integer_or_default(
        value: Any,
        default: int,
    ) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _positive_integer_or_default(
        value: Any,
        default: int,
        *,
        allow_zero: bool = False,
    ) -> int:
        try:
            parsed_value = int(value)
        except (TypeError, ValueError):
            return default

        if allow_zero:
            return parsed_value if parsed_value >= 0 else default

        return parsed_value if parsed_value > 0 else default

    def _remove_temporary_image(
        self,
        optimized_image_path: Path | None,
        *,
        original_image_path: Path,
    ) -> None:
        if optimized_image_path is None:
            return

        if (
            optimized_image_path.resolve()
            == original_image_path.resolve()
        ):
            return

        try:
            optimized_image_path.unlink(
                missing_ok=True
            )
        except OSError as error:
            print(
                "Unable to delete temporary OCR image: "
                f"{error}"
            )

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

    @staticmethod
    def _read_positive_integer(
        name: str,
        default: int,
    ) -> int:
        raw_value = os.getenv(name, "").strip()

        if not raw_value:
            return default

        try:
            value = int(raw_value)
        except ValueError:
            return default

        return value if value > 0 else default

    @staticmethod
    def _read_bounded_integer(
        name: str,
        default: int,
        *,
        minimum: int,
        maximum: int,
    ) -> int:
        value = (
            PaddleOcrVlService._read_positive_integer(
                name,
                default,
            )
        )

        return max(
            minimum,
            min(maximum, value),
        )

    @staticmethod
    def _read_boolean(
        name: str,
        *,
        default: bool,
    ) -> bool:
        raw_value = os.getenv(
            name,
            "",
        ).strip().lower()

        if not raw_value:
            return default

        return raw_value in {
            "1",
            "true",
            "yes",
            "on",
        }

    @staticmethod
    def _format_bytes(
        size: int,
    ) -> str:
        megabyte = 1024 * 1024

        if size >= megabyte:
            return (
                f"{size / megabyte:.1f} MB"
            )

        return f"{size / 1024:.1f} KB"
