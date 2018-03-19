---
tagline: Cassowary constraint solver in Lua
---

## `local amoeba = require'amoeba'`

A fork of [amoeba](https://github.com/starwing/amoeba) (Lua implementation
only), an implementation of the Cassowary constraint solving algorithm based
on [kiwi](https://github.com/nucleic/kiwi) and the original
[Cassowary paper](http://constraints.cs.washington.edu/solvers/uist97.html).

## API

----------------------------------------------------------- -----------------------------------------
`amoeba.new() -> S`                                         create a solver
`S:var(name) -> var`                                        create a variable
`expr + expr -> expr`                                       build expression (add an addition)
`expr - expr -> expr`                                       build expression (add an addition)
`expr * expr -> expr`                                       build expression (add a multiplication)
`expr / expr -> expr`                                       build expression (add a multiplication)
`expr:le(expr) -> expr`                                     build expression (set the `'<='` operator)
`expr:ge(expr) -> expr`                                     build expression (set the `'>='` operator)
`expr:eq(expr) -> expr`                                     build expression (set the `'=='` operator)
`S:constraint([op, [expr1], [expr2], [strength]]) -> cons`  create a constraint
`cons:relation(op) -> cons`                                 set operator (`'>='`, `'<='`, `'=='`)
`cons:add(op|expr|expr_args...) -> cons`                    add expression or set operator
`cons(...) -> cons`                                         `cons:add(...)`
`cons:strength(strength) -> cons`                           set strength
`S:addconstraint(cons|cons_args...) -> cons`                create/add a constraint
`S:delconstraint(cons) -> cons`                             remove a constraint
`S:addedit(var[, strength]) -> S`                           make variable editable
`S:deledit(var)`                                            make variable non-editable
`S:suggest(var, value)`                                     (make var editable and) set its value
`S:setstrength(cons, strength) -> S`                        set constraint strength
`S:set_constant(cons, constant)`                            set constant
`self.vars -> {var -> true}`                                solver's variables
`self.constraints -> {cons -> true}`                        solver's constraints
`self.edits -> {edit -> true}`                              solver's edits
----------------------------------------------------------- -----------------------------------------

__Notes:__

  * `op` can be `'>='` `'<='`, `'=='`, `'ge'`, `'le'` or `'eq'`.
  * `expr` can be a number (treated as constant), a `var` or an `expr`.
  * `strength` can be a number or `'WEAK'` (1), `'MEDIUM'` (1e3),
  `'STRONG'` (1e6) or `'REQUIRED'` (1e9).
  * all objects have a `__tostring` metamethod for inspection.
