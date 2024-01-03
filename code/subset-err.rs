fn test<'a, 'b>(a: &'a i32, b: &'b i32) -> &'a i32 {
    if *a > *b {
        a
    } else {
        b
    }
}