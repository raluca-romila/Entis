#ifndef AST_H
#define AST_H

#include <iostream>
#include <string>
#include <vector>
#include <cmath>
#include <cstdlib> 
#include "symbol_table.h"

using namespace std;

// STRUCTURA PENTRU REZULTATUL EVALUARII
struct EvalResult {
    string type; // "int", "float", "bool", "string"
    
    int iVal = 0;
    float fVal = 0.0;
    bool bVal = false;
    string sVal = "";

    // Helper pentru a determina daca rezultatul e "adevarat" (pentru if/while)
    bool isTrue() const {
        if (type == "bool") return bVal;
        if (type == "int") return iVal != 0;
        if (type == "float") return fVal != 0.0;
        return false;
    }
};

// CLASA DE BAZA ABSTRACTA 
class ASTNode {
public:
    string predictedType;
    virtual ~ASTNode() {}
    virtual EvalResult evaluate(SymbolTable* table) = 0;
};


// 1. NODURI PENTRU VALORI SI VARIABILE

// Nod pentru Constante (ex: 5, 3.14, "text")
class ConstNode : public ASTNode {
    string valStr;
public:
    ConstNode(string v, string t) : valStr(v) { predictedType = t; }

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult res;
        res.type = predictedType;
        try {
            if (res.type == "int") res.iVal = stoi(valStr);
            else if (res.type == "float") res.fVal = stof(valStr);
            else if (res.type == "bool") {
                res.bVal = (valStr == "true" || valStr == "1");
            }
            else res.sVal = valStr;
        } catch (...) {
            res.iVal = 0; 
        }
        return res;
    }
};

// Nod pentru Identificatori (Variabile simple: x, a, suma)
class IdNode : public ASTNode {
public: 
    string name; // Public pentru acces din UnaryNode (++)
    
    IdNode(string n, string t) : name(n) { predictedType = t; }

    EvalResult evaluate(SymbolTable* table) override {
        if (!table) { cerr << "Eroare critica: Tabela NULL." << endl; exit(1); }
        
        string valFromTable = table->getValue(name);
        EvalResult res;
        res.type = predictedType;
        
        try {
            if (res.type == "int") res.iVal = stoi(valFromTable);
            else if (res.type == "float") res.fVal = stof(valFromTable);
            else if (res.type == "bool") res.bVal = (valFromTable == "true" || valFromTable == "1");
            else res.sVal = valFromTable;
        } catch (...) {
            res.iVal = 0; res.fVal = 0.0; res.bVal = false;
        }
        return res;
    }
};

// 2. NODURI PENTRU OPERATII

// Nod Binar (+, -, *, /, %, <, >, ==, &&, ||)
class BinaryNode : public ASTNode {
    string op;
    ASTNode *left, *right;
public:
    BinaryNode(string oper, ASTNode* l, ASTNode* r, string resType) 
        : op(oper), left(l), right(r) { predictedType = resType; }

    EvalResult evaluate(SymbolTable* table) override {
        if (!left || !right) return EvalResult();

        EvalResult l = left->evaluate(table);
        EvalResult r = right->evaluate(table);
        EvalResult res;
        res.type = predictedType;

        //CONCATENARE STRING-URI 
        if (op == "+") {
            if (res.type == "string") {
                string s1 = (l.type == "string") ? l.sVal : to_string(l.iVal); // Simplificare: doar int la string
                string s2 = (r.type == "string") ? r.sVal : to_string(r.iVal);
                res.sVal = s1 + s2;
                return res;
            }
            // Aritmetica normala
            if (res.type == "int") res.iVal = l.iVal + r.iVal;
            else res.fVal = (l.type=="int"?l.iVal:l.fVal) + (r.type=="int"?r.iVal:r.fVal);
        }
        else if (op == "-") {
            if (res.type == "int") res.iVal = l.iVal - r.iVal;
            else res.fVal = (l.type=="int"?l.iVal:l.fVal) - (r.type=="int"?r.iVal:r.fVal);
        }
        else if (op == "*") {
            if (res.type == "int") res.iVal = l.iVal * r.iVal;
            else res.fVal = (l.type=="int"?l.iVal:l.fVal) * (r.type=="int"?r.iVal:r.fVal);
        }
        else if (op == "/") {
             float div = (r.type=="int"?r.iVal:r.fVal);
             
             // CHECK: IMPARTIRE LA ZERO
             if (div == 0.0f) { 
                 cerr << "RUNTIME ERROR: Division by zero!" << endl; 
                 exit(1); 
             }
             
             if (res.type == "int") res.iVal = (int)((l.type=="int"?l.iVal:l.fVal) / div);
             else res.fVal = (l.type=="int"?l.iVal:l.fVal) / div;
        }
        else if (op == "%") {
            int val1 = (l.type == "int" ? l.iVal : (int)l.fVal);
            int val2 = (r.type == "int" ? r.iVal : (int)r.fVal);
            if (val2 == 0) { cerr << "Runtime Error: Modulo by zero!" << endl; exit(1); }
            res.iVal = val1 % val2;
            res.type = "int"; 
        }
        
        else if (op == "<")  res.bVal = (l.type=="int"?l.iVal:l.fVal) <  (r.type=="int"?r.iVal:r.fVal);
        else if (op == ">")  res.bVal = (l.type=="int"?l.iVal:l.fVal) >  (r.type=="int"?r.iVal:r.fVal);
        else if (op == "<=") res.bVal = (l.type=="int"?l.iVal:l.fVal) <= (r.type=="int"?r.iVal:r.fVal);
        else if (op == ">=") res.bVal = (l.type=="int"?l.iVal:l.fVal) >= (r.type=="int"?r.iVal:r.fVal);
        else if (op == "==") res.bVal = (l.type=="int"?l.iVal:l.fVal) == (r.type=="int"?r.iVal:r.fVal);
        else if (op == "!=") res.bVal = (l.type=="int"?l.iVal:l.fVal) != (r.type=="int"?r.iVal:r.fVal);

        else if (op == "&&") res.bVal = l.isTrue() && r.isTrue();
        else if (op == "||") res.bVal = l.isTrue() || r.isTrue();

        return res;
    }
};

// Nod Unar (Minus, Negatie !, Increment ++, Decrement --)
class UnaryNode : public ASTNode {
    string op;
    ASTNode* operand;
public:
    UnaryNode(string op, ASTNode* operand, string type) 
        : op(op), operand(operand) {
        this->predictedType = type;
    }

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult res = operand->evaluate(table);

        // Operatori care modifica variabila (++ / --)
        if (op == "++" || op == "--") {
             IdNode* idNode = dynamic_cast<IdNode*>(operand);
             if(idNode) {
                 if (res.type == "int") {
                     if (op == "++") res.iVal++; else res.iVal--;
                     table->updateValue(idNode->name, to_string(res.iVal));
                 } else if (res.type == "float") {
                     if (op == "++") res.fVal += 1.0f; else res.fVal -= 1.0f;
                     table->updateValue(idNode->name, to_string(res.fVal));
                 }
                 return res; 
             }
        }
        
        // Operatori clasici
        if (op == "-") {
            if (res.type == "int") res.iVal = -res.iVal;
            else if (res.type == "float") res.fVal = -res.fVal;
        }
        if (op == "!") {
            res.type = "bool";
            res.bVal = !res.isTrue();
        }
        
        return res;
    }
};

// 3. NODURI PENTRU VECTORI 

// Accesare element vector: v[i]
class ArrayAccessNode : public ASTNode {
    string name;
    ASTNode* indexExpr;
public:
    ArrayAccessNode(string n, ASTNode* idx, string t) : name(n), indexExpr(idx) { predictedType = t; }

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult idxRes = indexExpr->evaluate(table);
        if (idxRes.type != "int") {
            cerr << "RUNTIME ERROR: Array index must be int!" << endl; exit(1);
        }
        
        // Apelam SymbolTable pentru a lua valoarea de la index
        string val = table->getArrayValue(name, idxRes.iVal);
        
        EvalResult res; res.type = predictedType;
        try {
            if (res.type == "int") res.iVal = stoi(val);
            else if (res.type == "float") res.fVal = stof(val);
            else if (res.type == "bool") res.bVal = (val == "1");
            else res.sVal = val;
        } catch (...) { res.iVal = 0; }
        return res;
    }
};

// Atribuire element vector: v[i] := 5
class ArrayAssignNode : public ASTNode {
    string name;
    ASTNode* indexExpr;
    ASTNode* valExpr;
public:
    ArrayAssignNode(string n, ASTNode* idx, ASTNode* val) 
        : name(n), indexExpr(idx), valExpr(val) {}

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult idxRes = indexExpr->evaluate(table);
        EvalResult valRes = valExpr->evaluate(table);

        if (idxRes.type != "int") {
            cerr << "RUNTIME ERROR: Indexul vectorului trebuie sa fie int!" << endl; exit(1);
        }

        string strVal;
        if (valRes.type == "int") strVal = to_string(valRes.iVal);
        else if (valRes.type == "float") strVal = to_string(valRes.fVal);
        else if (valRes.type == "bool") strVal = valRes.bVal ? "1" : "0";
        else strVal = valRes.sVal;

        // Updatam valoarea in Symbol Table
        table->updateArrayValue(name, idxRes.iVal, strVal);
        return valRes;
    }
};

// 4. NODURI PENTRU INTRARE / IESIRE

// Read(var) 
class ReadNode : public ASTNode {
    string varName;
public:
    ReadNode(string name) : varName(name) {}

    EvalResult evaluate(SymbolTable* table) override {
        // Verificam existenta variabilei
        string type = table->findSymbolType(varName);
        if (type == "") { cerr << "RUNTIME ERROR: Read into undefined variable " << varName << endl; exit(1); }

        // Prompt simplu pentru utilizator
        cout << "Input (" << varName << "): ";
        string inputVal;
        cin >> inputVal; 

        // Actualizam variabila
        table->updateValue(varName, inputVal);
        return EvalResult();
    }
};

// Print(expr)
class PrintNode : public ASTNode {
    ASTNode* expr;
public:
    PrintNode(ASTNode* e) : expr(e) {}

    EvalResult evaluate(SymbolTable* table) override {
        if (!expr) return EvalResult();
        
        EvalResult res = expr->evaluate(table);
        cout << "[OUTPUT] ";
        if (res.type == "int") cout << res.iVal;
        else if (res.type == "float") cout << res.fVal;
        else if (res.type == "bool") cout << (res.bVal ? "true" : "false");
        else cout << res.sVal;
        cout << endl;
        
        return res;
    }
};

// 5. NODURI DE CONTROL SI ATRIBUIRE

// Assign simplu: x := 5
class AssignNode : public ASTNode {
    string name;
    ASTNode* expr;
public:
    AssignNode(string n, ASTNode* e) : name(n), expr(e) {}

    EvalResult evaluate(SymbolTable* table) override {
        if (!expr) return EvalResult();

        EvalResult res = expr->evaluate(table);
        string strVal;
        
        if (res.type == "int") strVal = to_string(res.iVal);
        else if (res.type == "float") strVal = to_string(res.fVal);
        else if (res.type == "bool") strVal = res.bVal ? "1" : "0";
        else strVal = res.sVal;

        table->updateValue(name, strVal);
        return res;
    }
};

// Check (IF)
class IfNode : public ASTNode {
    ASTNode* condition;
    ASTNode* trueBlock;
public:
    IfNode(ASTNode* cond, ASTNode* blk) : condition(cond), trueBlock(blk) {}

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult res = condition->evaluate(table);
        if (res.isTrue()) {
            return trueBlock->evaluate(table);
        }
        return EvalResult();
    }
};

// Loop (WHILE)
class WhileNode : public ASTNode {
    ASTNode* condition;
    ASTNode* body;
public:
    WhileNode(ASTNode* cond, ASTNode* b) : condition(cond), body(b) {}

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult lastRes;
        while (condition->evaluate(table).isTrue()) {
            lastRes = body->evaluate(table);
        }
        return lastRes;
    }
};

// Block (Lista de instructiuni {...})
class BlockNode : public ASTNode {
public:
    vector<ASTNode*> statements;
    
    void addStatement(ASTNode* stmt) {
        if (stmt != nullptr) {
            statements.push_back(stmt);
        }
    }

    EvalResult evaluate(SymbolTable* table) override {
        EvalResult last;
        for (ASTNode* s : statements) {
            if (s) last = s->evaluate(table);
        }
        return last;
    }
};

#endif