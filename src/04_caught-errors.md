\cleardoublepage

# Examples of Errors Detected by the Borrow-Checker {#sec:errors}

This appendix presents some faulty program from gccrs test suite together with a fixed alternative (when applicable). Expected errors are marked using special comments used by the DejaGnu compiler testing framework.

Comments staring with `//~ ERROR` provide additional details for the reader. They are not a functional part of the test suite.

## Move Errors

A simple test, where an instance of type A, which is not trivially copyable (does not implement the `Copy` trait) is moved twice.

> ```rust
> fn test_move() {
>     // { dg-error "Found move errors in function test_move" }
>     struct A {
>         i: i32,
>     }
>     let a = A { i: 1 };
>     let b = a; // a is moved here for the first time
>     let c = a; //~ ERROR `a` moved here for the second time
> }
> ```

> ```rust
> fn test_move_fixed() {
>     let a = 1; // `a` is now primitive and can be copied
>     let b = a; // `a` is not moved here
>     let c = b;
> }
> ```

More complex text test, where moves the occurrence of the error depends on runtime values. Error is raised because for some values, the violation is possible

> ```rust
> fn test_move_conditional(b1: bool, b2:bool) {
>      // { dg-error "Found move errors in function test_move" }
>     struct A { i: i32 }
> 
>     let a = A { i: 1 }; // `A` cannot be copied
>     if b1 {
>         let b = a; // `a` might be moved here for the first time
>     }
>     if b2 {
>         let c = a; // `a` might be moved here for the second time
>     }
> }
> ```

> ```rust
> fn test_move_fixed(b1: bool, b2:bool) {
>     let a = 1; // a is now primitive and can be copied
>     if b1 {
>         let b = a;
>     }
>     if b2 {
>         let c = a;
>     }
> }
> ```

\clearpage

## Subset Errors

In the following examples, a reference with insufficient lifetime might be returned from a function.

> ```rust
> fn missing_subset<'a, 'b>(x: &'a u32, y: &'b u32) -> &'a u32 {
>     // { dg-error "Found subset errors in function missing_subset" } 
>     y //~ ERROR
> }
> ```

> ```rust 
> fn missing_subset_fixed<'a, 'b>(x: &'a u32, y: &'b u32) -> &'a u32
>     where 'b: 'a {
>     y
> }
> ```

> ```rust
> fn complex_cfg_subset<'a, 'b>(b: bool, x: &'a u32, y: &'b u32)
>     -> &'a u32 {
>     // { dg-error "Found subset errors in function
>          complex_cfg_subset" } 
>     if b {
>         y //~ ERROR
>     } else {
>         x
>     }
> }
> ```

> ```rust
> fn complex_cfg_subset_fixed<'a, 'b>(b: bool, x: &'a u32, y: &'b u32)
>     -> &'a u32 where 'b: 'a {
>     if b {
>         x
>     } else {
>         y
>     }
> }
> ```

\clearpage

## Loan Errors

### Polonius Smoke Test

The following tests were used when Polonius was first experimentally integrated into rustc.

In this test `s` is moved while it is borrowed. The test checks that facts are correctly propagated through the function call.

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

This test checks that variable cannot be used while borrowed.

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
> ```

\clearpage

This code fails under NLL but not under Polonius (including in gccrs).

> ```rust
> pub fn position_dependent_outlives<'a>(x: &'a mut i32, cond: bool)
>     -> &'a mut i32 {
>     let y = &mut *x;
>     if cond {
>         return y;
>     } else {
>         *x = 0;
>         return x;
>     }
> }
> ```

### Additional Tests of Access Rules

The tested rule should be obvious form the test name.

> ```rust
> fn immutable_borrow_while_immutable_borrowed() {
>     let x = 0;
>     let y = &x;
>     let z = &x;
>     let w = y;
> }
> ```

> ```rust
> fn immutable_borrow_while_mutable_borrowed() {
>     // { dg-error "Found loan errors in function
>          immutable_borrow_while_mutable_borrowed" }
>     let mut x = 0;
>     let y = &mut x;
>     let z = &x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust
> fn mutable_borrow_while_immutable_borrowed() {
>     // { dg-error "Found loan errors in function
>          mutable_borrow_while_immutable_borrowed" }
>     let x = 0;
>     let y = &x;
>     let z = &mut x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust
> fn mutable_borrow_while_mutable_borrowed() {
>     // { dg-error "Found loan errors in function
>          mutable_borrow_while_mutable_borrowed" }
>     let mut x = 0;
>     let y = &mut x;
>     let z = &mut x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust
> fn immutable_reborrow_while_immutable_borrowed() {
>     let x = 0;
>     let y = &x;
>     let z = &*y;
> }
> ```

> ```rust
> fn immutable_reborrow_while_mutable_borrowed() {
>     let mut x = 0;
>     let y = &mut x;
>     let z = &*y;
> }
> ```

> ```rust
> fn mutable_reborrow_while_immutable_borrowed() {
>     // { dg-error "Cannot reborrow immutable borrow as mutable" }
>     let x = 0;
>     let y = &x;
>     let z = &mut *y; //~ ERROR
> }
> ```

> ```rust
> fn read_while_mutable_borrowed() {
>     // { dg-error "Found loan errors in function
>          read_while_mutable_borrowed" }
>     let mut x = 0;
>     let y = &mut x;
>     let z = x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust
> fn write_while_borrowed() {
>     // { dg-error "Found loan errors in function write_while_borrowed" }
>     let mut x = 0;
>     let y = &x;
>     x = 1; //~ ERROR
>     let z = y;
> }
> ```

> ```rust
> fn write_while_immutable_borrowed() {
>     // { dg-error "Found loan errors in function
>          write_while_immutable_borrowed" }
>     let x = 0;
>     let y = &x;
>     x = 1; //~ ERROR
>     let z = y;
> }
> ```

### Access Rules Violations with Structs

The following test demonstrated that the previous tests work also when the references are wrapped in structs. Type generic structs cannot be demonstrated due to a preexisting bug in gccrs. This bug is unrelated to the borrow-checker, but it creates invalid TyTy. 

Note that due to one limitation of the current implementation, the `impl` functions need to explicitly specify the `<'a>` lifetime parameter. This is not required and not allowed in Rust 

> ```rust
> struct Reference<'a> {
>     value: &'a i32,
> }
> 
> impl<'a> Reference<'a> {
>     fn new<'a>(value: &'a i32) -> Reference<'a> {
>         Reference { value: value }
>     }
> }
> 
> struct ReferenceMut<'a> {
>     value: &'a mut i32,
> }
> 
> impl<'a> ReferenceMut<'a> {
>     fn new<'a>(value: &'a mut i32) -> ReferenceMut<'a> {
>         ReferenceMut { value: value }
>     }
> }
> ```

> ```rust                                                                                                                                               
> fn immutable_borrow_while_immutable_borrowed_struct() {
>     let x = 0;
>     let y = Reference::new(&x);
>     let z = &x;
>     let w = y;
> }
> ```

> ```rust                                                                                                                                                  
> fn immutable_borrow_while_mutable_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          immutable_borrow_while_mutable_borrowed_struct" }
>     let mut x = 0;
>     let y = ReferenceMut::new(&mut x);
>     let z = &x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust                                         
> fn mutable_borrow_while_immutable_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          mutable_borrow_while_immutable_borrowed_struct" }
>     let x = 0;
>     let y = Reference::new(&x);
>     let z = &mut x; //~ ERROR
>     let w = y;
> }
> ````

> ```rust                                                                                                                                                 
> fn mutable_borrow_while_mutable_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          mutable_borrow_while_mutable_borrowed_struct" }
>     let mut x = 0;
>     let y = ReferenceMut::new(&mut x);
>     let z = &mut x; //~ ERROR
>     let w = y;
> }
> ```

>```rust                                                                                                                                                  
> fn immutable_reborrow_while_immutable_borrowed_struct() {
>     let x = 0;
>     let y = Reference::new(&x);
>     let z = &*y.value;
> }
> ```

> ```rust                                                                                                                                                     
> fn immutable_reborrow_while_mutable_borrowed_struct() {
>     let mut x = 0;
>     let y = Reference::new(&mut x);
>     let z = &*y.value;
> }
> ```

> ```rust 
> fn mutable_reborrow_while_immutable_borrowed_struct() {
>     // { dg-error "Cannot reborrow immutable borrow as mutable" }
>     let x = 0;
>     let y = Reference::new(&x);
>     let z = &mut *y.value; //~ ERROR
> }
> ```

> ```rust 
> fn read_while_mutable_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          read_while_mutable_borrowed_struct" }
>     let mut x = 0;
>     let y = ReferenceMut::new(&mut x);
>     let z = x; //~ ERROR
>     let w = y;
> }
> ```

> ```rust 
> fn write_while_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          write_while_borrowed_struct" }
>     let mut x = 0;
>     let y = Reference::new(&x);
>     x = 1; //~ ERROR
>     let z = y;
> }
> ```

> ```rust 
> fn write_while_immutable_borrowed_struct() {
>     // { dg-error "Found loan errors in function
>          write_while_immutable_borrowed_struct" }
>     let x = 0;
>     let y = Reference::new(&x);
>     x = 1; //~ ERROR
>     let z = y;
> }
> ```
