#!/usr/bin/env python3
"""
Test the vim plugin fix by simulating its behavior.
This verifies that tokens from xs file can be found in original buffer.
"""
import struct
import re

# Read source file (original)
with open('Test/vim.pas', 'rb') as f:
    original_buffer = f.read()

# Read AST files
with open('pascal_ast.xt', 'rb') as f:
    data = f.read()

with open('pascal_ast.xs', 'rb') as f:
    xs_code = f.read().rstrip(b'\x00')

with open('pascal_ast.xtr', 'rb') as f:
    xtr_data = f.read()

# Parse term rules
term_rules = []
offset = 0
while offset < len(xtr_data):
    end = xtr_data.find(b'\x00', offset)
    if end == -1:
        break
    term_rules.append(xtr_data[offset:end].decode('latin-1'))
    offset = end + 1

# Parse nodes
nodes = []
for i in range(0, len(data), 40):
    if i + 40 > len(data):
        break
    node = struct.unpack('<' + 'Q'*5, data[i:i+40])
    nodes.append(node)

# Filter terminal nodes (rule_id == 0)
terminals = [(n[3], n[4], n[2]) for n in nodes if n[1] == 0 and n[2] < len(term_rules)]
terminals.sort(key=lambda x: x[1])  # Sort by offset in xs file

print("=== SIMULATING VIM PLUGIN BEHAVIOR ===")
print(f"Original buffer length: {len(original_buffer)}")
print(f"XS code length: {len(xs_code)}")
print()

# Simulate term_data extraction
term_data = []
for i, (start_pos, str_offset, token_kind) in enumerate(terminals):
    name = term_rules[token_kind]
    
    # Extract from xs file
    if i + 1 < len(terminals):
        next_offset = terminals[i+1][1]
        txt = xs_code[str_offset:next_offset]
    else:
        txt = xs_code[str_offset:]
    
    if len(txt) > 0:
        term_data.append({'name': name, 'text': txt.decode('latin-1'), 'start_pos': start_pos})

print(f"Extracted {len(term_data)} tokens")

# Simulate matching
def escape_regex(text):
    """Escape special regex characters"""
    import re as re_mod
    return re_mod.escape(text)

buffer_pos = 0
success_count = 0
fail_count = 0

for i, item in enumerate(term_data):  # Test all tokens
    name = item['name']
    tok_text = item['text']
    start_pos = item['start_pos']
    
    # Escape token text
    pattern = escape_regex(tok_text)
    
    # Make search robust to line endings (replace \n with \r?\n for CRLF support)
    search_pattern = pattern.replace(r'\n', r'\r?\n')
    
    # Find in buffer (decode original_buffer to string for regex matching)
    orig_text = original_buffer[buffer_pos:].decode('latin-1')
    match = re.search(search_pattern, orig_text, re.IGNORECASE)
    
    if match:
        found_pos = buffer_pos + match.start()
        actual_len = len(match.group())
        
        # Calculate line/col
        before_text = original_buffer[:found_pos]
        lines = before_text.decode('latin-1').split('\n')
        lnum = len(lines)
        cnum = len(lines[-1]) + 1 if lines else 1
        
        # Update buffer_pos
        buffer_pos = found_pos + actual_len
        
        success_count += 1
        print(f"Token {i}: {name:20s} FOUND at pos {found_pos}, length {actual_len}")
    else:
        fail_count += 1
        print(f"Token {i}: {name:20s} NOT FOUND (text={repr(tok_text)})")

print()
print(f"Success: {success_count}/{len(term_data)}")
print(f"Failed: {fail_count}/{len(term_data)}")

# Show all tokens that failed
if fail_count > 0:
    print()
    print("=== FAILED TOKENS ===")
    buffer_pos = 0
    for i, item in enumerate(term_data):
        name = item['name']
        tok_text = item['text']
        
        pattern = escape_regex(tok_text)
        search_pattern = pattern.replace(r'\n', r'\r?\n')
        
        orig_text = original_buffer[buffer_pos:].decode('latin-1')
        match = re.search(search_pattern, orig_text, re.IGNORECASE)
        
        if not match:
            print(f"  Token {i}: {name:20s} -> '{tok_text}'")
