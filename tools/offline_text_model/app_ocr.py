"""The offline app's PP-OCRv6 path, ported to Python for this PC.

Line by line from the app's ppocr-sdk (frontend/android/ppocr-sdk) with
the settings in PaddleOnnxOcrEngine.kt. OpenCV calls are the same
functions the app calls, with the same arguments:

  detection    DetPreprocessor.kt  ImageUtils.resizeToMultipleOf32
               (limit 1280, type "max", max side 1280, BGR), mean/std
               normalisation; DBPostProcessor.kt (thresh 0.3, box thresh
               0.6, unclip 1.5, fast score, no dilation, max 3000);
               PolygonUnclip.kt; QuadGeometry.kt
  reading order BoxSorter.kt (10 px row band)
  crop         QuadTextCrop.kt (minAreaRect, perspective warp, INTER_CUBIC,
               BORDER_REPLICATE, rotate tall crops)
  recognition  RecPreprocessor.kt (BGR->RGB, height 48, width
               ceil(48*w/h) up to 3200, INTER_LINEAR, x/127.5-1);
               CTCDecoder.kt (greedy, blank 0, collapse repeats, mean prob)
  dictionary   ModelConfig.kt (common.load_character_list)

Images are read with cv2.imread (BGR), like the app's imdecode.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import onnxruntime as ort

from common import DET_MODEL, REC_CONFIG, REC_MODEL, load_character_list

# PaddleOnnxOcrEngine.kt
DET_LIMIT_SIDE_LEN = 1280
DET_LIMIT_TYPE = "max"
DET_MAX_SIDE_LIMIT = 1280
DET_THRESH = 0.3
DET_BOX_THRESH = 0.6
DET_UNCLIP_RATIO = 1.5
DET_MAX_CANDIDATES = 3000  # PaddleOCRConfig default

# RecPreprocessor.kt
REC_HEIGHT = 48
REC_MAX_WIDTH = 3200

_DET_MEAN = (0.485, 0.456, 0.406)
_DET_STD = (0.229, 0.224, 0.225)


def round_half_to_even(value: float) -> int:
    # MathUtils.roundHalfToEven
    floored = math.floor(value)
    diff = value - floored
    if diff < 0.5:
        return int(floored)
    if diff > 0.5:
        return int(floored) + 1
    return int(floored) if int(floored) % 2 == 0 else int(floored) + 1


# ------------------------------------------------------------- detection


def resize_to_multiple_of_32(image: np.ndarray) -> np.ndarray:
    h, w = image.shape[:2]
    if DET_LIMIT_TYPE == "max":
        ratio = DET_LIMIT_SIDE_LEN / max(h, w) if max(h, w) > DET_LIMIT_SIDE_LEN else 1.0
    else:
        raise ValueError(DET_LIMIT_TYPE)
    new_h, new_w = int(h * ratio), int(w * ratio)
    if max(new_h, new_w) > DET_MAX_SIDE_LIMIT:
        ratio = DET_MAX_SIDE_LIMIT / max(new_h, new_w)
        new_h, new_w = int(new_h * ratio), int(new_w * ratio)
    new_h = max(round_half_to_even(new_h / 32.0) * 32, 32)
    new_w = max(round_half_to_even(new_w / 32.0) * 32, 32)
    return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_LINEAR)


def det_preprocess(bgr: np.ndarray) -> np.ndarray:
    # detImgMode "BGR": channels stay B, G, R; mean/std applied per channel
    # index exactly as DetPreprocessor.kt does.
    resized = resize_to_multiple_of_32(bgr).astype(np.float32)
    channels = []
    for c in range(3):
        channels.append((resized[:, :, c] * (1.0 / 255.0) - _DET_MEAN[c]) / _DET_STD[c])
    return np.stack(channels, axis=0)[None].astype(np.float32)


def order_min_area_rect_points(points) -> list[tuple[float, float]]:
    # QuadGeometry.orderMinAreaRectPoints
    s = sorted(points, key=lambda p: p[0])
    top_left, bottom_left = (s[0], s[1]) if s[1][1] > s[0][1] else (s[1], s[0])
    top_right, bottom_right = (s[2], s[3]) if s[3][1] > s[2][1] else (s[3], s[2])
    return [top_left, top_right, bottom_right, bottom_left]


def _signed_area(points) -> float:
    total = 0.0
    for i, (x1, y1) in enumerate(points):
        x2, y2 = points[(i + 1) % len(points)]
        total += x1 * y2 - x2 * y1
    return total / 2.0


def unclip(points, ratio: float):
    # PolygonUnclip.unclip: offset by area*ratio/perimeter with round joins.
    eps = 1e-6
    if len(points) < 3:
        return points
    signed = _signed_area(points)
    area = abs(signed)
    perimeter = sum(
        math.hypot(points[(i + 1) % len(points)][0] - x, points[(i + 1) % len(points)][1] - y)
        for i, (x, y) in enumerate(points)
    )
    if area <= eps or perimeter <= eps:
        return points
    distance = area * ratio / perimeter
    if distance <= eps:
        return points
    clockwise = signed > 0.0
    normals = []
    for i, (x1, y1) in enumerate(points):
        x2, y2 = points[(i + 1) % len(points)]
        dx, dy = x2 - x1, y2 - y1
        length = math.hypot(dx, dy)
        if length <= eps:
            return points
        normals.append((dy / length, -dx / length) if clockwise else (-dy / length, dx / length))

    ratio_cos = min(max(1.0 - 0.25 / distance, -1.0), 1.0)
    step = 2.0 * math.acos(ratio_cos)
    if not (math.isfinite(step) and step > eps):
        step = math.pi / 8.0

    expanded: list[tuple[float, float]] = []
    for i, (cx, cy) in enumerate(points):
        start = math.atan2(normals[i - 1][1], normals[i - 1][0])
        end = math.atan2(normals[i][1], normals[i][0])
        if clockwise:
            while end < start:
                end += 2.0 * math.pi
        else:
            while end > start:
                end -= 2.0 * math.pi
        sweep = end - start
        steps = max(math.ceil(abs(sweep) / step), 1)
        for k in range(steps + 1):
            angle = start + sweep * k / steps
            point = (cx + math.cos(angle) * distance, cy + math.sin(angle) * distance)
            if not expanded or math.hypot(point[0] - expanded[-1][0], point[1] - expanded[-1][1]) > eps:
                expanded.append(point)
    return expanded if len(expanded) >= 3 else points


def _box_score_fast(prob: np.ndarray, points) -> float:
    h, w = prob.shape
    xmin = min(max(min(math.floor(p[0]) for p in points), 0), w - 1)
    xmax = min(max(max(math.ceil(p[0]) for p in points), 0), w - 1)
    ymin = min(max(min(math.floor(p[1]) for p in points), 0), h - 1)
    ymax = min(max(max(math.ceil(p[1]) for p in points), 0), h - 1)
    mask = np.zeros((ymax - ymin + 1, xmax - xmin + 1), dtype=np.uint8)
    # Kotlin truncates (toInt) the shifted coordinates before fillPoly.
    poly = np.array([[int(p[0] - xmin), int(p[1] - ymin)] for p in points], dtype=np.int32)
    cv2.fillPoly(mask, [poly], 1)
    return float(cv2.mean(prob[ymin : ymax + 1, xmin : xmax + 1], mask)[0])


def db_postprocess(pred: np.ndarray, original_h: int, original_w: int) -> list[list[tuple[float, float]]]:
    prob = pred[0, 0].astype(np.float32)
    p_h, p_w = prob.shape
    scale_x, scale_y = original_w / p_w, original_h / p_h
    _, binary = cv2.threshold(prob, DET_THRESH, 255.0, cv2.THRESH_BINARY)
    mask = binary.astype(np.uint8)
    contours, _ = cv2.findContours(mask, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    boxes = []
    for contour in contours[:DET_MAX_CANDIDATES]:
        rect = cv2.minAreaRect(contour.astype(np.float32))
        if min(rect[1]) < 3:
            continue
        ordered = order_min_area_rect_points([tuple(p) for p in cv2.boxPoints(rect)])
        if _box_score_fast(prob, ordered) < DET_BOX_THRESH:
            continue
        expanded = unclip(ordered, DET_UNCLIP_RATIO)
        expanded_rect = cv2.minAreaRect(np.array(expanded, dtype=np.float32))
        if min(expanded_rect[1]) < 5:
            continue
        e_points = order_min_area_rect_points([tuple(p) for p in cv2.boxPoints(expanded_rect)])
        scaled = [
            (
                float(min(max(round_half_to_even(x * scale_x), 0), original_w)),
                float(min(max(round_half_to_even(y * scale_y), 0), original_h)),
            )
            for x, y in e_points
        ]
        box_w = math.hypot(scaled[1][0] - scaled[0][0], scaled[1][1] - scaled[0][1])
        box_h = math.hypot(scaled[3][0] - scaled[0][0], scaled[3][1] - scaled[0][1])
        if box_w <= 3 or box_h <= 3:
            continue
        boxes.append(scaled)
    return boxes


def sort_in_reading_order(boxes):
    # BoxSorter.sortInReadingOrder
    items = sorted(boxes, key=lambda b: (b[0][1], b[0][0]))
    for i in range(len(items) - 1):
        j = i
        while j >= 0:
            if abs(items[j + 1][0][1] - items[j][0][1]) < 10 and items[j + 1][0][0] < items[j][0][0]:
                items[j], items[j + 1] = items[j + 1], items[j]
                j -= 1
            else:
                break
    return items


def crop_quad(bgr: np.ndarray, box) -> np.ndarray:
    # QuadTextCrop.crop
    rect = cv2.minAreaRect(np.array(box, dtype=np.float32))
    ordered = order_min_area_rect_points([tuple(p) for p in cv2.boxPoints(rect)])
    width = max(math.dist(ordered[0], ordered[1]), math.dist(ordered[2], ordered[3]))
    height = max(math.dist(ordered[0], ordered[3]), math.dist(ordered[1], ordered[2]))
    dst_w, dst_h = max(int(width), 1), max(int(height), 1)
    matrix = cv2.getPerspectiveTransform(
        np.array(ordered, dtype=np.float32),
        np.array([[0, 0], [dst_w, 0], [dst_w, dst_h], [0, dst_h]], dtype=np.float32),
    )
    dst = cv2.warpPerspective(
        bgr, matrix, (dst_w, dst_h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
    )
    if dst.shape[0] / dst.shape[1] >= 1.5:
        dst = cv2.rotate(dst, cv2.ROTATE_90_COUNTERCLOCKWISE)
    return dst


# ------------------------------------------------------------- recognition


def rec_preprocess(crop_bgr: np.ndarray) -> np.ndarray:
    rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
    h, w = rgb.shape[:2]
    ratio = w / h if h > 0 else 1.0
    new_w = min(math.ceil(REC_HEIGHT * ratio), REC_MAX_WIDTH)
    resized = cv2.resize(rgb, (new_w, REC_HEIGHT), interpolation=cv2.INTER_LINEAR)
    tensor = resized.astype(np.float32) / 127.5 - 1.0
    return np.transpose(tensor, (2, 0, 1))[None].astype(np.float32)


def ctc_decode(output: np.ndarray, characters: list[str]) -> tuple[str, float]:
    steps = output[0]
    indices = steps.argmax(axis=1)
    probs = steps.max(axis=1)
    text, kept, previous = [], [], -1
    for index, prob in zip(indices, probs):
        index = int(index)
        if index != 0 and index != previous and 0 <= index - 1 < len(characters):
            text.append(characters[index - 1])
            kept.append(float(prob))
        previous = index
    return "".join(text), (float(np.mean(kept)) if kept else 0.0)


@dataclass
class LineResult:
    box: list[tuple[float, float]]
    text: str
    confidence: float


class AppOcr:
    def __init__(self, det_model: Path = DET_MODEL, rec_model: Path = REC_MODEL, rec_config: Path = REC_CONFIG, threads: int = 4):
        options = ort.SessionOptions()
        options.intra_op_num_threads = threads
        providers = ["CPUExecutionProvider"]
        self.det = ort.InferenceSession(str(det_model), options, providers=providers)
        self.rec = ort.InferenceSession(str(rec_model), options, providers=providers)
        self.characters = load_character_list(rec_config)

    def detect(self, bgr: np.ndarray):
        pred = self.det.run(None, {self.det.get_inputs()[0].name: det_preprocess(bgr)})[0]
        return sort_in_reading_order(db_postprocess(pred, bgr.shape[0], bgr.shape[1]))

    def recognize_line(self, crop_bgr: np.ndarray) -> tuple[str, float]:
        output = self.rec.run(None, {self.rec.get_inputs()[0].name: rec_preprocess(crop_bgr)})[0]
        return ctc_decode(output, self.characters)

    def read_page(self, bgr: np.ndarray) -> list[LineResult]:
        results = []
        for box in self.detect(bgr):
            crop = crop_quad(bgr, box)
            if crop.size == 0:
                continue
            text, confidence = self.recognize_line(crop)
            results.append(LineResult(box, text, confidence))
        return results


def read_image(path: Path) -> np.ndarray:
    data = np.fromfile(str(path), dtype=np.uint8)
    image = cv2.imdecode(data, cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"Cannot read image {path}")
    return image


def write_image(path: Path, image: np.ndarray, jpeg_quality: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    suffix = path.suffix.lower()
    params = [cv2.IMWRITE_JPEG_QUALITY, jpeg_quality] if jpeg_quality and suffix in (".jpg", ".jpeg") else []
    ok, encoded = cv2.imencode(suffix, image, params)
    if not ok:
        raise ValueError(f"Cannot encode {path}")
    encoded.tofile(str(path))
