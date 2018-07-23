
--hunspell ffi binding.
--Written by Cosmin Apreutesei. Publid Domain.

--Made for hunspell 1.3.2.

local ffi = require'ffi'
local C = ffi.load'hunspell'
local M = {C = C}

ffi.cdef[[
enum {
	HUNSPELL_MAXDIC = 20,
	HUNSPELL_MAXSUGGESTION = 15,
	HUNSPELL_MAXSHARPS = 5
};
typedef struct Hunhandle Hunhandle;
Hunhandle *Hunspell_create(const char * affpath, const char * dpath);
Hunhandle *Hunspell_create_key(const char * affpath, const char * dpath, const char * key);
void Hunspell_destroy(Hunhandle *pHunspell);
int Hunspell_spell(Hunhandle *pHunspell, const char *);
char *Hunspell_get_dic_encoding(Hunhandle *pHunspell);
int Hunspell_suggest(Hunhandle *pHunspell, char*** slst, const char * word);
int Hunspell_analyze(Hunhandle *pHunspell, char*** slst, const char * word);
int Hunspell_stem(Hunhandle *pHunspell, char*** slst, const char * word);
int Hunspell_stem2(Hunhandle *pHunspell, char*** slst, char** desc, int n);
int Hunspell_generate(Hunhandle *pHunspell, char*** slst, const char * word, const char * word2);
int Hunspell_generate2(Hunhandle *pHunspell, char*** slst, const char * word, char** desc, int n);
int Hunspell_add(Hunhandle *pHunspell, const char * word);
int Hunspell_add_with_affix(Hunhandle *pHunspell, const char * word, const char * example);
int Hunspell_remove(Hunhandle *pHunspell, const char * word);
void Hunspell_free_list(Hunhandle *pHunspell, char *** slst, int n);

//extras from extras.cxx
int Hunspell_add_dic(Hunhandle *pHunspell, const char * dpath, const char * key);

]]

function M.new(affpath, dpath, key) --key is for hzip-encrypted dictionary files
	local h = key and
		assert(C.Hunspell_create_key(affpath, dpath, key)) or
		assert(C.Hunspell_create(affpath, dpath))
	return ffi.gc(h, C.Hunspell_destroy)
end

function M.free(h)
	C.Hunspell_destroy(h)
	ffi.gc(h, nil)
end

function M.spell(h, s)
	local ret = C.Hunspell_spell(h, s)
	return ret ~= 0, ret == 2 and 'warn' or nil
end

function M.get_dic_encoding(h)
	local s = C.Hunspell_get_dic_encoding(h)
	if s == nil then return end
	return ffi.string(s)
end

local function output_list()
	return ffi.new('char**[1]')
end

local function free_list(h, list, n)
	local t = {}
	for i=0,n-1 do
		table.insert(t, ffi.string(list[0][i]))
	end
	C.Hunspell_free_list(h, list, n)
	return t
end

function M.suggest(h, word)
	local list = output_list()
	local n = C.Hunspell_suggest(h, list, word)
	return free_list(h, list, n)
end

function M.analyze(h, word)
	local list = output_list()
	local n = C.Hunspell_analyze(h, list, word)
	return free_list(h, list, n)
end

function M.stem(h, word)
	local list = output_list()
	local n = C.Hunspell_stem(h, list, word)
	return free_list(h, list, n)
end

local function input_list(t)
	local p = ffi.new('const char*[?]', #t)
	for i,s in ipairs(t) do
		p[i-1] = s
	end
	return p, #t
end

function M.generate(h, word, word2)
	local list = output_list()
	local n
	if type(word2) == 'table' then
		local desc, desc_n = input_list(word2)
		n = C.Hunspell_generate2(h, list, word, ffi.cast('char**', desc), desc_n)
	else
		n = C.Hunspell_generate(h, list, word, word2)
	end
	return free_list(h, list, n)
end

function M.add_word(h, word, example)
	if example then
		assert(C.Hunspell_add_with_affix(h, word, example) == 0)
	else
		assert(C.Hunspell_add(h, word) == 0)
	end
end

function M.remove_word(h, word)
	assert(C.Hunspell_remove(h, word) == 0)
end

function M.add_dic(h, dpath, key)
	assert(C.Hunspell_add_dic(h, dpath, key) == 0)
end

ffi.metatype('Hunhandle', {__index = {
	free = M.free,

	spell = M.spell,
	suggest = M.suggest,
	analyze = M.analyze,
	stem = M.stem,
	generate = M.generate,

	add_word = M.add_word,
	remove_word = M.remove_word,

	get_dic_encoding = M.get_dic_encoding,

	--extras
	add_dic = M.add_dic,
}})


if not ... then
	local hunspell = M
	local pp = require'pp'

	local h = hunspell.new(
		'media/hunspell/en_US/en_US.aff',
		'media/hunspell/en_US/en_US.dic')

	assert(h:spell('dog'))
	assert(not h:spell('dawg'))

	pp('suggest for "dawg"', h:suggest('dawg'))
	pp('analyze "words"', h:analyze('words'))

	pp('stem of "words"', h:stem('words'))

	pp('generate plural of "word"', h:generate('word', 'ts:Ns'))
	pp('generate plural of "word"', h:generate('word', {'ts:Ns'}))

	h:add_word('asdf')
	assert(h:spell('asdf'))
	h:remove_word('asdf')
	assert(not h:spell('asdf'))

	assert(h:get_dic_encoding() == 'UTF-8')

	--extras
	h:add_dic('media/hunspell/en_US/en_US.dic')

	h:free()
end

return M

