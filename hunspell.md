---
tagline: spell checking
---

## `local hunspell = require'hunspell'`

A ffi binding of the popular spell checking library [hunspell][hunspell lib].

------------------------------------------------------------- ------------------------------------------------------------
`hunspell.new(aff_filepath, dic_filepath[, key]) -> h`        create a hunspell instance
`h:free()`                                                    free the hunspell instance
`h:spell(word) -> true[, 'warn'] | false`                     spell-check a word (the 'warn' flag indicates a rare word, which often is a spelling mistake)
`h:suggest(word) -> words_t`                                  suggest correct words for a possibly bad word
**advanced use**
`h:analyze(word) -> words_t`                                  morphological analysis of a word
`h:stem(word) -> words_t`                                     stems of a word
`h:generate(word, example) -> words_t`                        generate word(s) by example
`h:generate(word, desc_t) -> words_t`                         generate word(s) by description (dictionary dependent)
`h:add_word(word)`                                            add a word to the dictionary (in memory)
`h:remove_word(word)`                                         remove a word from the dictionary (in memory)
`h:get_dic_encoding() -> string`                              return the current encoding (dictionary dependent)
**extras** (available with the included `hunspell.dll`)
`h:add_dic(dic_filepath[, key])`                              add a dictionary file to the hunspell instance
------------------------------------------------------------- ------------------------------------------------------------

[hunspell lib]:    http://hunspell.sourceforge.net/
