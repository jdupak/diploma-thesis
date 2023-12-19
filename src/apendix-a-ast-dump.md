# Appendix A: AST Dump

\small \small \small \small

```
Fn {
    defaultness: Final,
    generics: Generics {
        params: [],
        where_clause: WhereClause {
            has_where_token: false,
            predicates: [],
            span: example.rs:3:22: 3:22 (#0),
        },
        span: example.rs:3:7: 3:7 (#0),
    },
    sig: FnSig {
        header: FnHeader { unsafety: No, asyncness: No, constness: No, ext: None },
        decl: FnDecl {
            inputs: [
                Param {
                    attrs: [],
                    ty: Ty {
                        id: NodeId(4294967040),
                        kind: Path(
                            None,
                            Path {
                                span: example.rs:3:11: 3:14 (#0),
                                segments: [
                                    PathSegment {
                                        ident: i32#0,
                                        id: NodeId(4294967040),
                                        args: None,
                                    },
                                ],
                                tokens: None,
                            },
                        ),
                        span: example.rs:3:11: 3:14 (#0),
                        tokens: None,
                    },
                    pat: Pat {
                        id: NodeId(4294967040),
                        kind: Ident(
                            BindingAnnotation(No, Not),
                            x#0,
                            None,
                        ),
                        span: example.rs:3:8: 3:9 (#0),
                        tokens: None,
                    },
                    id: NodeId(4294967040),
                    span: example.rs:3:8: 3:14 (#0),
                    is_placeholder: false,
                },
            ],
            output: Ty(
                Ty {
                    id: NodeId(4294967040),
                    kind: Path(
                        None,
                        Path {
                            span: example.rs:3:19: 3:22 (#0),
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
                    span: example.rs:3:19: 3:22 (#0),
                    tokens: None,
                },
            ),
        },
        span: example.rs:3:1: 3:22 (#0),
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
                                            span: example.rs:4:5: 4:8 (#0),
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
                                    span: example.rs:4:5: 4:8 (#0),
                                    attrs: [],
                                    tokens: None,
                                },
                                [
                                    Expr {
                                        id: NodeId(4294967040),
                                        kind: Path(
                                            None,
                                            Path {
                                                span: example.rs:4:9: 4:10 (#0),
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
                                        span: example.rs:4:9: 4:10 (#0),
                                        attrs: [],
                                        tokens: None,
                                    },
                                ],
                            ),
                            span: example.rs:4:5: 4:11 (#0),
                            attrs: [],
                            tokens: None,
                        },
                    ),
                    span: example.rs:4:5: 4:11 (#0),
                },
            ],
            id: NodeId(4294967040),
            rules: Default,
            span: example.rs:3:23: 5:2 (#0),
            tokens: None,
            could_be_bare_literal: false,
        },
    ),
}
```

\normalsize