#!/usr/bin/env bash
# Final version — full snapshot with LOC total and fixed f-string

set -euo pipefail

# ---- Settings ----
ESTIMATE_TIME=1
GAP_MIN=720             # time gap between commits (minutes)
MIN_SESSION_MIN=30      # minimum time credited per session

# ---- Ensure Git repo ----
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not inside a Git repo"; exit 1;
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "Repo: $(basename "$REPO_ROOT")"
echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo
echo "Files (tracked by Git): $(git ls-files | wc -l)"
echo
echo "Commits (current branch): $(git rev-list --count HEAD)"
echo "Commits (all branches):   $(git rev-list --all --count)"
echo

# ---- Lines of Code by Language ----
echo "Lines of Code by language:"
git ls-files -z \
| python3 -c "
import sys, os
from collections import defaultdict

REPO_ROOT = os.getcwd()
EXT2LANG = {
  'py': 'Python', 'js': 'JavaScript', 'ts': 'TypeScript', 'tsx': 'TypeScript',
  'sh': 'Shell', 'sql': 'SQL', 'json': 'JSON', 'yml': 'YAML', 'yaml': 'YAML',
  'html': 'HTML', 'css': 'CSS', 'scss': 'SCSS', 'md': 'Markdown', 'java': 'Java',
  'c': 'C', 'cpp': 'C++', 'h': 'C Header', 'go': 'Go', 'rs': 'Rust', 'rb': 'Ruby',
  'php': 'PHP', 'swift': 'Swift', 'kt': 'Kotlin', 'txt': 'Text',
  'csv': 'CSV', 'tsv': 'TSV', 'log': 'Log'
}

langs = defaultdict(int)
total = 0
paths = sys.stdin.read().split('\0')

for rel_path in paths:
    if not rel_path.strip():
        continue
    full_path = os.path.join(REPO_ROOT, rel_path.strip())
    ext = os.path.splitext(rel_path)[1].lstrip('.').lower()
    lang = EXT2LANG.get(ext, ext if ext else 'Other')
    try:
        with open(full_path, errors='ignore') as f:
            line_count = sum(1 for _ in f)
        langs[lang] += line_count
        total += line_count
    except Exception as e:
        print(f'Could not read: {rel_path} ({e})', file=sys.stderr)

if not langs:
    print('No lines of code detected. Check file types or encoding.', file=sys.stderr)
else:
    for lang, count in sorted(langs.items(), key=lambda x: -x[1]):
        print(f'{lang:20} {count}')
    print(f\"{'Total':20} {total}\")
"

echo

# ---- Time Estimate by Commit Activity ----
if [ "$ESTIMATE_TIME" = "1" ]; then
  echo "Estimated time spent (by author; session gap = ${GAP_MIN} min, min session = ${MIN_SESSION_MIN} min):"
  git log --all --date=iso-strict --pretty=format:'%aI|%an' \
  | python3 - "$GAP_MIN" "$MIN_SESSION_MIN" <<'PY'
import sys,datetime,collections
gap_minutes=int(sys.argv[1])
min_session=int(sys.argv[2])
gap=datetime.timedelta(minutes=gap_minutes)
min_len=datetime.timedelta(minutes=min_session)

per=collections.defaultdict(lambda:{"sessions":[],"last":None,"start":None})
def parse(ts): return datetime.datetime.strptime(ts,"%Y-%m-%dT%H:%M:%S%z")

for line in sys.stdin:
    ts,author=line.strip().split("|",1)
    t=parse(ts)
    p=per[author]
    if p["last"] is None:
        p["start"]=t; p["last"]=t
    else:
        if p["last"]-t > gap:
            dur=p["start"]-p["last"]
            if dur<min_len: dur=min_len
            p["sessions"].append(dur)
            p["start"]=t
        p["last"]=t

# Close final session
total=datetime.timedelta()
rows=[]
for author,p in per.items():
    if p["last"] is not None:
        dur=p["start"]-p["last"]
        if dur<min_len: dur=min_len
        p["sessions"].append(dur)
    spent=sum(p["sessions"],datetime.timedelta())
    total+=spent
    rows.append((author,spent.total_seconds()/3600))

for author,hrs in sorted(rows,key=lambda x:-x[1]):
    print(f"{author:30s} {hrs:8.2f} hours")
print(f"\nEstimated total: {total.total_seconds()/3600:8.2f} hours")
PY
fi

echo
echo "Commit count by author:"
git shortlog -sne

