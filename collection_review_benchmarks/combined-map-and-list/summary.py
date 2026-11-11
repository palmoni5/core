"""Print per-run medians from paired baseline and candidate timing data."""

import argparse
from collections import defaultdict
import csv
from pathlib import Path
from statistics import median


def summarize(path):
    cases = defaultdict(list)
    with path.open(newline="", encoding="utf-8-sig") as stream:
        for row in csv.DictReader(stream):
            baseline = float(row["baseline_ns"])
            changed = float(row["changed_ns"])
            cases[row["case"]].append((baseline, changed))

    print(f"\n{path.name}")
    print(f"{'case':30s} {'pairs':>5s} {'baseline ns':>12s} {'changed ns':>12s} {'median ratio':>12s}")
    for case, pairs in sorted(cases.items()):
        base = median(a for a, _ in pairs)
        changed = median(b for _, b in pairs)
        ratio = median(b / a for a, b in pairs)
        print(f"{case:30s} {len(pairs):5d} {base:12.2f} {changed:12.2f} {ratio:12.3f}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path)
    args = parser.parse_args()
    for path in args.files or sorted(Path(__file__).with_name("raw").glob("*.csv")):
        summarize(path)


if __name__ == "__main__":
    main()
