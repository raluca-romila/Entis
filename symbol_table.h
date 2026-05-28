#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <algorithm>

using namespace std;

struct Symbol {
    string name;
    string kind;        
    string type;        
    string value;       
    bool isConst;       
    

    bool isArray;
    int arraySize;
    map<int, string> arrayValues; // Stocheaza valorile: index -> valoare
    
    vector<string> paramTypes; 

    Symbol() : isConst(false), isArray(false), arraySize(0) {} 

    Symbol(string n, string k, string t, string v = "", bool constant = false) 
        : name(n), kind(k), type(t), value(v), isConst(constant), isArray(false), arraySize(0) {}
};

class SymbolTable {
public:
    string scopeName;           
    SymbolTable* parentScope;   
    map<string, Symbol> symbols; 

    SymbolTable(string name, SymbolTable* parent = nullptr) 
        : scopeName(name), parentScope(parent) {}

    void addSymbol(Symbol s) {
        if (symbols.find(s.name) != symbols.end()) {
            cerr << "SEMANTIC ERROR: Variabila '" << s.name << "' este deja definita!" << endl;
            exit(1);
        }
        symbols[s.name] = s;
    }

    Symbol* findSymbol(string name) {
        if (symbols.find(name) != symbols.end()) return &symbols[name];
        if (parentScope != nullptr) return parentScope->findSymbol(name);
        return nullptr;
    }

    string findSymbolType(string name) {
        Symbol* s = findSymbol(name);
        if (s) return s->type;
        return "";
    }

    bool isSymbolConst(string name) {
        Symbol* s = findSymbol(name);
        if (s) return s->isConst;
        return false;
    }
    
    // Verificam daca e array pentru validari semantice
    bool isSymbolArray(string name) {
        Symbol* s = findSymbol(name);
        if (s) return s->isArray;
        return false;
    }

    // Update Variabila Simpla
    void updateValue(string name, string val) {
        Symbol* s = findSymbol(name);
        if (s) s->value = val;
        else cerr << "RUNTIME ERROR: Variabila " << name << " inexistenta." << endl;
    }

    // Get Variabila Simpla
    string getValue(string name) {
        Symbol* s = findSymbol(name);
        if (s) return s->value.empty() ? "0" : s->value;
        return "0"; 
    }

    // Runtime pt vectori
    
    void updateArrayValue(string name, int index, string val) {
        Symbol* s = findSymbol(name);
        if (s == nullptr) {
            cerr << "RUNTIME ERROR: Array '" << name << "' nedeclarat." << endl; exit(1);
        }
        if (!s->isArray) {
            cerr << "RUNTIME ERROR: '" << name << "' nu este un vector!" << endl; exit(1);
        }
        if (index < 0 || index >= s->arraySize) {
            cerr << "RUNTIME ERROR: Array Index Out of Bounds! Acces la index " << index 
                 << ", dar marimea este " << s->arraySize << "." << endl; exit(1);
        }
        s->arrayValues[index] = val;
    }

    string getArrayValue(string name, int index) {
        Symbol* s = findSymbol(name);
        if (s == nullptr) { cerr << "Err: " << name << " not found." << endl; exit(1); }
        
        if (index < 0 || index >= s->arraySize) {
            cerr << "RUNTIME ERROR: Array Index Out of Bounds!" << endl; exit(1);
        }
        
        // Daca nu a fost initializat inca indexul, returnam 0
        if (s->arrayValues.find(index) == s->arrayValues.end()) return "0";
        return s->arrayValues[index];
    }

    void printToFile(ofstream& file) {
        file << "=== Symbol Table: " << scopeName << " ===" << endl;
        file << "Name\t| Kind\t| Type\t| Const\t| Array?\t| Value/Size" << endl;
        file << "--------------------------------------------------------" << endl;
        for (auto const& [key, val] : symbols) {
            file << val.name << "\t| " << val.kind << "\t| " << val.type << "\t| " 
                 << (val.isConst ? "YES" : "NO") << "\t| "
                 << (val.isArray ? "YES" : "NO") << "\t\t| ";
            
            if (val.isArray) file << "Size: " << val.arraySize;
            else file << val.value;
            file << endl;
        }
        file << endl;
    }
};

#endif