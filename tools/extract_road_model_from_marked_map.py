from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt
from skimage.measure import label
from skimage.morphology import closing, disk, skeletonize


ROOT = Path(__file__).resolve().parents[1]
BASE_MAP = ROOT / "MapForUI.jpg"
OUT_DIR = ROOT / "docs" / "road_rework"
GREEN_MARKED_MAP = OUT_DIR / "MapForUI-road-width-green.jpg"
MARKED_MAP = GREEN_MARKED_MAP if GREEN_MARKED_MAP.exists() else next(ROOT.glob("MapForUI-*.jpg"))
OUT_M = ROOT / "RoadModelDataPx.m"
OUT_MASK = OUT_DIR / "extracted_road_mask.png"
OUT_SKELETON = OUT_DIR / "extracted_road_skeleton.png"
OUT_VECTOR = OUT_DIR / "extracted_road_vector.png"
OUT_CORRIDOR = OUT_DIR / "extracted_road_corridor.png"

SIMPLIFY_EPS_PX = 1.8
MIN_COMPONENT_PIXELS = 20
MIN_POLYLINE_LENGTH_PX = 8
MIN_ROAD_WIDTH_PX = 7
MAX_ROAD_WIDTH_PX = 46


def remove_small_components(mask, min_pixels):
    labeled = label(mask, connectivity=2)
    keep = np.zeros_like(mask, dtype=bool)
    for component_id in range(1, labeled.max() + 1):
        component = labeled == component_id
        if component.sum() >= min_pixels:
            keep |= component
    return keep


def green_marker_mask(base_img, marked_img):
    base = np.asarray(base_img.convert("RGB")).astype(np.int16)
    marked = np.asarray(marked_img.convert("RGB")).astype(np.int16)
    diff = marked - base
    r = marked[:, :, 0]
    g = marked[:, :, 1]
    b = marked[:, :, 2]
    changed = np.abs(diff).sum(axis=2) > 28
    saturated_green = (g > 145) & ((g - r) > 45) & ((g - b) > 40)
    compressed_green = (g > 190) & ((g - r) > 30) & ((g - b) > 28)
    mask = (saturated_green | compressed_green) & (changed | (g > 220))

    padded = np.pad(mask, 1, mode="constant")
    count = np.zeros_like(mask, dtype=np.int16)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            count += padded[1 + dy : 1 + dy + mask.shape[0], 1 + dx : 1 + dx + mask.shape[1]]
    mask = mask & (count >= 2)
    mask = closing(mask, disk(2))
    mask = remove_small_components(mask, 40)
    return mask


def red_marker_mask(base_img, marked_img):
    base = np.asarray(base_img.convert("RGB")).astype(np.int16)
    marked = np.asarray(marked_img.convert("RGB")).astype(np.int16)
    diff = marked - base
    r = marked[:, :, 0]
    g = marked[:, :, 1]
    b = marked[:, :, 2]
    changed = np.abs(diff).sum(axis=2) > 35
    red_added = (diff[:, :, 0] > 20) & (diff[:, :, 1] < 15)
    mask = (r > 120) & ((r - g) > 25) & ((r - b) > 20) & (changed | red_added)

    padded = np.pad(mask, 1, mode="constant")
    count = np.zeros_like(mask, dtype=np.int16)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            count += padded[1 + dy : 1 + dy + mask.shape[0], 1 + dx : 1 + dx + mask.shape[1]]
    mask = mask & (count >= 2)
    mask = closing(mask, disk(1))
    mask = remove_small_components(mask, 10)
    return mask


def marker_mask(base_img, marked_img):
    green = green_marker_mask(base_img, marked_img)
    if int(green.sum()) > 1000:
        return green, "green_width"
    return red_marker_mask(base_img, marked_img), "red_centerline"


def keep_large_skeleton_components(skeleton):
    labeled = label(skeleton, connectivity=2)
    keep = np.zeros_like(skeleton, dtype=bool)
    for component_id in range(1, labeled.max() + 1):
        component = labeled == component_id
        if component.sum() >= MIN_COMPONENT_PIXELS:
            keep |= component
    return keep


def neighbors(point, point_set):
    y, x = point
    result = []
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            candidate = (y + dy, x + dx)
            if candidate in point_set:
                result.append(candidate)
    return result


def edge_key(a, b):
    return (a, b) if a <= b else (b, a)


def trace_skeleton_paths(skeleton):
    point_set = set(map(tuple, np.argwhere(skeleton)))
    neighbor_map = {point: neighbors(point, point_set) for point in point_set}
    degree = {point: len(neighbor_map[point]) for point in point_set}
    critical = {point for point, value in degree.items() if value != 2}
    visited = set()
    paths = []

    def seen(a, b):
        return edge_key(a, b) in visited

    def mark(a, b):
        visited.add(edge_key(a, b))

    for start in list(critical):
        for nb in neighbor_map[start]:
            if seen(start, nb):
                continue
            path = [start, nb]
            mark(start, nb)
            prev = start
            current = nb
            while current not in critical:
                candidates = [point for point in neighbor_map[current] if point != prev]
                if not candidates:
                    break
                nxt = None
                for point in candidates:
                    if not seen(current, point):
                        nxt = point
                        break
                if nxt is None:
                    break
                path.append(nxt)
                mark(current, nxt)
                prev = current
                current = nxt
            paths.append(path)

    for start in list(point_set):
        for nb in neighbor_map[start]:
            if seen(start, nb):
                continue
            path = [start, nb]
            mark(start, nb)
            prev = start
            current = nb
            while current != start:
                candidates = [point for point in neighbor_map[current] if point != prev]
                if not candidates:
                    break
                nxt = None
                for point in candidates:
                    if not seen(current, point):
                        nxt = point
                        break
                if nxt is None:
                    break
                path.append(nxt)
                mark(current, nxt)
                prev = current
                current = nxt
            paths.append(path)
    return paths


def distance(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def point_line_distance(point, a, b):
    ax, ay = a
    bx, by = b
    px, py = point
    dx = bx - ax
    dy = by - ay
    den = dx * dx + dy * dy
    if den == 0:
        return distance(point, a)
    t = ((px - ax) * dx + (py - ay) * dy) / den
    if t < 0:
        q = a
    elif t > 1:
        q = b
    else:
        q = (ax + t * dx, ay + t * dy)
    return distance(point, q)


def rdp(points, epsilon):
    if len(points) <= 2:
        return points
    a = points[0]
    b = points[-1]
    max_distance = -1
    index = -1
    for i in range(1, len(points) - 1):
        value = point_line_distance(points[i], a, b)
        if value > max_distance:
            max_distance = value
            index = i
    if max_distance > epsilon:
        left = rdp(points[: index + 1], epsilon)
        right = rdp(points[index:], epsilon)
        return left[:-1] + right
    return [a, b]


def path_length(points):
    total = 0
    for i in range(1, len(points)):
        total += distance(points[i - 1], points[i])
    return total


def estimate_segment_width(radius_map, p1, p2):
    samples = max(3, int(distance(p1, p2) / 2))
    radii = []
    height, width = radius_map.shape
    for i in range(samples):
        t = 0 if samples == 1 else i / (samples - 1)
        x = p1[0] + (p2[0] - p1[0]) * t
        y = p1[1] + (p2[1] - p1[1]) * t
        col = int(round(x))
        row = int(round(y))
        if 0 <= row < height and 0 <= col < width:
            value = radius_map[row, col]
            if value > 0:
                radii.append(float(value))
    if not radii:
        return MIN_ROAD_WIDTH_PX
    width_px = 2 * float(np.percentile(radii, 60)) + 1.5
    width_px = max(MIN_ROAD_WIDTH_PX, min(MAX_ROAD_WIDTH_PX, width_px))
    return round(width_px, 1)


def vectorize_skeleton(skeleton, radius_map):
    road_segments = []
    raw_polylines = 0
    for path in trace_skeleton_paths(skeleton):
        points = [(float(x), float(y)) for y, x in path]
        cleaned = []
        for point in points:
            if not cleaned or distance(cleaned[-1], point) > 0.1:
                cleaned.append(point)
        if len(cleaned) < 2 or path_length(cleaned) < MIN_POLYLINE_LENGTH_PX:
            continue
        simplified = rdp(cleaned, SIMPLIFY_EPS_PX)
        if len(simplified) < 2 or path_length(simplified) < MIN_POLYLINE_LENGTH_PX:
            continue
        raw_polylines += 1
        for i in range(1, len(simplified)):
            p1 = simplified[i - 1]
            p2 = simplified[i]
            if distance(p1, p2) < MIN_POLYLINE_LENGTH_PX:
                continue
            road_segments.append((p1, p2, estimate_segment_width(radius_map, p1, p2)))
    road_segments.sort(
        key=lambda item: (
            round(min(item[0][1], item[1][1]) / 10),
            round(min(item[0][0], item[1][0]) / 10),
            -distance(item[0], item[1]),
        )
    )
    return road_segments, raw_polylines


def format_number(value):
    return f"{value:.1f}".rstrip("0").rstrip(".")


def write_matlab_data(road_segments, marker_mode):
    with OUT_M.open("w", encoding="ascii", newline="\n") as handle:
        handle.write("function segPx = RoadModelDataPx()\n")
        handle.write("%ROADMODELDATAPX Road corridor model extracted from the marked map.\n")
        handle.write("% Each row is [x1 y1 x2 y2 widthPx] in image pixel coordinates.\n")
        handle.write(f"% Generated offline from a {marker_mode} marker map; runtime uses only this MATLAB data.\n")
        handle.write("segPx = [];\n")
        for idx, (p1, p2, width_px) in enumerate(road_segments, 1):
            xs = f"{format_number(p1[0])} {format_number(p2[0])}"
            ys = f"{format_number(p1[1])} {format_number(p2[1])}"
            handle.write(
                f"segPx = appendRoadPolyline(segPx, [{xs}], [{ys}], {format_number(width_px)}); "
                f"% extracted_{idx:03d}\n"
            )
        handle.write("end\n\n")
        handle.write("function segPx = appendRoadPolyline(segPx, xs, ys, widthPx)\n")
        handle.write("for k = 1:(length(xs) - 1)\n")
        handle.write("    segPx(end + 1, :) = [xs(k) ys(k) xs(k + 1) ys(k + 1) widthPx];\n")
        handle.write("end\n")
        handle.write("end\n")


def write_review_images(base_img, mask, skeleton, road_segments):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    mask_img = Image.new("RGB", (mask.shape[1], mask.shape[0]), "white")
    mask_arr = np.array(mask_img)
    mask_arr[mask] = [0, 255, 0]
    Image.fromarray(mask_arr).save(OUT_MASK)

    skeleton_layer = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    skeleton_arr = np.array(skeleton_layer)
    skeleton_arr[skeleton] = [0, 90, 255, 230]
    Image.alpha_composite(base_img.convert("RGBA"), Image.fromarray(skeleton_arr)).convert("RGB").save(OUT_SKELETON)

    vector_layer = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(vector_layer)
    for p1, p2, _ in road_segments:
        draw.line([p1, p2], fill=(0, 80, 255, 230), width=2)
    Image.alpha_composite(base_img.convert("RGBA"), vector_layer).convert("RGB").save(OUT_VECTOR)

    corridor_layer = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    corridor_draw = ImageDraw.Draw(corridor_layer)
    for p1, p2, width_px in road_segments:
        corridor_draw.line([p1, p2], fill=(0, 100, 255, 160), width=max(1, int(round(width_px))))
    Image.alpha_composite(base_img.convert("RGBA"), corridor_layer).convert("RGB").save(OUT_CORRIDOR)


def main():
    base_img = Image.open(BASE_MAP)
    marked_img = Image.open(MARKED_MAP)
    mask, marker_mode = marker_mask(base_img, marked_img)
    radius_map = distance_transform_edt(mask)
    skeleton = keep_large_skeleton_components(skeletonize(mask))
    road_segments, polylines = vectorize_skeleton(skeleton, radius_map)
    write_matlab_data(road_segments, marker_mode)
    write_review_images(base_img, mask, skeleton, road_segments)
    widths = [item[2] for item in road_segments]
    print(f"marked_map={MARKED_MAP.name}")
    print(f"marker_mode={marker_mode}")
    print(f"mask_pixels={int(mask.sum())}")
    print(f"skeleton_pixels={int(skeleton.sum())}")
    print(f"polylines={polylines}")
    print(f"segments={len(road_segments)}")
    if widths:
        print(f"width_px_min={min(widths):.1f}")
        print(f"width_px_median={float(np.median(widths)):.1f}")
        print(f"width_px_max={max(widths):.1f}")
    print(f"out={OUT_M}")


if __name__ == "__main__":
    main()
