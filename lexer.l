%{
	struct Token
	{
		char string_val[1024];
		char val_type[10];
		int index;
		int int_val;
		float float_val;
		int reg;
		int label;
	};
	typedef struct Token Token;
	#define YYSTYPE Token

    #include "y.tab.h"
    #include <stdlib.h>
	#include <string.h>
    void yyerror(char *);
%}

%option yylineno

%%

[;:,()\[\]{}=+\-*/^'"&|!><]			return *yytext;
">="			return GE;
"<="			return LE;
"=="			return EE;
"!="			return NE;
int|bool			{
						strcpy(yylval.string_val,yytext);
						return TYPE;
					}
void			{
					strcpy(yylval.string_val,yytext);
					return VOID;
				}
const			return constant;
[0-9]+			{
					yylval.int_val=atoi(yytext);
					return int_value;
				}
[0-9]+\.[0-9]+			{
							yylval.float_val=atof(yytext);
							return float_value;
						}
true|false			{
						if(strcmp(yytext,"true")==0)
							yylval.int_val=1;
						else if(strcmp(yytext,"false")==0)
							yylval.int_val=0;
						return bool_value;
					}
if			return IF;
elseif			return ELSEIF;
else			return ELSE;
while			return WHILE;
do			return DO;
for			return FOR;
switch			return SWITCH;
case			return CASE;
default			return DEFAULT;
break			return BREAK;
return			return RETURN;
[A-Za-z_][A-Za-z0-9_]*			{
									strcpy(yylval.string_val,yytext);
									return ID;
								}
[ \t\r\n]			;
.			yyerror("invalid character");

%%

int yywrap()
{
	return 1;
}