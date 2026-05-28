%{
    #include <iostream>
    #include <string>
    #include <cstring>
    #include "parser.tab.h"
    using namespace std;
%}

%option noyywrap
%option yylineno

/* Declaram o stare exclusiva pentru comentarii bloc */
%x COMMENT_STATE

%%

    /*REGULI PENTRU COMENTARII*/

"//".* { /* Ignoram comentarii pe o linie */ }

"/*"                { BEGIN(COMMENT_STATE); } 
<COMMENT_STATE>"*/" { BEGIN(INITIAL); }       
<COMMENT_STATE>\n   { /* Ignoram newline in comentariu */ }
<COMMENT_STATE>.    { /* Ignoram orice alt caracter in comentariu */ }

    /* KEYWORDS*/

[ \t\n]+            { /* Ignoram spatii normale din cod */ }

"const"             { return CONST; } 
"var"               { return VAR; }
"int"               { return TYPE_INT; }
"float"             { return TYPE_FLOAT; }
"string"            { return TYPE_STRING; }
"bool"              { return TYPE_BOOL; }
"void"              { return TYPE_VOID; }

"entity"            { return ENTITY; }
"action"            { return ACTION; }
"Main"              { return MAIN; }
"Read"              { return READ; }
"return"            { return RETURN; }
"Print"             { return PRINT; }
"check"             { return CHECK; }
"loop"              { return LOOP; }
"for"               { return FOR; }
"self"              { return SELF; }

    /* --- OPERATORI --- */

":="                { return ASSIGN; }
"=="                { return EQ; }
"!="                { return NEQ; }
"<="                { return LEQ; }
">="                { return GEQ; }
"&&"                { return AND; }
"||"                { return OR; }

"++"                { return INC; } 
"--"                { return DEC; }

"+"                 { return '+'; }
"-"                 { return '-'; }
"*"                 { return '*'; }
"/"                 { return '/'; }
"%"                 { return '%'; }
"<"                 { return '<'; }
">"                 { return '>'; }
"!"                 { return '!'; } 

    /*DELIMITATORI*/

"("                 { return '('; }
")"                 { return ')'; }
"["                 { return '['; } 
"]"                 { return ']'; }
"{"                 { return '{'; }
"}"                 { return '}'; }
","                 { return ','; }
"."                 { return '.'; }
";"                 { return ';'; }
":"                 { return ':'; }

    /*LITERALI*/

"true"|"false"      { yylval.strval = strdup(yytext); return BOOL_VAL; }
[0-9]+              { yylval.intval = atoi(yytext); return INT_VAL; }
[0-9]+\.[0-9]+      { yylval.floatval = atof(yytext); return FLOAT_VAL; }
\"[^\"]*\"          { yylval.strval = strdup(yytext); return STRING_VAL; }

    /*IDENTIFICATORI*/

[a-zA-Z][a-zA-Z0-9_]* { 
    yylval.strval = strdup(yytext); 
    return ID; 
}

.                   { cout << "Eroare lexicala la linia " << yylineno << ": " << yytext << endl; exit(1); }

%%