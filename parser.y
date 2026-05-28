%{
    #include <iostream>
    #include <string>
    #include <vector>
    #include <cstring> 
    #include <sstream>
    #include "symbol_table.h"
    #include "ast.h" 
    
    // Declaratii externe din Lexer
    extern int yylineno;
    extern int yylex();
    extern char* yytext;
    extern FILE* yyin;
    
    void yyerror(const char *s);

    using namespace std;

    // Helper pentru string-uri
    char* mystrdup(const char* s) {
        if (!s) return NULL;
        char* d = new char[strlen(s) + 1];
        strcpy(d, s);
        return d;
    }

    // Gestionarea tabelelor de simboluri
    SymbolTable* globalScope = nullptr;
    SymbolTable* currentScope = nullptr;
    vector<SymbolTable*> allTables; 
    vector<Symbol> tempParams; 


    // Adauga o variabila simpla (suporta CONST)
    void addVarToTable(string name, string type, bool isConst, string value = "") {
        if (currentScope) {
            Symbol s(name, "variable", type, value, isConst);
            currentScope->addSymbol(s);
        }
    }

    // Adauga un VECTOR (Array)
    void addArrayToTable(string name, string type, int size) {
        if (currentScope) {
            Symbol s(name, "variable", type, "");
            s.isArray = true;
            s.arraySize = size;
            // s.isConst este false default
            currentScope->addSymbol(s);
        }
    }

    // Verificarea semantica a tipurilor
    void checkTypes(string type1, string type2, const char* op) {
        // Permitem mix intre int si float
        if ((type1 == "int" || type1 == "float") && (type2 == "int" || type2 == "float")) {
            return; 
        }
        if (type1 != type2) {
            cerr << "SEMANTIC ERROR la linia " << yylineno << ": Type mismatch! Nu poti face operatia '" 
                 << op << "' intre '" << type1 << "' si '" << type2 << "'." << endl;
            exit(1);
        }
    }
%}

/*
   DEFINITII UNION SI TOKENI
*/
%union {
    int intval;
    float floatval;
    char* strval;
    class ASTNode* node;
    class BlockNode* block;
}

/* Cuvinte cheie */
%token VAR CONST ENTITY ACTION MAIN RETURN PRINT READ CHECK LOOP FOR SELF
%token TYPE_INT TYPE_FLOAT TYPE_BOOL TYPE_STRING TYPE_VOID


/* Operatori */
%token ASSIGN EQ NEQ LEQ GEQ AND OR INC DEC

/* Literali si Identificatori */
%token <intval> INT_VAL 
%token <floatval> FLOAT_VAL
%token <strval> STRING_VAL BOOL_VAL ID

/*PRECEDENTA OPERATORILOR*/
%left OR
%left AND
%left EQ NEQ
%left '<' '>' LEQ GEQ
%left '+' '-'
%left '*' '/' '%'
%right '!' INC DEC UMINUS /* Operatorii unari au prioritate mare */

/* Tipuri returnate de reguli */
%type <strval> type
%type <node> expression function_call statement assignment
%type <block> statement_list func_body_statements main_block program

%start program

%%

/*
   REGULI GRAMATICALE
*/

program:
    {
        globalScope = new SymbolTable("Global Scope");
        currentScope = globalScope;
        allTables.push_back(globalScope);
    }
    global_declarations main_block 
    {
        if ($3 != nullptr) {
            cout << "\n=== EXECUTION START ===\n";
            $3->evaluate(globalScope);
            cout << "=== EXECUTION END ===\n";
        }
        cout << "SUCCESS: Program valid!\n";
    }
    ;

global_declarations: global_declarations global_decl | /* empty */ ;

global_decl: var_decl | class_decl | func_decl ;

/* Tipuri de date suportate */
type:
    TYPE_INT      { $$ = mystrdup("int"); }
    | TYPE_FLOAT  { $$ = mystrdup("float"); }
    | TYPE_BOOL   { $$ = mystrdup("bool"); }
    | TYPE_STRING { $$ = mystrdup("string"); }
    | TYPE_VOID   { $$ = mystrdup("void"); }
    | ID          { $$ = $1; }
    ;

/* Declaratii de Variabile */
var_decl:
    //Variabila Normala: var x : int;
    VAR ID ':' type ';' 
    {
        addVarToTable($2, $4, false); 
    }
    //Constanta: const var PI : float;
    | CONST VAR ID ':' type ';'
    {
        addVarToTable($3, $5, true); 
    }
    //Vector: var v[10] : int;
    | VAR ID '[' INT_VAL ']' ':' type ';'
    {
        addArrayToTable($2, $7, $4);
    }
    ;

/* Declaratii Clase */
class_decl:
    ENTITY ID '{' 
    {
        Symbol s($2, "class", "Entity");
        currentScope->addSymbol(s);
        
        SymbolTable* classScope = new SymbolTable("Class " + string($2), currentScope);
        allTables.push_back(classScope);
        currentScope = classScope; 
    }
    class_body '}'
    {
        currentScope = currentScope->parentScope;
    }
    ;

class_body: class_body class_member | /* empty */ ;
class_member: var_decl | func_decl ;

/* Declaratii Functii */
func_decl:
    ACTION ID '(' param_list ')' '-' '>' type '{' 
    {
        Symbol funcSym($2, "function", $8);
        for(const auto& p : tempParams) funcSym.paramTypes.push_back(p.type);
        currentScope->addSymbol(funcSym);
        
        SymbolTable* funcScope = new SymbolTable("Function " + string($2), currentScope);
        allTables.push_back(funcScope);
        currentScope = funcScope;
        
        for(auto& p : tempParams) currentScope->addSymbol(p);
        tempParams.clear();
    }
    func_body '}'
    {
        currentScope = currentScope->parentScope;
    }
    ;

param_list: param_list ',' param | param | /* empty */ ;
param: ID ':' type { Symbol s($1, "parameter", $3); tempParams.push_back(s); };

func_body: local_vars func_body_statements ;
local_vars: local_vars var_decl | /* empty */ ;

func_body_statements:
    func_body_statements statement { if ($2) $1->addStatement($2); $$ = $1; }
    | /* empty */ { $$ = new BlockNode(); }
    ;

/* Blocul Main */
main_block: MAIN '{' statement_list '}' { $$ = $3; } ;

statement_list:
    statement_list statement { if ($2) $1->addStatement($2); $$ = $1; }
    | /* empty */ { $$ = new BlockNode(); }
    ;

/* --- INSTRUCTIUNI --- */
statement:
    assignment ';' { $$ = $1; }
    | function_call ';' { $$ = $1; }
    
    // Incrementare / Decrementare ca statement (i++;)
    | ID INC ';' 
    { 
        if (currentScope->isSymbolConst($1)) { cerr << "Err: Const " << $1 << " modificata!" << endl; exit(1); }
        $$ = new UnaryNode("++", new IdNode($1, "int"), "int"); 
    }
    | ID DEC ';' 
    { 
        if (currentScope->isSymbolConst($1)) { cerr << "Err: Const " << $1 << " modificata!" << endl; exit(1); }
        $$ = new UnaryNode("--", new IdNode($1, "int"), "int"); 
    }

    //Input/Output
    | PRINT '(' expression ')' ';' { $$ = new PrintNode($3); }
    | READ '(' ID ')' ';' 
    { 
        string t = currentScope->findSymbolType($3);
        if(t=="") { cerr<<"Error: Var "<<$3<<" undefined."<<endl; exit(1); }
        if(currentScope->isSymbolArray($3)) { cerr<<"Error: Cannot Read directly into array. Use index."<<endl; exit(1); }
        $$ = new ReadNode($3); 
    }

    //Control Flow
    | CHECK '(' expression ')' '{' statement_list '}' { $$ = new IfNode($3, $6); } 
    | LOOP '(' expression ')' '{' statement_list '}' { $$ = new WhileNode($3, $6); }
    /*iMPLEMENTARE FOR LOOP*/
    | FOR '(' assignment ';' expression ';' expression ')' '{' statement_list '}' 
    { 
        //Cream un bloc exterior care va contine initializarea + while-ul
        BlockNode* outerBlock = new BlockNode();

        //Adaugam initializarea (ex: i := 0)
        outerBlock->addStatement($3); 

        //Luam corpul buclei (statement_list)
        BlockNode* loopBody = $10;

        //Siguranta: daca corpul e gol, cream unul nou
        if (loopBody == nullptr) loopBody = new BlockNode();

        //Adaugam pasul de incrementare (ex: i++) LA FINALUL corpului
        loopBody->addStatement($7);

        //Cream nodul While (Conditie + Corp modificat)
        WhileNode* whileLoop = new WhileNode($5, loopBody);

        //Adaugam while-ul in blocul exterior
        outerBlock->addStatement(whileLoop);

        $$ = outerBlock;
    }
    
    | RETURN expression ';' { $$ = nullptr; } 
    ;

/*ATRIBUIRI*/
assignment:
    // 1. Variabila simpla: x := 5
    ID ASSIGN expression
    {
        string varType = currentScope->findSymbolType($1);
        if (varType == "") { cerr << "Err: " << $1 << " nedeclarat!" << endl; exit(1); }
        if (currentScope->isSymbolConst($1)) { cerr << "Err: " << $1 << " este CONST!" << endl; exit(1); }
        if (currentScope->isSymbolArray($1)) { cerr << "Err: " << $1 << " este array, foloseste index!" << endl; exit(1); }
        
        checkTypes(varType, $3->predictedType, "Assignment");
        $$ = new AssignNode($1, $3);
    }
    
    // 2. Element Vector: v[i] := 5
    | ID '[' expression ']' ASSIGN expression
    {
        if (!currentScope->isSymbolArray($1)) { cerr << "Err: " << $1 << " nu este vector!" << endl; exit(1); }
        // Tipul elementelor din array
        string arrType = currentScope->findSymbolType($1); 
        checkTypes(arrType, $6->predictedType, "Array Assignment");
        
        $$ = new ArrayAssignNode($1, $3, $6);
    }

    | SELF '.' ID ASSIGN expression { $$ = new AssignNode($3, $5); }
    | ID '.' ID ASSIGN expression { $$ = nullptr; } 
    ;

function_call:
    ID '(' arg_list ')' { $$ = nullptr; }
    | ID '.' ID '(' arg_list ')' { $$ = nullptr; }
    | SELF '.' ID '(' arg_list ')' { $$ = nullptr; }
    ;

arg_list: arg_list ',' expression | expression | /* empty */ ;

/*EXPRESII*/
expression:
    // Aritmetica
    expression '+' expression { checkTypes($1->predictedType,$3->predictedType,"+"); $$ = new BinaryNode("+", $1, $3, $1->predictedType); }
    | expression '-' expression { checkTypes($1->predictedType,$3->predictedType,"-"); $$ = new BinaryNode("-", $1, $3, $1->predictedType); }
    | expression '*' expression { checkTypes($1->predictedType,$3->predictedType,"*"); $$ = new BinaryNode("*", $1, $3, $1->predictedType); }
    | expression '/' expression { checkTypes($1->predictedType,$3->predictedType,"/"); $$ = new BinaryNode("/", $1, $3, $1->predictedType); }
    | expression '%' expression { $$ = new BinaryNode("%", $1, $3, "int"); }
    
    // Relational
    | expression '<' expression { $$ = new BinaryNode("<", $1, $3, "bool"); }
    | expression '>' expression { $$ = new BinaryNode(">", $1, $3, "bool"); }
    | expression LEQ expression { $$ = new BinaryNode("<=", $1, $3, "bool"); }
    | expression GEQ expression { $$ = new BinaryNode(">=", $1, $3, "bool"); }
    | expression EQ expression { $$ = new BinaryNode("==", $1, $3, "bool"); }
    | expression NEQ expression { $$ = new BinaryNode("!=", $1, $3, "bool"); }
    
    // Logic
    | expression AND expression { $$ = new BinaryNode("&&", $1, $3, "bool"); }
    | expression OR expression { $$ = new BinaryNode("||", $1, $3, "bool"); }
    
    // Unar
    | '-' expression %prec UMINUS { $$ = new UnaryNode("-", $2, $2->predictedType); }
    | '!' expression { $$ = new UnaryNode("!", $2, "bool"); }
    | ID INC { $$ = new UnaryNode("++", new IdNode($1, "int"), "int"); }
    | ID DEC { $$ = new UnaryNode("--", new IdNode($1, "int"), "int"); }

    // Elemente
    | '(' expression ')'        { $$ = $2; }
    
    // Identificator simplu: x
    | ID 
    { 
        string type = currentScope->findSymbolType($1);
        if (type == "") { cerr << "Err: " << $1 << " nedeclarat!" << endl; exit(1); }
        if (currentScope->isSymbolArray($1)) { cerr << "Err: " << $1 << " e array, lipseste index!" << endl; exit(1); }
        $$ = new IdNode($1, type);
    }
    
    // Acces Vector: v[i]
    | ID '[' expression ']' 
    {
        string type = currentScope->findSymbolType($1);
        if (!currentScope->isSymbolArray($1)) { cerr << "Err: " << $1 << " nu este vector!" << endl; exit(1); }
        $$ = new ArrayAccessNode($1, $3, type);
    }

    | SELF '.' ID { string type = currentScope->findSymbolType($3); $$ = new IdNode($3, type); }
    
    // Literali
    | INT_VAL     { $$ = new ConstNode(to_string($1), "int"); }
    | FLOAT_VAL   { char buff[32]; sprintf(buff, "%.2f", $1); $$ = new ConstNode(buff, "float"); }
    | STRING_VAL  { $$ = new ConstNode($1, "string"); }
    | BOOL_VAL    { $$ = new ConstNode($1, "bool"); }
    
    | function_call { $$ = nullptr; }
    ;

%%

void yyerror(const char *s) {
    cerr << "Syntax Error la linia " << yylineno << ": " << s << endl;
}

int main(int argc, char** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) { perror("Eroare deschidere fisier"); return 1; }
    }

    tempParams.clear();
    cout << "=== COMPILATOR START ===\n";
    
    if (yyparse() == 0) {
        ofstream outFile("tables.txt");
        if (outFile.is_open()) {
            for (SymbolTable* t : allTables) {
                t->printToFile(outFile);
            }
            outFile.close();
            cout << "Tabele salvate.\n";
        }
    }
    
    return 0;
}