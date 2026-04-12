#!/usr/bin/env python3
import struct

with open('pascal_ast.xt', 'rb') as f:
    data = f.read()

# Parse first few nodes
for i in range(0, min(5*40, len(data)), 40):
    node = struct.unpack('<' + 'Q'*5, data[i:i+40])
    parent, rule_id, token_kind, start_val, offset_val = node
    print(f"Node {i//40}: parent={parent}, rule_id={rule_id}, token_kind={token_kind}, start={start_val}, offset={offset_val}")
