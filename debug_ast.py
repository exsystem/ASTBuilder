import struct

# Read tree file
with open('pascal_ast.xt', 'rb') as f:
    data = f.read()

# Read string file
with open('pascal_ast.xs', 'rb') as f:
    code_string = f.read().rstrip(b'\x00').decode('latin-1')

# Read term rules
with open('pascal_ast.xtr', 'rb') as f:
    xtr_data = f.read()

# Parse term rules (null-terminated strings)
term_rules = []
offset = 0
while offset < len(xtr_data):
    end = xtr_data.find(b'\x00', offset)
    if end == -1:
        break
    term_rules.append(xtr_data[offset:end].decode('latin-1'))
    offset = end + 1

# Parse tree nodes (40 bytes each: parent(8), rule_id(8), token_kind(8), start_pos(8), str_offset(8))
nodes = []
for i in range(0, len(data), 40):
    if i + 40 > len(data):
        break
    # Use Q for unsigned long long (8 bytes), I for unsigned int (4 bytes)
    node = struct.unpack('<' + 'Q'*5, data[i:i+40])
    nodes.append(node)

# Filter terminal nodes (rule_id == 0) - terminals have rule_id of 0
terminals = [(n[3], n[4], n[2]) for n in nodes if n[1] == 0 and n[2] < len(term_rules)]
# Also check what rule_id=1 means
non_terminals = [(n[0], n[1], n[2], n[3], n[4]) for n in nodes if n[1] != 0]
print(f"Non-terminals (rule_id != 0): {len(non_terminals)}")
terminals.sort(key=lambda x: x[1])  # sort by str_offset

print(f"Total nodes: {len(nodes)}")
print(f"Terminal nodes: {len(terminals)}")

# Extract tokens
tokens = []
for i, (start_pos, str_offset, token_kind) in enumerate(terminals):
    if i + 1 < len(terminals):
        next_offset = terminals[i+1][1]
    else:
        next_offset = len(code_string)
    
    length = next_offset - str_offset
    if 0 < length < 500 and str_offset + length <= len(code_string):
        token_text = code_string[str_offset:str_offset+length]
        tokens.append((term_rules[token_kind], token_text, start_pos, str_offset))

# Print heredoc-related tokens
for name, text, sp, so in tokens:
    if 'HEREDOC' in name or 'START' in name:
        print(f"{name}: '{text}' (sp={sp}, so={so})")

# Print first 5 tokens
print("\nFirst 10 tokens:")
for name, text, sp, so in tokens[:10]:
    print(f"{name}: '{text}' (sp={sp}, so={so})")
