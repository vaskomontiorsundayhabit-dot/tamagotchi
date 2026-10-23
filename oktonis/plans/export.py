import sys, runpy, json, re
S = sys.argv[1]
sys.argv = ['gen0.py', S]
g = runpy.run_path(S + '/gen0.py')
K = g['K']; EMO = g['EMO']
for lst in ('MIX2', 'MIX3L'):
    for a, b, r, em, w in g[lst]: EMO.setdefault(r, em)
for ins, r, em, w in g['MIX3'] + g['M34']: EMO.setdefault(r, em)
EMO["Къщичка за рачетата Крил"] = "🏠"
def mins(t):
    t = t.strip(); m = re.match(r'(\d+)\s*(минут|час|ден|дни)', t)
    if not m: return None
    n = int(m.group(1)); u = m.group(2)
    return n * (1 if u.startswith('минут') else 60 if u.startswith('час') else 1440)
ID = lambda n: K[n]
items = {}; living = set(); junk = set(); rar = {}
CATS = g['CATS']
for cat, sub, lst in CATS:
    for em, n, desc, tags, r, note, old in lst:
        k = ID(n); rar[k] = r
        kind = "junk" if cat.startswith("Съвременен") else "living" if cat.startswith("Живите") else "food" if cat.startswith("Провизии") else "part" if cat.startswith("От разбитите") else "nature"
        if kind == "living": living.add(k)
        if kind == "junk": junk.add(k)
        price = {"о": 2, "р": 6, "м": 18}[r]
        items[k] = [em, n, 0, kind, price, desc]
REC2, RECN = [], []
def addrec(ins, r):
    ids = [ID(x) for x in ins]
    if len(ids) == 2: REC2.append([ids[0], ids[1], ID(r)])
    else: RECN.append([ids, ID(r)])
for n, a2, a3 in g['SAME']:
    for x, c in ((a2, 2), (a3, 3)):
        if x and not (isinstance(x, str) and x.startswith("смешно")): addrec([n] * c, x[0] if isinstance(x, tuple) else x)
for m, ins, r, w in g['FOOD']:
    if m == "⚗️": addrec(ins, r)
for _, rows in g['MIX'] + g['MIXX']:
    for a, b, r, em, w in rows: addrec([a, b], r)
for a, b, r, em, w in g['MIX2'] + g['MIX3L']: addrec([a, b], r)
for ins, r, em, w in g['MIX3'] + g['M34']: addrec(ins, r)
addrec(["Кирпич"] * 3, "Къщичка за рачетата Крил")
# dedupe REC2 by pair key (first wins)
seen = set(); R2 = []
for a, b, c in REC2:
    kk = "+".join(sorted([a, b]))
    if kk in seen: continue
    seen.add(kk); R2.append([a, b, c])
HEAT, COOL = {}, {}
def outl(v): return [[ID(p), 1] for p, _ in v]
for n, v in g['HT'].items():
    if isinstance(v, list): HEAT[ID(n)] = outl(v)
    elif "гръмва" in v or "изпуква" in v: HEAT[ID(n)] = "!boom"
for n, v in g['CL'].items():
    if isinstance(v, list): COOL[ID(n)] = outl(v)
for ins, r, _ in g['HT2']: HEAT["+".join(sorted(ID(x) for x in ins))] = [[ID(r), 1]]
for ins, r, _ in g['CL2']: COOL["+".join(sorted(ID(x) for x in ins))] = [[ID(r), 1]]
for m, ins, r, w in g['FOOD']:
    kk = "+".join(sorted(ID(x) for x in ins))
    if m == "🔥": HEAT[kk] = [[ID(r), 1]]
    if m == "❄️": COOL[kk] = [[ID(r), 1]]
for n, v in g['D2'].items():
    for i, T in ((0, HEAT), (1, COOL)):
        if isinstance(v[i], list): T[ID(n)] = outl(v[i])
for n, ap, h, c_, t in g['D3']:
    if isinstance(h, tuple): HEAT[ID(n)] = [[ID(h[0]), 1]]
    elif isinstance(h, str) and "изпуква" in h: HEAT[ID(n)] = "!boom"
for n, v in g['HTX'].items():
    if isinstance(v, list): HEAT[ID(n)] = outl(v)
for n, v in g['CLX'].items():
    if isinstance(v, list): COOL[ID(n)] = outl(v)
APART = {}
def cntnote(note):
    m = re.match(r'×(\d+)', note or ""); return int(m.group(1)) if m else 1
for n, v in g['AP'].items(): APART[ID(n)] = [[ID(p), cntnote(note)] for p, note in v]
for n, a2, a3 in g['SAME']:
    for x, c in ((a2, 2), (a3, 3)):
        if x and not (isinstance(x, str) and x.startswith("смешно")): APART.setdefault(ID(x[0] if isinstance(x, tuple) else x), [[ID(n), c]])
for n, ap, h, c_, t in g['D3']:
    if isinstance(ap, tuple): APART[ID(n)] = [[ID(ap[0]), cntnote(ap[1])]]
NOAPART = []
food = g['_food']
for r, ins in g['_rec'].items():
    v = g['APX'].get(r)
    if r in g['APX']:
        if isinstance(v, list): APART[ID(r)] = [[ID(p), cntnote(note)] for p, note in v]
        else: NOAPART.append(ID(r))
    elif r in food: NOAPART.append(ID(r))
    else:
        cc = {}
        for x in ins: cc[x] = cc.get(x, 0) + 1
        APART.setdefault(ID(r), [[ID(x), c] for x, c in cc.items()])
for m, ins, r, w in g['FOOD']: NOAPART.append(ID(r))
TIME = {}
def tset(n, t, out):
    mm = mins(t)
    if mm: TIME[ID(n)] = [mm, out]
for n, v in g['TM'].items():
    if isinstance(v, str):
        if any(w in v for w in ("отплава", "обратно")): tset(n, v, "!escape")
    else: tset(n, v[0], ID(v[1][0][0]))
for n, v in g['D2'].items():
    x = v[2]
    if isinstance(x, tuple): tset(n, x[0], ID(x[1][0][0]))
for n, ap, h, c_, t in g['D3']:
    if isinstance(t, tuple) and len(t) == 3: tset(n, t[0], ID(t[1]))
for n, v in g['TMX'].items():
    if isinstance(v, tuple): tset(n, v[0], ID(v[1]))
    elif isinstance(v, str):
        mm = mins(v.replace("за ", "")) if mins(v.replace("за ", "")) else None
        if not mm: continue
        if any(w in v for w in ("вмирисва",)): TIME[ID(n)] = [mm, "stinkyfish"]
        elif any(w in v for w in ("разваля", "вкисва")): TIME[ID(n)] = [mm, "compost"]
        elif "компост" in v: TIME[ID(n)] = [mm, "compost"]
        elif "хартиена каша" in v: TIME[ID(n)] = [mm, "papermush"]
        elif "тиня" in v: TIME[ID(n)] = [mm, "silt"]
TIME["jarlantern"] = [4320, "jar"]; TIME["cocolamp"] = [4320, "cocoshell"]; TIME["litlantern"] = [4320, "lantern"]
EDIBLE = {"weed": 15, "kelp": 15, "kelpchips": 20, "cannedfish": 30, "cocomilk": 15, "hardtack": 20, "honey": 15, "lemon": 8, "sorbet": 15, "lemonade": 10, "honeytea": 10, "icedtea": 10,
 "cocoicecream": 20, "dryweed": 12, "sushi": 35, "soup": 45, "sailorsandwich": 40, "honeyhardtack": 30, "cocoshake": 25, "cocoporridge": 40, "cocopudding": 30, "seasalad": 30,
 "lemonfish": 40, "saltfish": 35, "honeyspoon": 10, "saltweed": 15, "seaplatter": 60, "festplatter": 60, "coconut": 0}
del EDIBLE["coconut"]
YUCK = ["stinkyfish", "moldlemon"]
# derived items
allr = set(c for a, b, c in R2) | set(c for i, c in RECN) | {o[0] for v in list(HEAT.values()) + list(COOL.values()) if isinstance(v, list) for o in v} | {o[0] for v in APART.values() for o in v} | {v[1] for v in TIME.values() if v[1][0] != "!"}
name_of = {v: k for k, v in K.items()}
dep = {k: 0 for k in items}
parents = {}
for a, b, c in R2: parents.setdefault(c, []).append([a, b])
for i, c in RECN: parents.setdefault(c, []).append(i)
for src, T in (("h", HEAT), ("c", COOL)):
    for kk, v in T.items():
        if isinstance(v, list):
            for o in v: parents.setdefault(o[0], []).append(kk.split("+"))
for kk, v in APART.items():
    for o in v: parents.setdefault(o[0], []).append([kk])
for kk, v in TIME.items():
    if v[1][0] != "!": parents.setdefault(v[1], []).append([kk])
ch = True
while ch:
    ch = False
    for c, ps in parents.items():
        if c in items and items[c][3] != "made": continue
        best = min((1 + max(dep.get(x, 99) for x in p) for p in ps), default=99)
        if best < dep.get(c, 99): dep[c] = best; ch = True
price = {k: v[4] for k, v in items.items()}
ch = True
while ch:
    ch = False
    for c, ps in parents.items():
        if c in items: continue
        p = min(sum(price.get(x, 99) for x in pp) for pp in ps) + 2
        p = min(p, 250)
        if price.get(c) != p: price[c] = p; ch = True
for c in allr:
    if c in items: continue
    n = name_of.get(c, c)
    items[c] = [EMO.get(n, "✨"), n, min(4, dep.get(c, 1)), "made", price.get(c, 10), ""]
ACTS = {}
for _t, rows in g['MIX'] + g['MIXX']:
    for a, b, r, em, w in rows:
        if w: ACTS[ID(r)] = w
for a, b, r, em, w in g['MIX2'] + g['MIX3L']: ACTS[ID(r)] = w
for ins, r, em, w in g['MIX3'] + g['M34']: ACTS[ID(r)] = w
LIGHTS = ["jarlantern", "cocolamp", "litlantern", "lighthouse", "candlestick", "spotlight", "lamp"]
MUSIC = ["musicbox", "orchestrion", "musictower", "reefbell", "glasschime", "tinguitar", "drum", "drummer"]
CLEAN = ["trashnet", "seacleaner", "electromag", "trashhook"]
PLACE = LIGHTS + MUSIC + CLEAN + ["trampoline", "medkit", "thermo", "aquarium", "lookout", "waterfilter", "weedgarden", "coralgarden", "seagarden", "palmpot", "royalbed", "lounger", "tireswing", "scale2", "whalegate", "floatrock", "showcase", "shipmodel", "workbench", "krillhouse", "stainedglass", "framedpic", "paintedplate", "clock"]
for k in PLACE:
    if k in items and k not in ACTS: ACTS[k] = "Стои на дъното."
for k in LIGHTS: ACTS[k] = "Свети около него нощем."
for k in MUSIC: ACTS.setdefault(k, "Свири. Понякога той танцува.")
for k in CLEAN: ACTS[k] = "Сам прибира по някой боклук в сандъка."
ACTS["trampoline"] = "Стои на дъното. Докосни го и той скача."; ACTS["medkit"] = "Когато е пусната, контузиите и болестите минават по-бързо."; ACTS["thermo"] = "Когато е болен, показва колко му остава да оздравее."
ACTS = {k: v for k, v in ACTS.items() if k in PLACE}
weights = {"о": 6, "р": 2, "м": 1}
JUNK = [k for k in items if items[k][3] == "junk" for _ in range(weights[rar[k]])]
OTHER = [k for k in items if items[k][3] in ("nature", "part", "food", "living") and k in rar for _ in range(weights[rar[k]])] + ["weed"] * 6 + ["hardtack", "cannedfish"] * 0
OTHER += ["can", "hardtack", "coconut", "lemon", "honey"] * 2
DESC = {k: v[5] for k, v in items.items() if v[5]}
for k, w in ACTS.items(): DESC.setdefault(k, w)
for k, v in items.items(): v.pop()
out = dict(items=items, REC2=R2, RECN=RECN, HEAT=HEAT, COOL=COOL, APART=APART, NOAPART=sorted(set(NOAPART)), TIME=TIME, EDIBLE=EDIBLE, YUCK=YUCK, LIVING=sorted(living), ACTS=ACTS,
           LIGHTS=LIGHTS, MUSIC=MUSIC, CLEAN=CLEAN, JUNK=JUNK, OTHER=OTHER, DESC=DESC, HEAL=["soup", "honeytea"])
open(S + '/gen1.json', 'w').write(json.dumps(out, ensure_ascii=False))
print(len(items), len(R2), len(RECN), len(HEAT), len(COOL), len(APART), len(TIME), "made", sum(1 for v in items.values() if v[3] == "made"))
print([k for k in allr if k not in items])
