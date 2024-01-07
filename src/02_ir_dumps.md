\cleardoublepage

# Rustc Intermediate Representations Examples

## Rust Source Code

```rust
struct Foo(i32);

fn foo(x: i32) -> Foo {
    Foo(x)
}
```


## Abstract Syntax Tree (AST)

> `$ rustc -Z unpretty=ast-tree`

```text
Fn {
    defaultness: Final,
    generics: Generics {
        params: [],
        where_clause: WhereClause {
            has_where_token: false,
            predicates: [],
            span: simple.rs:3:22: 3:22 (#0),
        },
        span: simple.rs:3:7: 3:7 (#0),
    },
    sig: FnSig {
        header: FnHeader { unsafety: No, asyncness: No, constness: No },
        decl: FnDecl {
            inputs: [
                Param {
                    attrs: [],
                    ty: Ty {
                        id: NodeId(4294967040),
                        kind: Path(
                            None,
                            Path {
                                span: simple.rs:3:11: 3:14 (#0),
                                segments: [
                                    PathSegment {
                                        ident: i31#0,
                                        id: NodeId(4294967040),
                                        args: None,
                                    },
                                ],
                                tokens: None,
                            },
                        ),
                        span: simple.rs:3:11: 3:14 (#0),
                        tokens: None,
                    },
                    pat: Pat {
                        id: NodeId(4294967040),
                        kind: Ident(
                            BindingAnnotation(No, Not),
                            x#0,
                            None,
                        ),
                        span: simple.rs:3:8: 3:9 (#0),
                        tokens: None,
                    },
                    id: NodeId(4294967040),
                    span: simple.rs:3:8: 3:14 (#0),
                    is_placeholder: false,
                },
            ],
            output: Ty(
                Ty {
                    id: NodeId(4294967040),
                    kind: Path(
                        None,
                        Path {
                            span: simple.rs:3:19: 3:22 (#0),
                            segments: [
                                PathSegment {
                                    ident: Foo#0,
                                    id: NodeId(4294967040),
                                    args: None,
                                },
                            ],
                            tokens: None,
                        },
                    ),
                    span: simple.rs:3:19: 3:22 (#0),
                    tokens: None,
                },
            ),
        },
        span: simple.rs:3:1: 3:22 (#0),
    },
    body: Some(
        Block {
            stmts: [
                Stmt {
                    id: NodeId(4294967040),
                    kind: Expr(
                        Expr {
                            id: NodeId(4294967040),
                            kind: Call(
                                Expr {
                                    id: NodeId(4294967040),
                                    kind: Path(
                                        None,
                                        Path {
                                            span: simple.rs:4:5: 4:8 (#0),
                                            segments: [
                                                PathSegment {
                                                    ident: Foo#0,
                                                    id: NodeId(4294967040),
                                                    args: None,
                                                },
                                            ],
                                            tokens: None,
                                        },
                                    ),
                                    span: simple.rs:4:5: 4:8 (#0),
                                    attrs: [],
                                    tokens: None,
                                },
                                [
                                    Expr {
                                        id: NodeId(4294967040),
                                        kind: Path(
                                            None,
                                            Path {
                                                span: simple.rs:4:9: 4:10 (#0),
                                                segments: [
                                                    PathSegment {
                                                        ident: x#0,
                                                        id: NodeId(4294967040),
                                                        args: None,
                                                    },
                                                ],
                                                tokens: None,
                                            },
                                        ),
                                        span: simple.rs:4:9: 4:10 (#0),
                                        attrs: [],
                                        tokens: None,
                                    },
                                ],
                            ),
                            span: simple.rs:4:5: 4:11 (#0),
                            attrs: [],
                            tokens: None,
                        },
                    ),
                    span: simple.rs:4:5: 4:11 (#0),
                },
            ],
            id: NodeId(4294967040),
            rules: Default,
            span: simple.rs:3:23: 5:2 (#0),
            tokens: None,
            could_be_bare_literal: false,
        },
    ),
}
```

## High-Level Intermediate Representation (HIR)

> `$ rustc -Z unpretty=hir-tree`

```text
Fn(
    FnSig {
        header: FnHeader {
            unsafety: Normal,
            constness: NotConst,
            asyncness: NotAsync,
            abi: Rust,
        },
        decl: FnDecl {
            inputs: [
                Ty {
                    hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).10),
                    kind: Path(
                        Resolved(
                            None,
                            Path {
                                span: simple.rs:3:11: 3:14 (#0),
                                res: PrimTy(
                                    Int(
                                        I32,
                                    ),
                                ),
                                segments: [
                                    PathSegment {
                                        ident: i32#0,
                                        hir_id: HirId(
                                            DefId(0:6 ~ simple[415f]::foo).11),
                                        res: PrimTy(
                                            Int(
                                                I32,
                                            ),
                                        ),
                                        args: None,
                                        infer_args: false,
                                    },
                                ],
                            },
                        ),
                    ),
                    span: simple.rs:3:11: 3:14 (#0),
                },
            ],
            output: Return(
                Ty {
                    hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).12),
                    kind: Path(
                        Resolved(
                            None,
                            Path {
                                span: simple.rs:3:19: 3:22 (#0),
                                res: Def(
                                    Struct,
                                    DefId(0:3 ~ simple[415f]::Foo),
                                ),
                                segments: [
                                    PathSegment {
                                        ident: Foo#0,
                                        hir_id: HirId(
                                            DefId(0:6 ~ simple[415f]::foo).13),
                                        res: Def(
                                            Struct,
                                            DefId(0:3 ~ simple[415f]::Foo),
                                        ),
                                        args: None,
                                        infer_args: false,
                                    },
                                ],
                            },
                        ),
                    ),
                    span: simple.rs:3:19: 3:22 (#0),
                },
            ),
            c_variadic: false,
            implicit_self: None,
            lifetime_elision_allowed: false,
        },
        span: simple.rs:3:1: 3:22 (#0),
    },
    Generics {
        params: [],
        predicates: [],
        has_where_clause_predicates: false,
        where_clause_span: simple.rs:3:22: 3:22 (#0),
        span: simple.rs:3:7: 3:7 (#0),
    },
    BodyId {
        hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).9),
    },
)

...

Expr {
    hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).3),
    kind: Call(
        Expr {
            hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).4),
            kind: Path(
                Resolved(
                    None,
                    Path {
                        span: simple.rs:4:5: 4:8 (#0),
                        res: Def(
                            Ctor(
                                Struct,
                                Fn,
                            ),
                            DefId(0:4 ~ simple[415f]::Foo::{constructor#0}),
                        ),
                        segments: [
                            PathSegment {
                                ident: Foo#0,
                                hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).5),
                                res: Def(
                                    Ctor(
                                        Struct,
                                        Fn,
                                    ),
                                    DefId(0:4 ~ simple[415f]::Foo::{constructor#0}),
                                ),
                                args: None,
                                infer_args: true,
                            },
                        ],
                    },
                ),
            ),
            span: simple.rs:4:5: 4:8 (#0),
        },
        [
            Expr {
                hir_id: HirId(DefId(0:6 ~ simple[415f]::foo).6),
                kind: Path(
                    Resolved(
                        None,
                        Path {
                            span: simple.rs:4:9: 4:10 (#0),
                            res: Local(
                                HirId(DefId(0:6 ~ simple[415f]::foo).2),
                            ),
                            segments: [
                                PathSegment {
                                    ident: x#0,
                                    hir_id: HirId(
                                        DefId(0:6 ~ simple[415f]::foo).7),
                                    res: Local(
                                        HirId(
                                            DefId(0:6 ~ simple[415f]::foo).2),
                                    ),
                                    args: None,
                                    infer_args: true,
                                },
                            ],
                        },
                    ),
                ),
                span: simple.rs:4:9: 4:10 (#0),
            },
        ],
    ),
    span: simple.rs:4:5: 4:11 (#0),
}
```

## Mid-Level Intermediate Representation (MIR)

> `$ rustc -Z unpretty=mir -Z identify-regions`

```
fn foo(_1: i32) -> Foo {
    debug x => _1;
    let mut _0: Foo;	

    bb0: {
        _0 = Foo(_1);
        return;
    }
}

fn Foo(_1: i32) -> Foo {
    let mut _0: Foo;	

    bb0: {
        _0 = Foo(move _1);
        return;
    }
}

```