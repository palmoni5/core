import csv
import glob
import json
import random
import statistics
from collections import defaultdict
from pathlib import Path

root = Path(__file__).parent
groups = defaultdict(list)
for path in sorted(root.glob('samples-*.csv')):
    for row in csv.DictReader(path.open(encoding='utf-8')):
        groups[row['case'], row['mode']].append(row)

rng = random.Random(1042)
with (root / 'summary.csv').open('w', newline='', encoding='utf-8') as output:
    writer = csv.writer(output)
    writer.writerow(['case', 'mode', 'samples', 'median_baseline_ns_op',
                     'median_proposal_ns_op', 'median_p_over_b',
                     'paired_bootstrap_low95', 'paired_bootstrap_high95',
                     'min_process_median_ratio', 'max_process_median_ratio'])
    for (case, mode), rows in groups.items():
        ratios = [int(r['proposal_us']) / int(r['baseline_us']) for r in rows]
        boot = sorted(statistics.median(rng.choices(ratios, k=len(ratios)))
                      for _ in range(5000))
        per_process = defaultdict(list)
        for row, ratio in zip(rows, ratios):
            per_process[row['seed']].append(ratio)
        medians = [statistics.median(x) for x in per_process.values()]
        fields = [case, mode, len(rows),
                  statistics.median(int(r['baseline_us'])*1000/int(r['iterations']) for r in rows),
                  statistics.median(int(r['proposal_us'])*1000/int(r['iterations']) for r in rows),
                  statistics.median(ratios), boot[124], boot[4874], min(medians), max(medians)]
        writer.writerow(fields)
        print(case, mode, 'P/B=', round(fields[5], 3), 'process range=',
              round(min(medians), 3), round(max(medians), 3))
