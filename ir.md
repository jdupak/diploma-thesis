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

# IR

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

In addition to code representation, there is also representation for types.
Initially, types are represented in HIR on syntactic level.
Every mention of a type in HIR is a distinct HIR node.
Those types are compiled into a representation called TyTy, where each type is represented by a single instance.
(This is achieved by interning.
Note, that there can be multiple equivalent type of different structure.
Those are represented by different TyTy instances.) Each non-primitive type forms a tree (e.g. reference to a pair of integer and char), where the
inner nodes are shared (due to interning). Generic types, which are of special interest to borrow-checking, are represented as a pair:
an inner type and a list of generic parameters.
When generic types parameters are substituted for concrete types, the new type is place into the parameter list.
The inner type is left unchanged.
Finally, there is a procedure, which transforms the generic type into a concrete type.

Inside the HIR, after the type-checking analysis, types of nodes can be looked up based on the node's ID in one of the helper tables
(namely, the typecheck context).
Each THIR node directly contains a pointer to its type.
In MIR the type is stored in each place.

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

## Rust GCC representation

The gccrs representation is strongly inspired by rustc and diverges mostly for two reasons: for simplicity,
since gccrs is still in a early stage, and due to the specifics of the GCC platform.
Gccrs uses AST, HIR and TyTy representations, but it does not use THIR or MIR.

AST and HIR representation are similar to rustc's, with less features supported.
The main difference is the structure of the representation.
Rustc takes advantaged of algebraic data types resulting in very fine-grained representation.
On the other hand gccrs is severly limited by capabilities of C++ and is forced to use an object-oriented approach.

There is no THIR and MIR or any equivalent in gccrs.
MIR cannot be used in GCC unless a the whole gccrs code generation is rewritten to output GIMPLE instead of GENERIC,
which would be way more complex then the current approach.
Given the limited development resources of gccrs, this is not a viable
option. [#](https://gcc-rust.zulipchat.com/#narrow/stream/281658-compiler-development/topic/Borrowchecking.20vs.20.28H.29IR)
THIR

TyTy type representions is simplified in gccrs and does not provide any uniqueness guarantees.
There is a notable difference in the representation of generic types.
Instead of being built on top of ther types (generic type of top of struct tupe) like in rustc,
types that support generic parameters inherit from a common base class.
That means, that the type definition is not shared between different generic types.
The advantage of this approach is that during substitution of generic parameters,
the inner types are modified at the time of each substitution, which simplifies intermediate handling, like type
inference. [todo, ask Phillip, if this is true]

# Rust GCC Borrow-checker Design

> This section discusses the intermediate representation in gccrs. Since gccrs is a second implementation of the Rust compiler, it is heavily inspired
> by rustc. Therefore this section will assume familiarity with rustc's intermediate representations, described in the previous section. We will focus
> on similarities and differences between rustc and gccrs, rather than describing the gccrs intermediate representation in detail.

The Rust GCC borrow-checker is designed to be as similar to the `rustc` borrow-checker as possible withing the constraints of the Rust GCC.
This allows us to leverage the existing knowledge about borrow-checking in Rust.
The checking works in two phases.
First, it collects information (called facts) about the program, which typically takes a form of tuples of numbers.
Then it passes the facts to the analysis engine, which computes the results of the analysis.
The compiler then receives back the facts involved in rules violations and translates them into error messages.
The main decision of the Rust GCC borrow-checker is to reuse the analysis engine from rustc.
To connect the Polonius engine written in Rust to the gccrs compiler written in C++, we

## Analysis of the fact collection problem

This section described options for fact collection in gccrs that were considered and experimented with during the initial design phase.
Due to the differences between internal representations of rustc and gccrs it was not possible to simply adopt the rustc's approach.
Considered options were to use HIR directly, to implement MIR in gccrs,
or to design a new IR for borrow-checking with multiple option to place it inside the compilation pipeline.

Ever since the introduction of NLL in rustc (see section TODO), the analysis is control-flow sensitive.
This requires us to match the required facts, which are specific to Rust semantics, with control-flow graph nodes.
We need to distinguish between pointers (in unsafe Rust) and references.
Pointer is not subject to borrow-checking, but references are.
Furthermore, we need to distinguish between mutable and immutable references, since they have different rules, essential for borrow-checking
[^](The key rule of borrow-checking is the for a single borrowed variable,
there can only be a single mutable borrow, or only immutable borrows valid at each point of the CFG.).
Each type has to carry information about lifetimes it contains and their variances (described later in this chaper).
For explicit user type annotation, we need to store the explicit lifetime parameters.

The only IR in GCC what contains the CFG information is GIMPLE; however, under normal circumstances GIMPLE is language agnostic.
It is possible to annotate the GIMPLE statements with language specific information,
using special statements, which would have to be generated from special information that would need to be added GENERIC.
The statemenets would need to be preserved by the middle-end passes until the pass building the CFG (that includes 11 passes),
after which the facts could be collected.
After that,
the facts would need
to be discared to avoid complicating the tens of following passes[#](passes.def)[#](https://gcc.gnu.org/onlinedocs/gccint/Passes.html) and RTL
generation.
This approach was discussed with senior GCC developers and quickly rejected as it would require large amount of work and it would leak front-end
specific information into the middle-end,
making it more complex.
No attempt was made to experiment with this approach.

Since it was clear that we need to build a possibly approximate GFC. It is not necessary to work with a particular control flow graph created by the
compiler. Any CFG that is consistent with
Rust semantics is sufficient.
In particular, adding any edges and merging nodes in the CFG is conservative with regards to the borrow-checking analysis,
and it many cases it does not change the result.
This fact is exploited by the rustc in at least two ways.
Match CFG is simplified and fake edges are added to loops to ensure that there is an exit edge.

Initially,
we have attempted to collect the information from HIR and compute and approximate CFG as we go.
This can work nicely for simple language constructs,
that are local, but its get very complicated for more complex constructs like patterns,
loops with breaks and continues, etc, and since no "code" is generated, there is no easy way to verify the process, not even by manual checking.
Further more, it was not clear, how to handle panics and stack unwinding.

An option to ease such problems was to radically desuggared the HIR to only basic constructs.
An advantage of this approach would be that it would leverage the code already existing in the code generator,
possibly making the code generation easier.
Also,
the code generator already preforms some of those tranformations locally
(not applying them back to HIR, but using them directly for GENERIC generation).
Problem, that quickly arose was that the HIR visitor system was not designed for HIR-to-HIR transformations, where new nodes would be created.
Many of such transformations,
like explicit handling of automatic referencing and dereferencing would require information about the types of each node,
which would in return require name resolution.
Therefofore those transformation would have to happen after all analysis passes on HIR are completed.
However, all of that information would need to be updated for the newly created nodes.
The code generator partly avoids this problems by querying the GENERIC API for the some information it needs about already compiled code.
This fact would complicated leveraging those existing thransformations on the HIR level.
Rustc avoid this problem by doing such tranformations on the HIR-THIR boundary, and not modifying the HIR itself.
Since this modification would be complicated and it would only be a preparation for the borrow-checking,
it was decided not to proceed in this direction at that time.
Hovewer, it was found that some transformation can be done on the AST-HIR boundary.
This approach can be done mostly independently (only code handling the removed nodes is also removed, but no additions or modifications are needed).
It was agreed that such transformations are useful and should be implemented regardless of the path taken by the borrow-checker.
Those transformations include mainly loops and pattern matching structures.
Those transformations are even documented in the rust reference [citation needed].

> At the time of writing this thesis, desugaring of for loop was implemented by Philip Herron.
> And more desugaring is in progress or planned.
> Hovever, I have focused on the borrow-checking itself and for the time being I have ignored the complex constructs, assuming that they will be
> eventualy desugared to constructs tha borrow-checker already can handle.

To make sure that all possible approaches were considered, we have discussed the possibility of implementing MIR in gccrs.
This approached as some advantages and many problems.
Should the MIR be implemented in a completely compatible way, it would be possible to use tools like MIRI with gccrs.
The borrowchecking would be very similar to rustc's borrow-checking and parts of rustc's code might even get reused.
Gccrs would also be more ready for rust specific optimizations.
The final advantage would be that the process of lowering HIR to MIR would be covered by the current testsuite
as all transformations would affect the code genetration.
The main problem with this approach is that it would require a large portion of gccrs to be reimplemented,
delaying the project by a considerable amount of time.
Should such an approach be taken, any effort on borrow-checking would be delayed until the MIR is implemented.
It was decided by the maintainers[#](https://gcc-rust.zulipchat.com/#narrow/stream/281658-compiler-development/topic/Borrowchecking.20vs.20.28H.29IR)
that such approach is not feasible and that gccrs will not use MIR in any foreseeable future.

After Arthur Cohen suggesting to keep the things more simple, I have decided to experiment with a different, minimalistic approach -
to build a radically simplified MIR-like IR, that keeps only the bare minimum of information needed for borrow-checking.
Given the unexpected productivity of this approach, it was decided to go on with it.
This IR, later called the borrow-checker IR (BIR), only focuses on flow of data and it ignores the actual operations on the data.
The main disadvantage of this approach is that it creates a dead branch of the compilation pipeline,
that is not used for code generation, and therefore it is not covered by the existing testsuite.
To overcome this difficulty, the BIR, and its textual representation (dump) is designed to be as similar to rustc's MIR as possible.
This allows us to check the generated BIR against the MIR generated by rustic, at least for simple programs.
This is the final approach used by this work.
Details of the BIR design are described in the next section.

## Borrowcheking Process

Before the borrow-checking itself can be performed,
specific information about types needs to be collected, when HIR is type check and TyTy types are created and processed,
and the TyTy needs to resolve and store information about lifetimes and their constraints.
At this point, lifetimes are resolved from string names and their bounding clauses are found.
There are different kinds of lifetimes that can be encountered.
Inside types, the lifetimes are bound to the lifetime parameters of generic types.
In function pointers, lifetimes can be universally quantified (meaning that the function must work for every possible lifetime).
In function definitions lifetimes can be elided when all references have the same lifetime.
In function bodies, lifetimes can be bound to the lifetime parameters of the function, or they can be omitted,
in which case they are inferred
[^](At least Rust semantics thinks about it that way. In reality, the compiler only checks, that there exists some lifetime that could be used in that
position, by collecting constraints that would apply to such lifetime abd passing them to the borrow-checker.).

## Borrow-checker IR Design

```
fn fib(_1: usize) -> i32 {
    bb0: {
        _4 = Operator(_1, const usize);
        switchInt(_4) -> [bb1, bb2];
    }

    ... 

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

> Shortened example of BIR dump of a simple Rust program, computing a Fibonacci number.
> The source code and full dump together with a legend can be found in the
> appendix. [crossref, todo make the apeendix]
> This example comes from a "BIR Design Notes",
> which is part of the source tree
> and where provides an introduction for a developer getting familiar with the basic aspects of the borrow-checker implementation.

The borrow-checker IR (BIR) is a three-address code representation, designed to be very close to a subset of rustc's MIR.
Same as MIR, it represents the body of a single function (or other function-like item, e.g. a closure),
since borrow-checking is performed on each function separately. It ignores particular operations and merges them into a few abstract operations, that
only focus on the flow of data.

The BIR of a single function composes of basic metadata about the function (like arguments, return type, explicit lifetimes, etc.), a list of basic
blocks, and a list of places.

A basic block is identified by its index in the function's basic block list. It contains a list of BIR statements and a list of successor
basic block indices in CFG.
BIR statements are of three categories: An assignment of an expression to a local (place), a control flow operation (switch, return), or a special
statement (not executable), which carries additional information for borrow-checking (explicit type annotations, information about variable scope,
etc.).
BIR statements correspond to MIR `StatementKind` enum.

Expressions represent the executable parts of the rust code. Many different Rust contracts are represented by a single expression, as only data (and
lifetime) flow needs to be tracked.
Some expressions are differentiated only to allow for a better debugging experience.
BIR expressions correspond to MIR `RValue` enum.

Expressions and statements operate on places.
A place is an abstract representation of a memory location.
Is is either a variables, a field, an index, or a dereference of another place.
For simplicity, constants are also represented as places.
Since exact values are not important for borrow-checking and constants are from principle immutable with static storage duration,
all constants of single type can be represented by a single place.
Rustc MIR cannot afort this simplification and it keeps constants separate.
`Operand` enum is used as a common interface for usage of places and constants.
However, since constants and lvalues are used the same way by operations, MIR introduces a special layers of lvalues.

Places are identified by the index in the place database.
The database stores a list of the places and their properties.
The properties include an identifier,
used to always resolve the same variable (field, index, etc.) to the same place, move and copy flags.
Temporaries are treated just like variables, but are differentiated in the place database, because of place lookup.
a type, a list of fresh regions (lifetimes), relationship to other places (e.g. a field of a struct).
The place database structure is based on
rustc `MovePathData` [#](https://rustc-dev-guide.rust-lang.org/borrow_check/moves_and_initialization/move_paths.html).
It combines the handling of places done by both MIR and borrow-checker separately in rustc.

It is important to highlight that different fields are assigned to different places;
however, all indices are assigned to the same place (both in gccrs and rustc).
That has a strong impact on the strength and complexity of the analysis,
since the number of fields is static and typically small, while the size of arrays is unbound and depends on runtime information.

The following graphic illustrates the while structure of BIR:

- `BIR Function`
    - basic block list
        - basic block
            - `Statement`
                - `Assignment`
                    - `InitializerExpr`
                    - `Operator<ARITY>`
                    - `BorrowExpr`
                    - `AssignmentExpr` (copy)
                    - `CallExpr`
                - `Switch`
                - `Goto`
                - `Return`
                - `StorageLive` (start of variable scope)
                - `StorageDead` (end of variable scope)
                - `UserTypeAsscription` (explicit type annotation)
    - place database
    - arguments
    - return type
    - universal lifetimes
    - universal lifetime constraints

## BIR Building

The BIR is built by visiting the HIR tree of the function.
There are specialized visitors for expressions and statements, pattern, and a top level vistor that handles

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
