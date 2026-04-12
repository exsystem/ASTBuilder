#!/usr/bin/env python3
"""
Test if readfile works with Test/vim.pas
"""

# Simulate what Vim would do when reading file as binary
with open('/Users/exsystem/DelphiProjects/XDE/ASTBuilder/Test/vim.pas', 'rb') as f:
    content = f.read()

print(f"File length: {len(content)}")
print(f"First 10 bytes: {content[:10]}")

# Check what Vim would get with readfile('b')
# In Vim, readfile(filename, 'b') returns a list of character codes
char_codes = [ord(c) if isinstance(c, str) else c for c in content]
print(f"Number of character codes: {len(char_codes)}")
print(f"First 10 char codes: {char_codes[:10]}")

# Verify we can reconstruct
reconstructed = bytes(char_codes).decode('latin-1')
print(f"Reconstructed length: {len(reconstructed)}")
print(f"First 10 chars: {reconstructed[:10]}")
