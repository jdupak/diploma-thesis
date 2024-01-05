pub fn x<'a>(cond: bool, x: &i32, y: &i32) {
> let r: &'0 i32 = if (cond) {
>     &x /* Loan L0 */
> } else {
>     &y /* Loan L1 */
> };
}
