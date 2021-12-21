
--Line wrapping based on SMAWK algorithm from https://xxyxyz.org/line-breaking/
--Written by Cosmin Apreutesei. Public Domain.

--[==[
def linear(text, width):
    words = text.split()
    count = len(words)
    offsets = [0]
    for w in words:
        offsets.append(offsets[-1] + len(w))

    minima = [0] + [10 ** 20] * count
    breaks = [0] * (count + 1)

    def cost(i, j):
        w = offsets[j] - offsets[i] + j - i - 1
        if w > width:
            return 10 ** 10 * (w - width)
        return minima[i] + (width - w) ** 2

    def smawk(rows, columns):
        stack = []
        i = 0
        while i < len(rows):
            if stack:
                c = columns[len(stack) - 1]
                if cost(stack[-1], c) < cost(rows[i], c):
                    if len(stack) < len(columns):
                        stack.append(rows[i])
                    i += 1
                else:
                    stack.pop()
            else:
                stack.append(rows[i])
                i += 1
        rows = stack

        if len(columns) > 1:
            smawk(rows, columns[1::2])

        i = j = 0
        while j < len(columns):
            if j + 1 < len(columns):
                end = breaks[columns[j + 1]]
            else:
                end = rows[-1]
            c = cost(rows[i], columns[j])
            if c < minima[columns[j]]:
                minima[columns[j]] = c
                breaks[columns[j]] = rows[i]
            if rows[i] < end:
                i += 1
            else:
                j += 2

    n = count + 1
    i = 0
    offset = 0
    while True:
        r = min(n, 2 ** (i + 1))
        edge = 2 ** i + offset
        smawk(range(0 + offset, edge), range(edge, r + offset))
        x = minima[r - 1 + offset]
        for j in range(2 ** i, r - 1):
            y = cost(j + offset, r - 1 + offset)
            if y <= x:
                n -= j
                i = 0
                offset += j
                break
        else:
            if r == n:
                break
            i = i + 1

    lines = []
    j = count
    while j > 0:
        i = breaks[j]
        lines.append(' '.join(words[i:j]))
        j = i
    lines.reverse()
    return lines

]==]
