#include "library.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *here_doc_id;

void Init(const struct TContext *Context) {
    free(here_doc_id);
    here_doc_id = NULL;
    Context->RegisterTermRule("@HEREDOC_END");
}

void ProcessToken(const struct TContext *Context) {
    const char *mode = Context->GetMode();
    const char *token_value = Context->GetTokenValue();
    const char *token_kind = Context->GetTokenKind();
    if (strcmp(mode, "hereDoc") != 0) {
        return;
    }
    if (strcmp(token_kind, "START_HEREDOC") == 0) {
        size_t token_length = strlen(token_value);
        if (token_length < 3) {
            return;
        }
        size_t id_length = token_length - 3;
        char *new_id = (char *) malloc(id_length + 1);
        if (new_id == NULL) {
            return;
        }
        memcpy(new_id, token_value + 3, id_length);
        new_id[id_length] = '\0';
        free(here_doc_id);
        here_doc_id = new_id;
        return;
    }
    if (here_doc_id != NULL && strcmp(token_kind, "HEREDOC_TEXT") == 0 &&
        strstr(token_value, here_doc_id) == token_value) {
        Context->InsertToken("@HEREDOC_END", here_doc_id);
        Context->PopMode();
        free(here_doc_id);
        here_doc_id = NULL;
        return;
    }
}
