# Entis

A custom interpreted programming language built in C++ using Flex and Bison. Entis features its own syntax, a full AST-based evaluator, scoped symbol tables, static type checking, and runtime error detection.

## Features

- **Custom syntax** — clean, descriptive keywords (`entity`, `action`, `check`, `loop`)
- **AST evaluation** — the interpreter builds and walks an Abstract Syntax Tree to execute code
- **Scoped symbol tables** — separate scopes for global, class, and function levels with proper lookup chaining
- **Static type checking** — type mismatches are caught at parse time
- **Constant support** — `const var` declarations enforced at both compile and runtime
- **Arrays** — fixed-size arrays with bounds checking
- **Runtime error detection** — division by zero, array out of bounds, use of undeclared variables
- **Two loop constructs** — `loop` (while) and `for`
- **Classes** — `entity` blocks with fields and methods
- **Functions** — `action` declarations with parameters and return types

## Requirements

- `gcc` / `g++`
- `flex`
- `bison`

On Ubuntu/Debian:
```bash
sudo apt install build-essential flex bison
```


## Build

```bash
make
```

This runs Bison and Flex to generate the parser and lexer, then compiles everything into the `my_compiler` executable.

To clean generated files and the binary:
```bash
make clean
```


## Usage

```bash
./my_compiler your_program.entis
```

The interpreter will execute the program and print output to stdout. A `tables.txt` file is generated after each run containing the full symbol table for all scopes.


## Language Syntax

### Variables & Constants

```
var x : int;
var name : string;
var pi : float;
const var MAX : int;
```

### Arrays

```
var v[10] : int;
v[0] := 42;
Print(v[0]);
```

### Assignment

Entis uses `:=` for assignment:
```
x := 5;
pi := 3.14;
name := "hello";
```

### Input & Output

```
Read(x);
Print(x);
Print("Hello, world!");
```

### Conditionals

```
check (x > 10) {
    Print("x is greater than 10");
}
```

### Loops

```
// while-style
loop (i < n) {
    i++;
}

// for-style
for (i := 0; i < n; i++) {
    Print(v[i]);
}
```

### Functions

```
action add(a : int, b : int) -> int {
    return a + b;
}
```

### Classes

```
entity Point {
    var x : int;
    var y : int;

    action getX() -> int {
        return self.x;
    }
}
```

### Comments

```
// single line comment

/* 
   multi-line comment
*/
```

---

## Supported Types

| Type | Description |
|---|---|
| `int` | Integer numbers |
| `float` | Floating point numbers |
| `bool` | `true` or `false` |
| `string` | Text values |
| `void` | Return type for functions with no return value |


## Operators

| Category | Operators |
|---|---|
| Arithmetic | `+` `-` `*` `/` `%` |
| Relational | `==` `!=` `<` `>` `<=` `>=` |
| Logical | `&&` `\|\|` `!` |
| Increment | `++` `--` |
| Assignment | `:=` |


## Example Programs

**Math & operator precedence** (`math.txt`):
```
var PI : float;
var raza : float;
var rezultat : float;

Main {
    PI := 3.14;
    raza := 10.0;
    rezultat := PI * raza * raza;
    Print("Circle area:");
    Print(rezultat);
}
```

**Arrays & loops** (`arrays_loops.txt`):
```
var n : int;
var i : int;
var suma : int;
var v[10] : int;

Main {
    Read(n);
    for (i := 0; i < n; i++) {
        Read(v[i]);
    }
    suma := 0;
    i := 0;
    loop (i < n) {
        suma := suma + v[i];
        i++;
    }
    Print(suma);
}
```

\
## Error Detection

Entis catches errors at three stages:

**Lexical** — unrecognized characters are reported with line number.

**Semantic** (at parse time):
- Type mismatch in expressions or assignments
- Use of undeclared variables
- Assignment to a `const` variable
- Assigning to an array without an index

**Runtime**:
- Division by zero
- Modulo by zero
- Array index out of bounds


## Project Structure

```
Entis/
├── lexer.l          # Flex lexer — tokenizes source code
├── parser.y         # Bison parser — grammar rules and semantic actions
├── ast.h            # AST node definitions and evaluator
├── symbol_table.h   # Symbol table with scoping and array support
├── Makefile         # Build rules
├── math.txt         # Example: arithmetic and operator precedence
├── arrays_loops.txt # Example: arrays, for loops, while loops
└── erori.txt        # Example: error detection test cases
```


## Roadmap

- [ ] `else` / `else if` branches for `check`
- [ ] Function calls with return values in expressions
- [ ] String built-in operations (length, substring)
- [ ] Multi-file support
- [ ] Bytecode compilation target


## License

MIT
