#!/usr/bin/env python3
# Read term rules
with open('pascal_ast.xtr', 'rb') as f:
    xtr_data = f.read()

print(f"xtr data length: {len(xtr_data)}")
print(f"First 10 bytes: {xtr_data[:10]}")

# Parse term rules (null-terminated strings)
term_rules = []
offset = 0
while offset < len(xtr_data):
    end = xtr_data.find(b'\x00', offset)
    if end == -1:
        break
    rule = xtr_data[offset:end].decode('latin-1')
    term_rules.append(rule)
    print(f"Index {len(term_rules)-1}: '{rule}'")
    offset = end + 1

print(f"\nTotal term rules: {len(term_rules)}")

# Check what's at specific indices
print(f"\nterm_rules[0]: '{term_rules[0]}'")
print(f"term_rules[1]: '{term_rules[1]}'")
print(f"term_rules[30]: '{term_rules[30]}'")
print(f"term_rules[31]: '{term_rules[31]}'")
print(f"term_rules[77]: '{term_rules[77]}'")
