//
// Created by 許子健 on 2024/1/20.
//

#ifndef MYFORMATTER_H
#define MYFORMATTER_H

#include <stdint.h>

typedef const uint8_t *PTChar;

enum {
    ekASCII = 0,
    ekUTF8 = 1,
    ekUTF16LE = 2,
    ekUTF16BE = 3,
    ekGBK = 4
};

typedef void (*TRegisterTermRule)(PTChar Name);

typedef PTChar (*TGetMode)(void);

typedef PTChar (*TGetTokenKind)(void);

typedef PTChar (*TGetTokenValue)(void);

typedef void (*TInsertToken)(PTChar Kind, PTChar Value);

typedef void (*TPopMode)(void);

typedef struct TContext *PContext;

struct TContext {
    TRegisterTermRule RegisterTermRule;
    TGetMode GetMode;
    TGetTokenKind GetTokenKind;
    TGetTokenValue GetTokenValue;
    TInsertToken InsertToken;
    TPopMode PopMode;
    uint8_t Encoding;
};

#endif //MYFORMATTER_H
