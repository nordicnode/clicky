#!/usr/bin/env python3
"""Static checks for the journal's authored chapter dependencies.

This checks the GML content definitions, not the running game or playtime.
"""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
album = (root / 'Clicky/scripts/scr_album/scr_album.gml').read_text()
init = (root / 'Clicky/scripts/scr_init/scr_init.gml').read_text()
save = (root / 'Clicky/scripts/scr_save/scr_save.gml').read_text()

count = int(re.search(r'#macro JOURNAL_CHAPTERS\s+(\d+)', album).group(1))
block = album.split('function journal_goal(', 1)[1].split('function journal_value(', 1)[0]
rows = re.findall(r'\[\{ kind:.*?\}\]', block, re.S)
assert len(rows) == count, (len(rows), count)

goals = []
for row in rows:
    items = re.findall(r'kind: "(\w+)", target: (\d+), label: "([^"]+)"', row)
    assert len(items) == 4, items
    goals.append([(kind, int(target), label) for kind, target, label in items])

# A chapter opens after 3 claims in its predecessor. Assume all ordinary
# activities can be completed; explicitly model only projects locked by chapter.
for chapter, items in enumerate(goals[:-1]):
    possible = sum(kind != 'project' or target <= 3 * (chapter + 1)
                   for kind, target, _ in items)
    assert possible >= 3, (chapter, items)

names = album.split('function journal_project_name(', 1)[1].split('function journal_project_cost(', 1)[0]
project_rows = re.findall(r'\["([^\"]+)", "([^\"]+)", "([^\"]+)"\]', names)
assert len(project_rows) == count, project_rows
assert len({name for row in project_rows for name in row}) == count * 3

assert 'claims: array_create(32, 0)' in init
assert 'projects: array_create(24, 0)' in init
for field in ('claims', 'projects', 'skills', 'order_active', 'order_chapter', 'order_start'):
    assert f'array_resize(global.G.journal.{field}' in save, field
for material in ('treats', 'scraps', 'dust'):
    assert f'{material}: 0' in init
assert 'global.G.journal.stamps += 1' in album
assert 'global.G.journal.materials[$ _key] -= _materials' in album
assert 'global.G.journal.order_active[_order] = 1' in album
assert 'global.G.journal.order_active[_order] = 0' in album
assert 'journal_order_progress(_order)' in album

step = (root / 'Clicky/objects/obj_album/Step_0.gml').read_text()
for action in ('journal_claim(chapter, _i)', 'journal_project_buy(chapter, _i)',
               'journal_order_start(_i, chapter)', 'journal_order_claim(_i)',
               'journal_skill_buy(_i)'):
    assert action in step, action

print(f'PASS: {count} chapters, {count * 4} goals, {count * 3} unique projects;')
print('chapter dependencies, UI call sites, save fields and order/material definitions checked statically')
