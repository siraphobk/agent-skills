# Worked Example

One finding, shown twice. The first version is too coarse to act on. The
second version is the target density. The code is a Go order handler.

## The code

```go
func (h *Handler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    var req createOrderRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, err.Error(), 400)
        return
    }
    if req.CustomerID == "" || req.Currency == "" || len(req.Lines) == 0 {
        http.Error(w, "missing fields", 400)
        return
    }
    total := 0.0
    for _, l := range req.Lines {
        if l.Qty <= 0 {
            http.Error(w, "bad qty", 400)
            return
        }
        total += float64(l.Qty) * l.UnitPrice
    }
    if req.Currency == "THB" {
        total = math.Round(total*100) / 100
    } else if req.Currency == "JPY" {
        total = math.Round(total)
    }
    disc := 0.0
    if req.CouponCode != "" {
        c, err := h.coupons.Get(r.Context(), req.CouponCode)
        if err == nil && c.ValidUntil.After(time.Now()) {
            disc = total * c.Percent / 100
        }
    }
    o := &Order{
        CustomerID: req.CustomerID, Currency: req.Currency,
        Total: total - disc, Lines: req.Lines, Status: "new",
    }
    if err := h.repo.Save(r.Context(), o); err != nil {
        http.Error(w, err.Error(), 500)
        return
    }
    w.WriteHeader(201)
    _ = json.NewEncoder(w).Encode(o)
}
```

## Too coarse

> #### B1 — Long Method in `CreateOrder` · 🟡
>
> **Where:** `handler/order.go:14`
>
> **Smell.** The function is long.
>
> **Technique.** Extract Method.
>
> **Why it matters here.** Long functions are hard to read.

This version fails in four ways. The anchor is one line, not the span. The
evidence has no number. The technique has no reason and no alternative. The
sketch is missing, so the reader cannot see the shape of the fix.

## Right

> #### B1 — Long Method in `CreateOrder` · 🟡
>
> **Where:** `handler/order.go:14-52`
>
> **Smell.** The function is 39 lines with four jobs: decode, validate, price,
> and save. The site says a method over ten lines deserves a question. The
> pricing block at lines 24-37 is the part that changes most.
>
> **Technique.** Extract Method
> (`https://refactoring.guru/extract-method`). Three extractions: `validate`,
> `price`, and `applyCoupon`. Replace Temp with Query is the alternative for
> `total`, but the extraction alone removes the temp, so it is not needed.
>
> **Why it matters here.** The next pricing rule lands inside an HTTP handler
> and needs an HTTP test to cover it. After the extraction, `price` takes a
> request and returns a value, so a table test covers it. It is 🟡 and not 🔴
> because no change to pricing is in progress.
>
> **Sketch.**
>
> ```go
> // before
> total := 0.0
> for _, l := range req.Lines { … }
> if req.Currency == "THB" { … } else if req.Currency == "JPY" { … }
> disc := 0.0
> if req.CouponCode != "" { … }
> o := &Order{ …, Total: total - disc, … }
> ```
>
> ```go
> // after
> if err := validate(req); err != nil {
>     http.Error(w, err.Error(), 400)
>     return
> }
> total := price(req.Lines, req.Currency)
> disc := h.applyCoupon(r.Context(), req.CouponCode, total)
> o := &Order{ …, Total: total - disc, … }
> ```

## The rest of the report for this code

The same file yields three more findings and one ignored smell. The report
lists them in this order.

| ID | Smell | Where | Severity | Technique |
|---|---|---|---|---|
| B2 | Primitive Obsession | `order.go:23,37` | 🟡 | Replace Data Value with Object |
| B3 | Switch Statements | `order.go:29-33` | 🔵 | Replace Conditional with Polymorphism |
| D1 | Primitive Obsession | `order.go:44` | 🔵 | Replace Type Code with Class |

- **B2.** Money is a `float64` and the currency is a `string` beside it. A
  `Money` type with the rounding rule inside it removes the currency `if`
  chain as well, so B2 and B3 share one fix. Say that in B3.
- **B3.** The `if` chain on `Currency` is a switch on a type code. It is 🔵
  and not 🟡 because it appears once. It becomes 🟡 when a second copy
  appears in the refund path.
- **D1.** `Status: "new"` is a string constant used as a code. A named type
  with constants is the fix. Group letter `D` is wrong here. Primitive
  Obsession is a bloater, so the ID is `B4`. The table above shows the error
  on purpose. Check every ID against its group before you show the report.

| Where | Smell | Ignore reason |
|---|---|---|
| `order.go:14` | Long Parameter List | Two parameters. Go handler signature. |
