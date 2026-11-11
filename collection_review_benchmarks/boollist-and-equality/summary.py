
import argparse
import csv
from collections import defaultdict
from pathlib import Path
from statistics import median


def summarize(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        lines = list(handle)
    if not lines[-1].startswith("# checksum "):
        raise ValueError(f"Missing checksum in {path}")
    cases = defaultdict(list)
    for row in csv.DictReader(lines[:-1]):
        cases[row["case"]].append((float(row["before_ns"]), float(row["after_ns"])))
    if len(cases) != 15 or any(len(pairs) != 7 for pairs in cases.values()):
        raise ValueError(f"Unexpected number of measurements in {path}")
    print(f"\n{path.name}")
    print(f"{'case':23} {'before ns':>13} {'after ns':>13} {'after/before':>14} {'faster pairs':>13}")
    for name, pairs in sorted(cases.items()):
        before, after = map(median, zip(*pairs))
        paired_ratio = median(b / a for a, b in pairs)
        faster = sum(b < a for a, b in pairs)
        print(f"{name:23} {before:13.2f} {after:13.2f} {paired_ratio:14.6f} {faster:11}/{len(pairs)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("raw_directory", type=Path, nargs="?", default=Path(__file__).parent / "raw")
    args = parser.parse_args()
    for csv_path in sorted(args.raw_directory.glob("*.csv")):
        summarize(csv_path)
