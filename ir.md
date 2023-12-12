# Structure

## Borrow-checking

### Lexical borrow-checking

### Non-lexical borrow-checking

### Polonius

## IR comparison

## Gccrs borrow-checker design

### BIR

### BIR building

### TyTy Generic types

#### Variance analysys

### BIR fact collection and checking

Building a borrow-checker consists of two main parts.
First, we need to extract information about the program.
We will call that information *facts*.
(This follows the terminology used by Polonius [link polonius book/facts]().)
Second, we need to use those facts to check the program.

To understand how facts are extracted in gccrs and rustc, we need to understand how programs are represented in each compiler.

## GCC vs LLVM

To understand the differences between gccrs and rustc, we must first explore the differences of the compiler platforms they are built
on (GCC and LLVM).
We will only focus on the middle-end of each compiler platform, since the back-end is not relevant to borrow-checking.

The core of LLVM is a three-address code (3-AD) [^](Three-address code represents the program as a sequence of statements (we call such sequence a
*basic block*), connected by control flow instructions, forming a control flow graph (CFG).) representation called the LLVM intermediate
representation (LLVM IR) [https://llvm.org/docs/Reference.html#llvm-ir].
This IR is the interface between front-ends and the compiler platform (the middle-end and the back-end). Each front-end is responsible for
transforming its AST into the LLVM IR.
The LLVM IR is stable and strictly separated from the front-end.

![LLVM IR CFG (Compiler Explorer)](./llvm-ir-cfg-example.svg)

[//]: # (TODO: picture)

GCC, on the other hand, interfaces with the front-ends on a tree-based representation called the
GENERIC [#](https://gcc.gnu.org/onlinedocs/gccint/GENERIC.html).
GENERIC was created generalized form of AST shared by most front-ends.
GCC provides a set of common tree nodes to describe all the common language constructs in the GENERIC IR.
Front-ends may define language-specific constructs and provide hooks for their
handling. [#](gccint:212)[#](https://gcc.gnu.org/onlinedocs/gccint/Language-dependent-trees.html)
This representation is then transformed into a GIMPLE representation [#](https://gcc.gnu.org/onlinedocs/gccint/GIMPLE.html), which is a mostly[^]("
GIMPLE that is not fully lowered is
known as “High GIMPLE” and consists of the IL before the pass pass_lower_cf. High
GIMPLE contains some container statements like lexical scopes (represented by GIMPLE_
BIND) and nested expressions (e.g., GIMPLE_TRY), while “Low GIMPLE” exposes all of the
implicit jumps for control and exception expressions directly in the IL and EH region trees." [#](gccint:225)) 3-AD
representation, by breaking down expression into a sequence of statements, introducing temporary variables.
This transformation is done inside the compiler platform, not in the front-end.
This approach allows the front-ends to be smaller and shifting more works into the shared part.
GIMPLE representation does not contain information specific to each front-end (programming language).
It is only possible to add completely new statements.
[#](gccint:262) This is possible, because GIMPLE is not a stable interface.

The key takeaway is that rustc has to transform the tree-based representation into a 3-AD representation itself.
That means that it has access to the control flow graph (CFG) of the program.
This is not the case for gccrs.
In GCC, the CFG is only available in the Low GIMPLE representation, deep inside the middle-end.

## Rustc's representation

```rust
struct Foo(i32);

fn foo(x: i32) -> Foo {
    Foo(x)
}
```

> This very simple code will be used as an example throughout this section.

In the previous section, we have seen that rustc is responsible for transforming the code all the way from the raw text to the LLVM IR.
Given the high complexity of the Rust language, rustc uses multiple intermediate representations (IR) to simplify the process.
The text is first tokenized and parsed into the abstract syntax tree (AST),
which is then transformed into the high-level intermediate representation (HIR).
For transformation into a middle-level intermediate representation (MIR), the HIR is first transformed into a typed HIR (THIR).
The MIR is then transformed into the LLVM IR.

AST is a tree-based representation of the program, which closely follows each token in the source code.
At this stage, rustc performs macro-expansion and a partial name resolution (macros and
imports) [https://rustc-dev-guide.rust-lang.org/macro-expansion.html, https://rustc-dev-guide.rust-lang.org/name-resolution.html].
As the AST is lowered to HIR, some complex language constructs are desuggared to simpler constructs.
For example,
various kinds of loops are transformed to a single infinite loop construct
(Rust `loop` keyword) and many structures that can perform pattern matching (`if let`, `while let`, `?` operator) are transformed to a `match`
construct.

```
Fn {
  generics: Generics { ... },
  sig: FnSig {
    header: FnHeader { ... },
      decl: FnDecl {
        inputs: [
          Param {
            ty: Ty { Path { segments: [ PathSegment { ident: i32#0 } ] } },
            pat: Pat { Ident(x#0) }
          },
        ],
        output: Ty { Path { segments: [ PathSegment { ident: Foo#0 } ] }
      },
  },
  body: Block {
    stmts: [ Stmt { Expr {
      Call(
        Expr { Path { segments: [ PathSegment { ident: Foo#0 } ] } },
        params: [
          Expr { Path { segments: [ PathSegment { ident: x#0 } ] } }
        ]
      )
    ]
  }
}
```

> This is a textual representation of a small and simplified part of the abstract syntax tree (AST) of the example program.

HIR is the main representation used for most rustc operations [https://rustc-dev-guide.rust-lang.org/hir.html].
It combines a simplified version of the AST with additional tables and maps for quick access to information.
For example, those tables contain information about the types of expressions and statements.
Those are used for analysis passes, like full (late) resolution and typechecking.
The typechecking process, which includes both checking the type correctness of the program as well as the type inference and resolution of implicit
langugage constructs.
[#](https://rustc-dev-guide.rust-lang.org/type-checking.html)

```
#[prelude_import]
use ::std::prelude::rust_2015::*;
#[macro_use]
extern crate std;
struct Foo(i32);

fn foo(x: i32) -> Foo { Foo(x) }
```

> **One of HIR dump formats:**
> HIR structure still corresponds to a valid Rust program, equivalent to the original one. rustc provides a textual representation of HIR, which is
> displays such program.

The HIR representation can contain many placeholders and "optional" fields that are resolved during the HIR analysis.
To simplify further processing, parts of HIR that correspond to executable code (e.g. not type definitions) are transformed into THIR
(Typed High-Level Intermediate Representation) where all the missing informaion (mainly types) must be resolved.
The reader can think about HIR and THIR in terms of the builder pattern [https://en.wikipedia.org/wiki/Builder_pattern],
where HIR provides flexible interface for modification and THIR the final immutable representation
This does not only involve the data explicitly stored in HIR, but also parts of the program, that are implied from the type system.
Operator overloading, automatic references and dereferences, etc. are all resolved at this stage.

The final rustc IR that is lowered directly to LLVM IR is the MIR (Mid-level Intermediate Representation).
We will pay extra attention to MIR because it is the main representation used by the borrow-checker.
MIR is a three-address code representation, similar to LLVM IR but with Rust specific constructs.
It consists of basic blocks, which are sequences of statements connected by control flow instructions.
The statements operate on places and rvalues. A place (often called lvalue in other languages) is an abstract representation of a memory location.
It is either a local variable, a field, index or dereference of another place.

MIR contains information about types, including lifetimes.
It differentiates pointers and references, as well as mutable and immutable references.
It is aware of panics and stack unwinding.
It contains additional information for borrow-checker, like storage live/dead annotations,
which denote when a place is first used or last used, and false operations which help with the analysis.
For example, a false unwind operation inside infinite loops, to ensure that there is an exit edge in the CFG.
This can be critical for algorithms, that process the CFG in reverse order.

```
fn foo(_1: i32) -> Foo {
    debug x => _1;
    let mut _0: Foo;	

    bb0: {
        _0 = Foo(_1);
        return;
    }
}
```

> **MIR dump example**

For further details, see the [Source Code Representation]() chapter of the rustc developer guide.

# Rust GCC Borrow-checker Design

> This section discusses the intermediate representation in gccrs. Since gccrs is a second implementation of the Rust compiler, it is heavily inspired
> by rustc. Therefore this section will assume familiarity with rustc's intermediate representations, described in the previous section. We will focus
> on similarities and differences between rustc and gccrs, rather than describing the gccrs intermediate representation in detail.

The Rust GCC borrow-checker is designed to be as similar to the `rustc` borrow-checker as possible withing the constraints of the Rust GCC IR.
This allows us to leverage the existing knowledge about borrow-checking in Rust.
The differences between the IR and the challenges they pose are discussed in the previous chapter.
The main decision of the Rust GCC borrow-checker is to reuse the dataflow analysis engine from rustc.
The interface between the analysis engine and the compiler consist of passing a set of facts to the analysis engine.

Ever since the introduction of NLL in rustc, the analysis is control-flow sensitive.
This requires us to collect the required facts from a control-flow graph based IR which still contains rust specific information.

We need to distinguish between pointers (in unsafe Rust) and references.
Pointer is not subject to borrow-checking, but references are.
Furthermore, we need to distinguish between mutable and immutable references, since they have different rules, essential for borrow-checking
[^](The key rule of borrowchecking is the for a single borrowed variable,
there can only be a single mutable borrow, or only immutable borrows valid at each point of the CFG.).
Each type has to carry information about lifetimes it contains and their variances.
For explicit user type annotation, we need to store the explicit lifetime parameters.

The only IR in GCC what contains the CFG information is GIMPLE; however, under normal circumstances GIMPLE is supposed to be language agnostic.
It is possible to annotate the GIMPLE statements with language specific information,
using special statements [quote Jan Hubicka consulations], however it is very complicated.

Initially, we have attempted to collect the information from HIR and compute and approximate CFG as we go.
This can work nicely for simple language constructs,
that are local, but its get very compicated for more complex constructs like patterns,
loops with breaks and continues, etc. Further more, it was not clear, how to handle panics and unwinding.
An option to ease such problems was to radically desuggar the HIR to only basic constructs.
An advantage of this approach would be that it would leverage the code already existing in the code generator,
possibly making the code generation easier.
The most extreme case would be to add rustc's MIR to gccrs.
This approached as some advantages and many problems.
The main advange for borrow-checking is that the process of lowering HIR to MIR would be covered by the current testsuite.
Another advantage, if full compatibility with rustc's MIR is achieved, is that many MIR based tools (like MIRI) could be used with gccrs.
Also the borrow-checking itself would be very similar to rustc's borrow-checking.
The main problem with this approach is that it would require a large portion of gccrs to be reimplemented,
delaying the project by a considerable amount of time.
Should such an approach be taken, any effort on borrow-checking would be delayed until the MIR is implemented.
It was decided by the maintainers that such an approach is not feasible and that gccrs will not use MIR in any forseable future.
The effort to lift the HIR simplification done in the code generator to a HIR-to-HIR simplification pass was also abandoned, due to high reliace of
such passes on the GENERIC API. After further discussion with the maintainers, it was decided that the best apporach is to duplicate the work and
possibly unify it later. After Arthur Cohen suggesting to keep the things simple, I have decided to experiment with another apporoach. To build a
extremply simplified MIR-like IR, that keeps only the bare minimum of information needed for borrow-checking. Given unexpected productivity of this
approach, it was decided to go on with it.
This IR, later called the borrow-checker IR (BIR), only focuses on flow of data and it ignores the actual operations on the data.
The main disadvantage of this approach is that it creates a dead branch of the compilation pipeline,
that is not used for code generation and therefore it is not covered by the existing testsuite.
To overcome this difficulty, the BIR and it's textual representatio (dump) is designed to be as similar to rustc's MIR as possible.
This allows us to check the generated BIR againts the MIR generated by rustc, at least for simple programs.

## BIR Dump Example

An example program calculating the i-th fibonacci number:

```rust

fn fib(i: usize) -> i32 {
    if i == 0 || i == 1 {
        1
    } else {
        fib(i - 1) + fib(i - 2)
    }
}
```

Here is an example of BIR dump (note: this needs to be updated regularly):

```
fn fib(_1: usize) -> i32 {
    let _0: i32;
    let _2: i32;
    let _3: bool;
    let _4: bool;
    let _5: bool;
    let _6: usize;
    let _7: i32;
    let _8: usize;
    let _9: i32;
    let _10: i32;

    bb0: {
        _4 = Operator(_1, const usize);
        switchInt(_4) -> [bb1, bb2];
    }

    bb1: {
        _3 = const bool;
        goto -> bb3;
    }

    bb2: {
        _5 = Operator(_1, const usize);
        _3 = _5;
        goto -> bb3;
    }

    bb3: {
        switchInt(_3) -> [bb4, bb7];
    }

    bb4: {
        _2 = const i32;
        goto -> bb8;
    }

    bb5: {
        _6 = Operator(_1, const usize);
        _7 = Call(fib)(_6, ) -> [bb6];
    }

    bb6: {
        _8 = Operator(_1, const usize);
        _9 = Call(fib)(_8, ) -> [bb7];
    }

    bb7: {
        _10 = Operator(_7, _9);
        _2 = _10;
        goto -> bb8;
    }

    bb8: {
        _0 = _2;
        return;
    }
}


```

The dump consists of:

- A function header with arguments: `fn fib(_1: usize) -> i32 { ... }`.
- Declaration of locals: `let _0: i32;`, where `_0` is the return value (even if it is of the unit type). Arguments are not listed here, they are
  listed in the function header.
- A list of basic blocks: `bb0: { ... }`. The basic block name is the `bb` prefix followed by a number.
- Each basic block consists of a list of BIR statements. Instruction can be either assigned to a local (place) or be a statement.
  Instructions take locals (places) as arguments.
- Each basic block is terminated with a control flow instruction followed by a list of destinations:
    - `goto -> bb3;` - a goto instruction with a single destination.
    - `switchInt(_3) -> [bb4, bb7];` - a switch instruction with multiple destinations.
    - `return;` - a return instruction with no destinations.
    - `Call(fib)(_6, ) -> [bb6];` - a call instruction with a single destination. This section is prepared for panic handling.

## BIR Structure

BIR structure is defined in `gcc/rust/checks/errors/borrowck/rust-bir.h`. It is heavily inspired by rustc's MIR. The main difference is that BIR
drastically reduces the amount of information carried to only borrow-checking relevant information.

As borrow-checking is performed on each function independently, BIR represents a single function (`struct Function`). A `Function` consists of a list
of basic blocks, list of arguments (for dump only) and place database, which keeps track of locals.

### Basic Blocks

A basic block is identified by its index in the function's basic block list.
It contains a list of BIR statements and a list of successor
basic block indices in CFG.

### BIR Statements

BIR statements are of three categories:

- An assignment of an expression to a local (place).
- A control flow operation (switch, return).
- A special statement (not executable), which carries additional information for borrow-checking (`StorageDead`, `StorageLive`).

#### Expressions

Expressions represent the executable parts of the rust code. Many different Rust contracts are represented by a single expression, as only data (and
lifetime) flow needs to be tracked.

- `InitializerExpr` represents any kind of struct initialization. It can be either explicit (struct expression) or implicit (range expression,
  e.g. `0..=5`).
- `Operator<ARITY>` represents any kind of operation, except the following, where special information is needed either for borrow-checking or for
  better debugging.
- `BorrowExpr` represents a borrow operation.
- `AssignmentExpr` holds a place for an assignment statement (i.e., no operation is done on the place, it is just assigned).
- `CallExpr` represents a function call.
    - For functions, the callable is represented by a constant place (see below). (E.i. all calls use the same constant place.)
    - For closures and function pointers, the callable is represented by a (non-constant) place.

### Places

Places are defined in `gcc/rust/checks/errors/borrowck/rust-bir-place.h`.

Places represent locals (variables), their field, and constants. They are identified by their index (`PlaceId`) in the function's place database. For
better dump correspondence to MIR, constants use a different index range.

Non-constant places are created according to Polonius path [documentation](https://rust-lang.github.io/polonius/rules/atoms.html). The following
grammar describes
possible path elements:

```
Path = Variable
     | Path "." Field // field access
     | Path "[" "]"   // index
     | "*" Path
```

It is important to highlight that different fields are assigned to different places; however, all indices are assigned to the same place.
Also, to match the output of rustc.
In dump, paths contain at most one dereference and are split otherwise.
Same paths always result in the same place.

Variables are identified by `AST` `NodeId`. Fields indexes are taken from `TyTy` types.

Each place holds indices to its next relatives (in the path tree), `TyTy` type, lifetime and information whether the type can be copies or it needs to
be moved. Not that unlike rustc, we copy any time we can (for simplicity), while rustc prefers to move if possible (only a single copy is held).

## Generic types

Generic types impose some additional changes to the borrow-checker.
Generic types are generic over both types and lifetimes (and constants, but that fact is not important for the borrow-checker).
Types substituted for type parameters can again be generic, creating a structure known as higher-kinded lifetimes.
The Rust language subtyping rules allow types with different lifetimes to be coerced to each other.
This coercion has to follow the variance rules.
The lifetimes can be substituted in different contexts, leading a different

### Rust Language Subtyping Rules

The Rust language subtyping rules are defined in the [the reference](https://doc.rust-lang.org/reference/subtyping.html).
Unlike other languages, which are based on the OOP principles,
Rust is very explicit about type conversions and therefore leaving a very little space for subtyping. "Subtyping is restricted to two cases: variance
with respect to lifetimes and between types with higher ranked lifetimes.".

### Variance analysis

Variance analysis is a process of determining the variance of type and lifetime generic parameters.
"
F<T> is covariant over T if T being a subtype of U implies that F<T> is a subtype of F<U> (subtyping "passes through")
F<T> is contravariant over T if T being a subtype of U implies that F<U> is a subtype of F<T>
F<T> is invariant over T otherwise (no subtyping relation can be derived)
"

Let us see what that means on example specific to lifetimes.
For a simple reference type `&'a T`, the lifetime parameter `'a` is covariant. That's means that if we have a reference `&'a T` and we can coerce it
to
`&'b T`, then `'a` is a subtype of `'b`.
In other words, if we are storing a reference to some memory, it is sound to assign it to a reference which lives for a shorter period of time.
That is, if it is save to dereference a reference withing any point of period `'a`,
it is also safe to dereference it within any point of period `'b`, which is a subset of `'a` [^](Subset of CFG points.).
The situation is different when we pass a reference to a function as an argument. In that case, the lifetime parameter is contravariant.

For function parameter, we need to ensure that the parameter lives as long as the function needs it to.
If we have a function pointer of type `fn foo<'a>(x: &'a T)`, we can coerce it to `fn foo<'b>(x: &'b T)`, where `'b` lives longer than `'a`.

Let us look at that visually.
In the following code, we have region `'a` where it is save to reference the storage of `x`,
and region `'b` where it is save to reference the storage of `y`.
If a function will safely work with a reference of lifetime `'b` it will also safely work with a reference of lifetime `'a`.
Hence, we can "pretend" (understand: coerce) what `fn(&'b T)` is `fn(&'a T)`.

```rust
let x = 5;        | region 'a
{                 |
    let y = 7;    |             | region 'b          
}                 |
```

The return type of a function is effectively an assignment to a local variable (just accross function boundaries), and therefore is covariant.

The situation gets integresting, when there two rules re combined.
Let us have a function `fn foo<'a>(x: &'a T) -> &'a T`.
The return type require the function to be covariant over `'a`, while the parameter requires it to be contravariant.
This is called *invariance*.

Rust uses 'definition-site variance'.
That means that the variance is computed solely from the definition of the type, not from its usage.

Both rustc and gccrs variance analysis is based on Section 4 of the paper "Taming the Wildcards: Combining Definition- and
Use-Site Variance"
published in PLDI'11 and written by Altidor et al. Notation from the paper is followed in documentation of both compilers and in this text.
The paper primarily focuses on complex type variance, like in the case of Java,
but it introduces a simple calculus, which nicely works with higher-kinded lifetimes.

The exact rules are best understood from the paper and from the code itself.
Therefore, here I will only give a simple overview.
Lets assume a generic structs.

```rust
struct Foo<'a, 'b, T> {
    x: &'a T,
    y: Bar<T>,
}
```

