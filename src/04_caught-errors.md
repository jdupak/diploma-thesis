# Examples of Errors Detected by the Borrow-Checker {#sec:errors}

A faulty program from gccrs test suite together with a fixed alternative (when applicable) is presented. Expected errors are marked using special comments used by the DejaGnu compiler testing framework.

## Move Errors

A simple test, where an instance of type A, which is not trivially copiable (does not implement the compy trait) is moved twice.

> ```rust
> fn test_move() {
>     // { dg-error "Found move errors in function test_move" }
>     struct A {
>         i: i32,
>     }
>     let a = A { i: 1 };
>     let b = a;
>     let c = a;
> }
> ```

> ```rust
> fn test_move_fixed() {
>     let a = 1; // a is now primitive and can be copied
>     let b = a;
>     let c = b;
> }
> ```

More complex text test, where moves the occurence of the error depends on runtime values. Error is raised bacause for some values, the violation is possible

> ```rust
> fn test_move_conditional(b1: bool, b2:bool) {
>      // { dg-error "Found move errors in function test_move" }
>     struct A {
>         i: i32,
>     }
> 
>     let a = A { i: 1 };
>     let b = a;
>     if b1 {
>         let b = a;
>     }
>     if b2 {
>         let c = a;
>     }
> }
> ```

> ```rust
> fn test_move_fixed(b1: bool, b2:bool) {
> 
>     let a = 1; // a is now primitive and can be copied
>     let b = a;
>     if b1 {
>         let b = a;
>     }
>     if b2 {
>         let c = a;
>     }
> }
> ```

## Subset Errors

TODO

## Loan Error

TODO

The following test were used when Polonius was first experimentally integrated into rustc.

In this test `s` is moved while it is borrowed. The test checks that facts are corectly propagated through the function call.

> ```rust
> fn foo<'a, 'b>(p: &'b &'a mut usize) -> &'b&'a mut usize {
>     p
> }
> 
> fn well_formed_function_inputs() {
>     // { dg-error "Found loan errors in function well_formed...
>     let s = &mut 1;
>     let r = &mut *s;
>     let tmp = foo(&r  );
>     s; //~ ERROR
>     tmp;
> }
> ```

This test check that variable cannot be used while borrowed.

> ```rust
> pub fn use_while_mut() {
>     // { dg-error "Found loan errors in function use_while_mut" }
>     let mut x = 0;
>     let y = &mut x;
>     let z = x; //~ ERROR
>     let w = y;
> }
> ```

This test is similar to the previous one but uses a reborrow of a reference passed as an argument.

> ```rust
> pub fn use_while_mut_fr(x: &mut i32) -> &mut i32 { 
>     // { dg-error "Found loan errors in function use_while_mut_fr" }
>     let y = &mut *x;
>     let z = x; //~ ERROR
>     y
> }
>```