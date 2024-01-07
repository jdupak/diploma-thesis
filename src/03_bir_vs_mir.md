# Comparison of BIR and MIR

BIR and MIR dump of the following code are displayed parallel, BIR on left pages and MIR on right pages. Note that assert macros in MIR were simplified to fit onto the page.

## Compilation Commands

>
> ```
> $ crab1 -frust-incomplete-and-experimental-compiler-do-not-use \
>         -frust-dump-bir -frust-borrowcheck
> ```
>
> `$ rustc -Zdump-mir=nll -Zidentify-regions`

## Rust Source Code

```rust
pub fn fib(n: u32) -> u32 {
    if n == 0 || n == 1 {
        1
    } else {
        fib(n-1) + fib(n - 2)
    }
}
```

```{=latex}
\begin{Parallel}[p]{}{}
\ParallelLText{
```

## BIR (Rustc GCC) 

\small
```
fn fib(_2: u32) -> u32 {
        let _1: u32;	[]
        let _2: u32;	[]
        let _3: bool;	[]
        let _5: u32;	[]
        let _6: bool;	[]
        let _8: u32;	[]
        let _9: bool;	[]
        scope 2 {
            let _14: u32;	[]
            let _15: u32;	[]
            let _16: u32;	[]
            let _19: u32;	[]
            let _20: u32;	[]
            let _21: u32;	[]
        }

    bb0: {
    0    StorageLive(_3);
    1    StorageLive(_5);
    2    _5 = _2;
    3    StorageLive(_6);
    4    _6 = Operator(move _5, const u32);
    5    switchInt(move _6) -> [bb1, bb2];
    }

    bb1: {
    0    _3 = const bool;
    1    goto -> bb3;
    }

    bb2: {
    0    StorageLive(_8);
    1    _8 = _2;
    2    StorageLive(_9);
    3    _9 = Operator(move _8, const u32);
    4    _3 = move _9;
    5    goto -> bb3;
    }

    bb3: {
    0    switchInt(move _3) -> [bb4, bb5];
    }

    bb4: {
    0    _1 = const u32;
    1    goto -> bb8;
    }

    bb5: {
    0    StorageLive(_14);
    1    _14 = _2;
    2    StorageLive(_15);
    3    _15 = Operator(move _14, const u32);
    4    StorageLive(_16);
    5    _16 = Call(fib)(move _15) -> [bb6];
    }

    bb6: {
    0    StorageLive(_19);
    1    _19 = _2;
    2    StorageLive(_20);
    3    _20 = Operator(move _19, const u32);
    4    StorageLive(_21);
    5    _21 = Call(fib)(move _20) -> [bb7];
    }

    bb7: {
    0    _1 = Operator(move _16, move _21);
    1    StorageDead(_21);
    2    StorageDead(_20);
    3    StorageDead(_19);
    4    StorageDead(_16);
    5    StorageDead(_15);
    6    StorageDead(_14);
    7    goto -> bb8;
    }

    bb8: {
    0    StorageDead(_9);
    1    StorageDead(_8);
    2    StorageDead(_6);
    3    StorageDead(_5);
    4    StorageDead(_3);
    5    return;
    }
}
```

```{=latex}
}
\ParallelRText{
```

## MIR (rustc)

\small

```
fn fib(_1: u32) -> u32 {
    debug n => _1;
    let mut _0: u32;	
    let mut _2: bool;	
    let mut _3: u32;	
    let mut _4: bool;	
    let mut _5: u32;	
    let mut _6: u32;	
    let mut _7: u32;	
    let mut _8: u32;	
    let mut _9: (u32, bool);	
    let mut _10: u32;	
    let mut _11: u32;	
    let mut _12: u32;	
    let mut _13: (u32, bool);	
    let mut _14: (u32, bool);	

    bb0: {
        StorageLive(_2);
        StorageLive(_3);
        _3 = _1;
        _2 = Eq(move _3, const 0_u32);
        switchInt(move _2) -> [0: bb2, otherwise: bb1];
    }

    bb1: {
        StorageDead(_3);
        goto -> bb3;
    }

    bb2: {
        StorageDead(_3);
        StorageLive(_4);
        StorageLive(_5);
        _5 = _1;
        _4 = Eq(move _5, const 1_u32);
        switchInt(move _4) -> [0: bb4, otherwise: bb3];
    }

    bb3: {
        StorageDead(_5);
        _0 = const 1_u32;
        goto -> bb10;
    }

    bb4: {
        StorageDead(_5);
        StorageLive(_6);
        StorageLive(_7);
        StorageLive(_8);
        _8 = _1;
        _9 = CheckedSub(_8, const 1_u32);
        assert(!move (_9.1: bool)) -> [success: bb5, unwind: bb11];
    }

    bb5: {
        _7 = move (_9.0: u32);
        StorageDead(_8);
        _6 = fib(move _7) -> [return: bb6, unwind: bb11];
    }

    bb6: {
        StorageDead(_7);
        StorageLive(_10);
        StorageLive(_11);
        StorageLive(_12);
       _12 = _1;
        _13 = CheckedSub(_12, const 2_u32);
        assert(!move (_13.1: bool)) -> [success: bb7, unwind: bb11];
    }

    bb7: {
        _11 = move (_13.0: u32);
        StorageDead(_12);
        _10 = fib(move _11) -> [return: bb8, unwind: bb11];
    }

    bb8: {
        StorageDead(_11);
        _14 = CheckedAdd(_6, _10);
        assert(!move (_14.1: bool)) -> [success: bb9, unwind: bb11];
    }

    bb9: {
        _0 = move (_14.0: u32);
        StorageDead(_10);
        StorageDead(_6);
        goto -> bb10;
    }

    bb10: {
        StorageDead(_4);
        StorageDead(_2);
        return;
    }

    bb11 (cleanup): {
        resume;
    }
}

}
```

```{=latex}
}
\end{Parallel}
```