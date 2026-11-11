"""Report median within-round candidate/baseline ratios from raw observations."""

import csv
import sys
from collections import defaultdict
from pathlib import Path
from statistics import median


def summarize(path):
    rounds = defaultdict(dict)
    with path.open(newline="", encoding="utf-8") as file:
        for row in csv.DictReader(file):
            key = (
                row["benchmark"], row["scenario"],
                int(row["count"]), int(row["round"]),
            )
            rounds[key][row["variant"]] = float(row["ns_per_op"])
    observations = defaultdict(list)
    for (benchmark, scenario, count, _), variants in rounds.items():
        baseline = variants["baseline"]
        for variant, ns in variants.items():
            if variant != "baseline":
                observations[benchmark, scenario, count, variant].append(
                    (baseline, ns, ns / baseline)
                )
    for key, rows in observations.items():
        print(path.name, *key, *(f"{median(col):.4f}" for col in zip(*rows)), sep=",")


if __name__ == "__main__":
    print("run,benchmark,scenario,count,variant,baseline_ns,variant_ns,ratio")
    for argument in sys.argv[1:]:
        summarize(Path(argument))
