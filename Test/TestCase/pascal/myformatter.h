//
// Created by 許子健 on 2024/1/20.
//

#ifndef MYFORMATTER_H
#define MYFORMATTER_H

typedef void (*TRegisterTermRule)(char *Name);

typedef char *(*TGetMode)(void);

typedef char *(*TGetTokenKind)(void);

typedef char *(*TGetTokenValue)(void);

typedef void (*TInsertToken)(char *Kind, char *Value);

typedef void (*TPopMode)(void);

typedef struct TContext *PContext;

struct TContext {
    TRegisterTermRule RegisterTermRule;
    TGetMode GetMode;
    TGetTokenKind GetTokenKind;
    TGetTokenValue GetTokenValue;
    TInsertToken InsertToken;
    TPopMode PopMode;
};

#endif //MYFORMATTER_H
