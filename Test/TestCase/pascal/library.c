#include "library.h"

#include <stdlib.h>
#include <string.h>

static uint8_t *here_doc_id;
static size_t here_doc_id_length;

static size_t encoded_char_size(PTChar text, uint8_t encoding) {
    uint8_t first = text[0];
    if (encoding == ekUTF16LE || encoding == ekUTF16BE) {
        uint16_t code_unit = encoding == ekUTF16LE
            ? (uint16_t)(text[0] | ((uint16_t)text[1] << 8))
            : (uint16_t)(((uint16_t)text[0] << 8) | text[1]);
        if (code_unit >= 0xD800 && code_unit <= 0xDBFF) {
            return 4;
        }
        return 2;
    }
    if (encoding == ekGBK && first >= 0x81) {
        return 2;
    }
    if (encoding == ekUTF8) {
        if (first >= 0xF0) return 4;
        if (first >= 0xE0) return 3;
        if (first >= 0xC2) return 2;
    }
    return 1;
}

static size_t encoded_length(PTChar text, uint8_t encoding) {
    size_t offset = 0;
    if (text == NULL) {
        return 0;
    }
    if (encoding == ekUTF16LE || encoding == ekUTF16BE) {
        while (text[offset] != 0 || text[offset + 1] != 0) {
            offset += encoded_char_size(text + offset, encoding);
        }
    } else {
        while (text[offset] != 0) {
            offset += encoded_char_size(text + offset, encoding);
        }
    }
    return offset;
}

static int encoded_ascii_equal(PTChar text, const char *ascii,
                               uint8_t encoding) {
    size_t offset = 0;
    size_t index = 0;
    while (ascii[index] != '\0') {
        if (encoding == ekUTF16LE || encoding == ekUTF16BE) {
            uint16_t code_unit = encoding == ekUTF16LE
                ? (uint16_t)(text[offset] | ((uint16_t)text[offset + 1] << 8))
                : (uint16_t)(((uint16_t)text[offset] << 8) | text[offset + 1]);
            if (code_unit != (uint8_t)ascii[index]) {
                return 0;
            }
            offset += 2;
        } else {
            if (text[offset] != (uint8_t)ascii[index]) {
                return 0;
            }
            offset++;
        }
        index++;
    }
    if (encoding == ekUTF16LE || encoding == ekUTF16BE) {
        return text[offset] == 0 && text[offset + 1] == 0;
    }
    return text[offset] == 0;
}

static size_t encoded_ascii_prefix_length(PTChar text, const char *ascii,
                                          uint8_t encoding) {
    size_t offset = 0;
    size_t index = 0;
    while (ascii[index] != '\0') {
        if (encoding == ekUTF16LE || encoding == ekUTF16BE) {
            uint16_t code_unit = encoding == ekUTF16LE
                ? (uint16_t)(text[offset] | ((uint16_t)text[offset + 1] << 8))
                : (uint16_t)(((uint16_t)text[offset] << 8) | text[offset + 1]);
            if (code_unit != (uint8_t)ascii[index]) {
                return 0;
            }
            offset += 2;
        } else {
            if (text[offset] != (uint8_t)ascii[index]) {
                return 0;
            }
            offset++;
        }
        index++;
    }
    return offset;
}

static uint8_t *encode_ascii(const char *ascii, uint8_t encoding) {
    size_t length = strlen(ascii);
    size_t char_width = encoding == ekUTF16LE || encoding == ekUTF16BE ? 2 : 1;
    uint8_t *result = (uint8_t *)calloc(length * char_width + char_width, 1);
    size_t index;
    if (result == NULL) {
        return NULL;
    }
    for (index = 0; index < length; index++) {
        if (char_width == 1) {
            result[index] = (uint8_t)ascii[index];
        } else if (encoding == ekUTF16LE) {
            result[index * 2] = (uint8_t)ascii[index];
        } else {
            result[index * 2 + 1] = (uint8_t)ascii[index];
        }
    }
    return result;
}

void Init(const struct TContext *Context) {
    free(here_doc_id);
    here_doc_id = NULL;
    here_doc_id_length = 0;
    uint8_t *end_rule = encode_ascii("@HEREDOC_END", Context->Encoding);
    if (end_rule != NULL) {
        Context->RegisterTermRule(end_rule);
        free(end_rule);
    }
}

void ProcessToken(const struct TContext *Context) {
    PTChar mode = Context->GetMode();
    PTChar token_value = Context->GetTokenValue();
    PTChar token_kind = Context->GetTokenKind();
    uint8_t encoding = Context->Encoding;
    if (!encoded_ascii_equal(mode, "hereDoc", encoding)) {
        return;
    }
    if (encoded_ascii_equal(token_kind, "START_HEREDOC", encoding)) {
        size_t token_length = encoded_length(token_value, encoding);
        size_t prefix_length =
            encoded_ascii_prefix_length(token_value, "<<<", encoding);
        if (prefix_length == 0 || token_length < prefix_length) {
            return;
        }
        size_t id_length = token_length - prefix_length;
        size_t terminator_length =
            encoding == ekUTF16LE || encoding == ekUTF16BE ? 2 : 1;
        uint8_t *new_id = (uint8_t *)calloc(id_length + terminator_length, 1);
        if (new_id == NULL) {
            return;
        }
        memcpy(new_id, token_value + prefix_length, id_length);
        free(here_doc_id);
        here_doc_id = new_id;
        here_doc_id_length = id_length;
        return;
    }
    if (here_doc_id != NULL &&
        encoded_ascii_equal(token_kind, "HEREDOC_TEXT", encoding) &&
        encoded_length(token_value, encoding) >= here_doc_id_length &&
        memcmp(token_value, here_doc_id, here_doc_id_length) == 0) {
        uint8_t *end_rule = encode_ascii("@HEREDOC_END", encoding);
        if (end_rule != NULL) {
            Context->InsertToken(end_rule, here_doc_id);
            free(end_rule);
        }
        Context->PopMode();
        free(here_doc_id);
        here_doc_id = NULL;
        here_doc_id_length = 0;
    }
}
