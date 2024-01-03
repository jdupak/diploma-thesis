fn test_move_behind_reference() {
    struct A {
        i: i32,
    }
    struct B {
        a: A,
    }
    let a = A { i: 1 };
    let b = B { a };
    let c = &b;
    let d = c.a;
}