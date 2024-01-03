pub fn fib(n: u32) -> u32 {
    if n == 0 || n == 1 {
        1
    } else {
        fib(n-1) + fib(n - 2)
    }
}

