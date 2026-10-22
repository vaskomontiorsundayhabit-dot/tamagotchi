import sys, runpy, json
S = sys.argv[1]
sys.argv = ['gen0.py', S]
g = runpy.run_path(S + '/gen0.py')
K = g['K']; IM = json.load(open(S + '/img0.json')); EMO = g['EMO']
CATS = g['CATS']
base = {i[1]: c[0] for c in CATS for i in c[2]}
par = {}
def add(r, how, ins):
    par.setdefault(r, [])
    if [how, ins] not in par[r]: par[r].append([how, ins])
for n, v in g['AP'].items():
    for p, _ in v: add(p, "apart", [n])
for T, how in ((g['HT'], "heat"), (g['CL'], "cool")):
    for n, v in T.items():
        if isinstance(v, list):
            for p, _ in v:
                if p != n: add(p, how, [n])
for n, v in g['TM'].items():
    if not isinstance(v, str):
        for p, _ in v[1]: add(p, "time", [n])
for n, v in g['D2'].items():
    for i, how in enumerate(("heat", "cool", "time")):
        x = v[i]
        if isinstance(x, list):
            for p, _ in x: add(p, how, [n])
        elif isinstance(x, tuple):
            for p, _ in x[1]: add(p, how, [n])
for n, a2, a3 in g['SAME']:
    for x, k in ((a2, 2), (a3, 3)):
        if x and not (isinstance(x, str) and x.startswith("смешно")):
            add(x[0] if isinstance(x, tuple) else x, "mix", [n] * k)
for n, ap, h, c_, t in g['D3']:
    if isinstance(h, tuple): add(h[0], "heat", [n])
    if isinstance(t, tuple) and len(t) == 3: add(t[1], "time", [n])
for ins, r, _ in g['HT2']: add(r, "heat", ins)
for ins, r, _ in g['CL2']: add(r, "cool", ins)
for m, ins, r, _ in g['FOOD']: add(r, {"⚗️": "mix", "🔥": "heat", "❄️": "cool"}[m], ins)
for _, rows in g['MIX'] + g['MIXX']:
    for a, b, r, em, w in rows: add(r, "mix", [a, b])
for a, b, r, em, w in g['MIX2'] + g['MIX3L']: add(r, "mix", [a, b])
for ins, r, em, w in g['MIX3'] + g['M34']: add(r, "mix", ins)
add("Къщичка за рачетата Крил", "mix", ["Кирпич"] * 3); EMO["Къщичка за рачетата Крил"] = "🏠"
for _a, _b, r, em, _w in g["MIX3L"]: EMO[r] = em
names = set(base) | set(par) | {x for rs in par.values() for r in rs for x in r[1]}
# depth
INF = 99
dep = {k: (0 if k in base else INF) for k in names}
changed = True
while changed:
    changed = False
    for k in names:
        if k in base or k not in par: continue
        best = min(1 + max(dep[x] for x in r[1]) for r in par[k])
        if best < dep[k]: dep[k] = best; changed = True
def depth(k): return dep.get(k, INF)
D = {}
ids = {}
for i, n in enumerate(sorted(names)): ids[n] = K.get(n) or f"x{i}"
for n in names:
    d = 0 if n in base else dep.get(n, 99)
    rs = [] if n in base else sorted(par.get(n, []), key=lambda r: max(depth(x) for x in r[1]))
    D[ids[n]] = {"n": n, "d": d, "p": [[r[0], [ids[x] for x in r[1]]] for r in rs], "base": n in base, "cat": base.get(n, ""),
                 "em": "" if (K.get(n) in IM) else (EMO.get(n) or "❔")}
kids = {}
for k, v in D.items():
    for r in v["p"]:
        for x in set(r[1]): kids.setdefault(x, set()).add(k)
for k in D: D[k]["c"] = sorted(kids.get(k, []), key=lambda x: (D[x]["d"], D[x]["n"]))
css = ''.join(f'.i-{ids[n]}{{background-image:url({IM[K[n]]})}}' for n in names if K.get(n) in IM)
tpl = open(S + '/tree2_tpl.html').read()
open(S + '/art/rodoslovie-2.html', 'w').write(tpl.replace('{{CSS}}', css).replace('{{DATA}}', json.dumps(D, ensure_ascii=False)))
from collections import Counter
print(len(D), Counter(v["d"] for v in D.values()))
print("deepest:", sorted([(v["d"], v["n"]) for v in D.values()])[-6:])
