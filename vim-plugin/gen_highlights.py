import sys
import os
import struct

def to_hex_pattern(text_bytes):
    result = ""
    for b in text_bytes:
        # Only keep safe ASCII characters as-is.
        # Escape everything else to \xXX to avoid encoding-related issues in syntax patterns.
        # Safe ASCII: 32-126, but escape some special regex chars.
        if 32 <= b <= 126 and chr(b) not in r'\/ []^$.*~"':
            result += chr(b)
        else:
            result += r'\x{:02x}'.format(b)
    return result

def gen_highlights(prefix, buf_path):
    xt_path = prefix + "ast.xt"
    xtr_path = prefix + "ast.xtr"
    xs_path = prefix + "ast.xs"
    
    if not all(os.path.exists(p) for p in [xt_path, xtr_path, xs_path, buf_path]):
        return

    # Read term rules (null-separated strings)
    with open(xtr_path, 'rb') as f:
        term_rules = f.read().split(b'\x00')

    # Read XS blob (code text)
    with open(xs_path, 'rb') as f:
        xs_blob = f.read()

    # Read original buffer blob to calculate line offsets
    with open(buf_path, 'rb') as f:
        buffer_blob = f.read()

    line_offsets = [0]
    for i, b in enumerate(buffer_blob):
        if b == 10: # \n
            line_offsets.append(i + 1)

    # Read nodes (40 bytes each)
    nodes = []
    with open(xt_path, 'rb') as f:
        while True:
            data = f.read(40)
            if len(data) < 40:
                break
            # 5 x 8-byte uint64 (little-endian)
            # parent, rule, token, start, offset
            nodes.append(struct.unpack('<QQQQQ', data))

    # Extract terminal nodes (rule == 0)
    terms = [n for n in nodes if n[1] == 0]
    terms.sort(key=lambda x: x[4]) # Sort by offset in xs_blob

    term_data = []
    for i in range(len(terms)):
        t = terms[i]
        token_id = t[2]
        if token_id >= len(term_rules):
            continue
        name = term_rules[token_id].decode('ascii', errors='ignore')
        
        start_in_xs = t[4]
        if i + 1 < len(terms):
            end_in_xs = terms[i+1][4]
        else:
            end_in_xs = len(xs_blob)
            
        txt_bytes = xs_blob[start_in_xs:end_in_xs]
        if txt_bytes:
            term_data.append({'name': name, 'text': txt_bytes, 'start_pos': t[3]})

    # Category map
    KEYWORDS = {'PROGRAM', 'UNIT', 'INTERFACE', 'IMPLEMENTATION', 'USES', 'TYPE', 'RECORD', 'VAR', 'CONST', 'BEGIN', 'END', 'PROCEDURE', 'FUNCTION', 'IF', 'THEN', 'ELSE', 'FOR', 'WHILE', 'REPEAT', 'UNTIL', 'DO', 'WITH', 'GOTO', 'LABEL', 'ARRAY', 'OF', 'FILE', 'SET', 'STRING', 'AND', 'OR', 'NOT', 'XOR', 'DIV', 'MOD', 'SHL', 'SHR', 'IN', 'AS', 'IS', 'NIL', 'TO', 'DOWNTO', 'EXIT', 'RESULT', 'READLN', 'WRITELN', 'READ', 'WRITE', 'BYTE', 'INTEGER', 'BOOLEAN', 'CHAR', 'WORD', 'LONGINT', 'DOUBLE', 'SINGLE', 'EXTENDED', 'PCHAR', 'POINTER', 'TSIZE', 'PSIZE', 'REAL'}
    
    # Map token names to highlighting groups
    output = []
    
    # We'll use a simple matching logic in Python too, to confirm positions
    buffer_pos = 0
    in_heredoc = False
    
    for item in term_data:
        name = item['name']
        txt_bytes = item['text']
        start_pos = item['start_pos']
        
        # Simple search for the bytes in the buffer
        found_pos = buffer_blob.find(txt_bytes, buffer_pos)
        if found_pos == -1:
            # Fallback: search from beginning
            found_pos = buffer_blob.find(txt_bytes, 0)
            if found_pos == -1:
                continue
        
        actual_len = len(txt_bytes)
        buffer_pos = found_pos + actual_len
        
        # Calculate line/col
        import bisect
        line_idx = bisect.bisect_right(line_offsets, found_pos) - 1
        lnum = line_idx + 1
        cnum = found_pos - line_offsets[line_idx] + 1 # byte-based column
        
        group = ""
        if name == 'START_HEREDOC':
            in_heredoc = True
            group = "pascalHeredoc"
        elif name == '@HEREDOC_END':
            in_heredoc = False
            group = "pascalHeredoc"
        elif name == 'HEREDOC_TEXT' or in_heredoc:
            group = "pascalHeredoc"
        elif name == 'STRING_LITERAL':
            group = "pascalString"
        elif name == 'NUM_REAL':
            group = "pascalFloat"
        elif name == 'NUM_INT':
            group = "pascalNumber"
        elif name in KEYWORDS:
            group = "pascalKeyword"
        elif name in {'IDENTIFIER', 'ID', 'IDENT', 'NAME', 'TEXT', 'STRING'}:
            group = "pascalIdentifier"
        elif name == 'STRING_LITERAL_TYPE':
            group = "pascalType"
        elif name in {'DIRECTIVE', 'COMPILER_DIRECTIVE', 'COMMENT_1', 'COMMENT_2'}:
            group = "pascalComment"
            
        if group:
            pattern = to_hex_pattern(txt_bytes)
            output.append(f"syntax match {group} /\\%{lnum}l\\%{cnum}c\\V{pattern}/")

    with open('/tmp/pascal_highlights.vim', 'w') as f:
        f.write('\n'.join(output))

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        gen_highlights(sys.argv[1], sys.argv[2])
