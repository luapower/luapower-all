---
tagline: 3rd degree equation solver
---

## `local eq = require'eq'`

### `eq.solve2(a, b, c[, epsilon]) -> [s1[, s2]]`

Solve the [2nd degree equation][1] *ax^2^ + bx + c* and return all the real solutions.

Epsilon controls the precision at which the solver converges on close enough solutions.

### `eq.solve3(a, b, c, d[, epsilon]) -> [s1[, s2[, s3]]]`

Solve the [3rd degree equation][2] *ax^3^ + bx^2^ + cx + d* and return all the real solutions.

Epsilon controls the precision at which the solver converges on close enough solutions.


[1]: http://en.wikipedia.org/wiki/Quadratic_equation
[2]: http://en.wikipedia.org/wiki/Cubic_function
