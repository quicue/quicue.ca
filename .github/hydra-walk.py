#!/usr/bin/env python3
"""hydra_walk.py ENTRYPOINT_URL [--limit N] [--header 'Name: value']

Walk a quicue Hydra API the way a generic Hydra client would, using only
what the API says about itself:

  entry point -> Link rel=apiDocumentation -> ApiDocumentation
  entry point -> hydra:collection -> hydra:member -> resource
  resource -> each property the documentation defines as a hydra:Link with
  a hydra:supportedOperation -> send that operation's method to the link
  target

Prints one line per resource and a summary; exits 1 if any operation's
request fails or a link cannot be followed. Send no token to stay in mock
mode: with a valid token from the trusted subnet the server runs the
commands for real.
"""
import argparse
import json
import sys
import urllib.error
import urllib.request
from collections import Counter

ap = argparse.ArgumentParser()
ap.add_argument("entrypoint")
ap.add_argument("--limit", type=int, default=0, help="stop after N resources (0: all)")
ap.add_argument("--header", action="append", default=[])
args = ap.parse_args()
HYDRA = "http://www.w3.org/ns/hydra/core#"
extra = dict(h.split(": ", 1) for h in args.header)


def fetch(url, method="GET"):
    req = urllib.request.Request(url, method=method, headers={"Accept": "application/ld+json", **extra})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, dict(r.headers), r.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()


def api_doc_url(headers):
    for k, v in headers.items():
        if k.lower() == "link":
            for part in v.split(","):
                if f'rel="{HYDRA}apiDocumentation"' in part:
                    return part.split(">")[0].strip().lstrip("<")
    return None


def operations_by_link(doc):
    """property @id -> operation, for every hydra:Link property in the documentation."""
    out = {}
    for c in doc.get("hydra:supportedClass", []):
        for sp in c.get("hydra:supportedProperty", []):
            prop = sp.get("hydra:property")
            if isinstance(prop, dict) and prop.get("@type") == "hydra:Link":
                ops = prop.get("hydra:supportedOperation", [])
                if ops:
                    out[prop["@id"]] = ops[0]
    return out


fails = []
status, headers, body = fetch(args.entrypoint)
if status != 200:
    sys.exit(f"entry point {args.entrypoint}: HTTP {status}")
entry = json.loads(body)
doc_url = api_doc_url(headers)
if not doc_url:
    sys.exit("entry point has no Link rel=apiDocumentation")
s, _, b = fetch(doc_url)
doc = json.loads(b)
link_ops = operations_by_link(doc)
coll_url = entry["hydra:collection"]["@id"]
s, _, b = fetch(coll_url)
members = json.loads(b).get("hydra:member", [])
print(f"entry point ok; documentation {doc_url}: {len(link_ops)} link properties with operations; "
      f"collection {coll_url}: {len(members)} members")

results = Counter()
for i, m in enumerate(members):
    if args.limit and i >= args.limit:
        break
    s, _, b = fetch(m["@id"])
    if s != 200:
        fails.append(f"{m['@id']}: HTTP {s}")
        continue
    res = json.loads(b)
    n = 0
    for key, val in res.items():
        op = link_ops.get(key)
        if op is None or not isinstance(val, dict):
            continue
        target, method = val["@id"], op["hydra:method"]
        s, _, b = fetch(target, method)
        mode = json.loads(b).get("mode") if s == 200 else None
        results[(method, s, mode)] += 1
        n += 1
        if s != 200:
            fails.append(f"{method} {target}: HTTP {s}")
    print(f"  {res.get('name', m['@id'])}: {n} actions")

print("results (method, status, mode):", dict(results))
for f in fails[:10]:
    print("FAIL ", f)
sys.exit(1 if fails or not results else 0)
