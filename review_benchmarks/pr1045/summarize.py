import csv,statistics,collections,sys
from pathlib import Path
p=Path(__file__).parent
rows=list(csv.DictReader((p/(sys.argv[1] if len(sys.argv)>1 else 'core-pr1045-results.csv')).open()))
groups=collections.defaultdict(dict)
for r in rows: groups[(r['language'],r['size'],r['mode'])][(r['round'],r['variant'])]=r
out=[]
for key,g in groups.items():
    d=dict(zip(['language','size','mode'],key))
    d['baseline_clusters_s']=round(statistics.median(float(g[(str(i),'baseline')]['clusters_per_second']) for i in range(7)))
    for v in ['original','generic']:
        ratios=[float(g[(str(i),'baseline')]['elapsed_us'])/float(g[(str(i),v)]['elapsed_us']) for i in range(7)]
        d[v+'_median_speedup']=round(statistics.median(ratios),4)
        d[v+'_min_speedup']=round(min(ratios),4)
        d[v+'_max_speedup']=round(max(ratios),4)
        d[v+'_wins']=sum(x>1 for x in ratios)
    out.append(d)
with (p/(sys.argv[2] if len(sys.argv)>2 else 'core-pr1045-summary.csv')).open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(out[0]));w.writeheader();w.writerows(out)
for r in out:print(r)
print('ROWS',len(rows))
