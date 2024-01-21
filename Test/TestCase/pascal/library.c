#include "library.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void Init(const struct TContext *Context) {
    Context->RegisterTermRule("@HEREDOC_END");
}

void ProcessToken(const struct TContext *Context) {
    const char *mode = Context->GetMode();
    const char *token_value = Context->GetTokenValue();
    const char *token_kind = Context->GetTokenKind();
    static char *here_doc_id;
    if (strcmp(mode, "hereDoc") != 0) {
        return;
    }
    if (strcmp(token_kind, "START_HEREDOC") == 0) {
        here_doc_id = (char *) malloc(strlen(token_value) - 3);
        strncpy(here_doc_id, token_value + 3, strlen(token_value) - 3);
        return;
    }
    if (strcmp(token_kind, "HEREDOC_TEXT") == 0 && strstr(token_value, here_doc_id) == token_value) {
        Context->InsertToken("@HEREDOC_END", here_doc_id);
        Context->PopMode();
        free(here_doc_id);
        return;
    }
}
