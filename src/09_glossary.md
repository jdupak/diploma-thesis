# Glossary
|  |  |
|------|------------|
| ABI | Application Binary Interface |
| 3-AD | Three Address Code |
| API | Application Programming Interface |
| AST | Abstract Syntax Tree |
| BIR | (gccrs) Borrow-Checker Intermediate Representation |
| CFG | Control Flow Graph |
| CLI | Command Line Interface |
| GCC | GNU Compiler Collection |
| GENERIC | (GCC) The internal representation used by GCC as an interface between the front-end and the middle-end of the compiler |
| GIMPLE | (GCC) The internal representation used by GCC in the middle-end of the compiler |
| HIR | (rustc, gccrs) High-level Intermediate Representation |
| IR | Intermediate Representation |
| LLVM | Low Level Virtual Machine |
| MIR | (rustc) Mid-level Intermediate Representation |
| MIRI | (rustc) The Rust MIR interpreter |
| NLL | (rustc) Non-Lexical Lifetimes (a CFG-based borrow-checker) |
| Polonius | The name of the new borrow-checker algorithm and engine |
| RAII | Resource Acquisition Is Initialization (C++ idiom) |
| RFC | Request For Comments (formal process for proposing changes to Rust) |
| SSA | Static Single Assignment |
| THIR | (rustc) Typed High-level Intermediate Representation |
| TyTy | (rustc, gccrs) Type Intermediate Representation (used after types are parsed and resolved) |
| basic block | A sequence of instructions with a single entry point and a single exit point |
| borrow | (Polonius) The act of taking a checked reference |
| fact | (Polonius) Information about the program, reduced to a relation between enumerated program objects |
| gccrs | GCC Rust Front-end |
| interning | The process of replacing a value with a unique identifier |
| loan | (Polonius) The result of a borrow operation (taking a checked reference). |
| origin | (Polonius) An inference variable that represents a set of loans. May be used interchangeably with *region*. |
| outlives | (Polonius) A relationship between two origins, where the first region must live longer than the second region. Denoted as `R1: R2` where `R1` outlives `R2`. That means that the set of CFG points R1 represents must be a superset of the set of CFG points R2 represents. |
| point | (Polonius) A point in the CFG |
| region | (Polonius/NLL) An inference variable that represents a set of points in the CFG. May be used interchangeably with *origin*. |
| rustc | The main Rust Compiler based on LLVM |
| usize | Unsigned integer type with the same size as a pointer in Rust |
