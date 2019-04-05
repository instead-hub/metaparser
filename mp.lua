require "fmt"
require "snapshots"
--luacheck: no self
if std.ref'@theme' then
	std.ref'@theme'.set ('win.scroll.mode', 3)
end

local mrd = require "morph/mrd"
local inp_split = " :.,!?-"

local input = std.ref '@input'

local function utf_bb(b, pos)
	if type(b) ~= 'string' or b:len() == 0 then
		return 0
	end
	local utf8 = (std.game.codepage == 'UTF-8' or std.game.codepage == 'utf-8')
	if not utf8 then return 1 end
	local i = pos or b:len()
	local l = 0
	while b:byte(i) >= 0x80 and b:byte(i) <= 0xbf do
		i = i - 1
		l = l + 1
		if i <= 1 then
			break
		end
	end
	return l + 1
end

local function utf_ff(b, pos)
	if type(b) ~= 'string' or b:len() == 0 then
		return 0
	end
	local utf8 = (std.game.codepage == 'UTF-8' or std.game.codepage == 'utf-8')
	if not utf8 then return 1 end
	local i = pos or 1
	local l = 0
	if b:byte(i) < 0x80 then
		return 1
	end
	i = i + 1
	l = l + 1
	while b:byte(i) and b:byte(i) >= 0x80 and b:byte(i) <= 0xbf do
		i = i + 1
		l = l + 1
		if i > b:len() then
			break
		end
	end
	return l
end

local function utf_len(b)
	local i = 1
	local n = 0
	if not b or b:len() == 0 then
		return 0
	end
	while i <= b:len() do
		i = i + utf_ff(b, i)
		n = n + 1
	end
	return n
end

local function utf_char(b, c)
	local i = 1
	local n = 0
	local s
	while i <= b:len() do
		s = i
		i = i + utf_ff(b, i)
		n = n + 1
		if n == c then
			return b:sub(s, i - 1)
		end
	end
	return
end

local function utf_chars(b)
	local i = 1
	local s
	local res = {}
	while i <= b:len() do
		s = i
		i = i + utf_ff(b, i)
		table.insert(res,  b:sub(s, i - 1))
	end
	return res
end

--- Returns the Levenshtein distance between the two given strings.
-- https://gist.github.com/Badgerati/3261142

-- @param str1 string1
-- @param str2 string2
local function utf_lev(str1, str2)
	str1 = str1 or ''
	str2 = str2 or ''
	local chars1 = utf_chars(str1)
	local chars2 = utf_chars(str2)
	local len1 = #chars1
	local len2 = #chars2
	local matrix = {}
	local cost

        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end

        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end

        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (chars1[i] == chars2[j]) then
				cost = 0
			else
				cost = 1
			end

			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end
local okey = input.key
local mp

local function use_text_event()
	return instead.text_input and instead.text_input()
end

local function post_inp()
	if mp.autohelp then
		mp:compl_fill(mp:compl(mp.inp))
	elseif mp.autocompl then
		mp:compl(mp.inp)
	end
end

if PLATFORM == "ANDROID" or PLATFORM == "IOS" or PLATFORM == "SFOS" then
local oclick = input.click

function input:click(press, mb, x, y, ...)
	local theme = std.ref'@theme'

	if not instead.text_input or not press or mb ~= 1 or not theme or mp.autohelp then
		if oclick then
			return oclick(self, press, mb, x, y, ...)
		end
		return false
	end

	local xx = std.tonum(theme.get 'inv.x')
	local yy = std.tonum(theme.get 'inv.y')
	local ww = std.tonum(theme.get 'inv.w')
	local hh = std.tonum(theme.get 'inv.h')
	if x >= xx and y >= yy and x < xx + ww and y < yy + hh then
		instead.text_input(not instead.text_input())
	end
	if oclick then
		return oclick(self, press, mb, x, y, ...)
	end
	return false
end
end

function input:text(sym)
	if sym == " " then -- in old key logic
		return false
	end
	if iface:raw_mode() then
		return false
	end
	mp:inp_insert(sym)
	post_inp()
	return '@mp_key '..tostring(sym)
end

function input:key(press, key)
	local mod
	if key:find("alt") then
		mp.alt = press
		mod = true
	elseif key:find("ctrl") then
		mp.ctrl = press
		mod = true
	elseif key:find("shift") then
		mp.shift = press
		mod = true
	end
	if key:find("enter") or key:find("return") then key = 'enter' end

	if press and not mod and not (mp.ctrl or mp.alt) then
		if mp:key(key) then
			post_inp()
			if key == 'f6' and mp.autoplay then key = 'enter' end
			return '@mp_key '..tostring(key)
		end
	end
	if okey then
		return okey(self, press, key)
	end
end

mp = std.obj {
	nam = '@metaparser';
	score = false;
	expert_mode = true;
	autohelp = false;
	autohelp_limit = 1000;
	autohelp_noverbs = false;
	togglehelp = true;
	errhints = true;
	autocompl = true;
	undo = 0;
	compl_thresh = 0;
	compare_len = 3;
	detailed_inv = false;
	daemons = std.list {};
	{
		version = "1.3";
		cache = { tokens = {} };
		scope = std.list {};
		logfile = false;
		lognum = 0;
		clear_on_move = true;
		auto_animate = true;
		autoplay = false;
		pushed = {};
		autoplay_command = false;
		inp = '';
		cur = 1;
		utf = {
			bb = utf_bb;
			ff = utf_ff;
			len = utf_len;
			char = utf_char;
		};
		lev_thresh = 3;
		lev_ratio = 0.20;
		history = {};
		persistent = std.list {};
		winsize = 16 * 1024;
		history_len = 100;
		history_pos = 0;
		cursor = fmt.b("|");
		prompt = "> ";
		ctrl = false;
		shift = false;
		alt = false;
		words = {};
		parsed = {};
		hints = {};
		unknown = {};
		multi = {};
		token = {};
		shortcut = {};
		reaction = false;
		redirect = false;
		msg = {};
		mrd = mrd;
		args = {};
		vargs = {};
		debug = { trace_action = false };
		completions = {};
		event = false;
		xevent = false;
		aliases = {};
		first = false;
		first_it = false;
		second_it = false;
		second = false;
		first_hint = '';
		second_hint = '';
		hint = {
			live = 'live',
			neuter = 'neuter',
			male = 'male',
			female = 'female',
			plural = 'plural',
		};
		shorten = {};
		shorten_expert = {};
	};
	text = '';
	-- dict = {};
}

function mp:trim()
	if self.winsize == 0 then
		self.text = ""
		return
	end
	local text = self.text
	while text:len() > self.winsize do
		local text2 = text:gsub("^%^?[^%^]*%^%^", "")
		if text2 == text then
			break
		end
		text = text2
	end
	self.text = text
end

function mp:key(key)
	if key == 'f1' and (self.togglehelp or DEBUG) then
		self.autohelp = not self.autohelp
		return true
	end
	if key == 'f6' and DEBUG then
		self:autoscript()
		return true
	end

	if key == 'left' then
		return self:inp_left()
	end
	if key == 'right' then
		return self:inp_right()
	end
	if key == 'up' then
		return self:key_history_prev()
	end
	if key == 'down' then
		return self:key_history_next()
	end
	if key == 'space' then
--		local inp = mp:docompl(self.inp)
--		if inp == self.inp then
			mp:inp_insert(' ')
--		else
--			self.inp = inp
--			self.cur = self.inp:len() + 1
--		end
		return true
	end
	if key == 'tab' then
		self.inp = mp:docompl(self.inp)
		self.cur = self.inp:len() + 1
		return true
	end
	if key == 'backspace' then
		if self:inp_remove() then
			return true
		end
		return true -- avoid scrolling
	end
	if key == 'enter' then
		return true
	end
	if use_text_event() then
		return false
	end
	if key:len() > 1 then
		return false
	end
	key = mp.shift and mrd.lang.kbd.shifted[key] or mrd.lang.kbd[key] or key
	if key then
		mp:inp_insert(key)
		return true
	end
	return false
end

function mp:inp_left()
	if self.cur > 1 then
		local i = utf_bb(self.inp, self.cur - 1)
		self.cur = self.cur - i
		return true
	end
end

function mp:inp_right()
	if self.cur <= self.inp:len() then
		local i = utf_ff(self.inp, self.cur)
		self.cur = self.cur + i
		return true
	end
end

function mp:inp_split()
	local pre = self.inp:sub(1, self.cur - 1);
	local post = self.inp:sub(self.cur);
	return pre, post
end

function mp:inp_insert(k)
	local pre, post = self:inp_split()
	self.cur = self.cur + k:len()
	self.inp = pre .. k .. post
end

function mp:inp_remove()
	local pre, post = self:inp_split()
	if not pre or pre == '' then
		return false
	end
	local i = utf_bb(pre)
	self.inp = self.inp:sub(1, pre:len() - i) .. post
	self.cur = self.cur - i
	return true
end

function mp:esc(s)
	local rep = function(str)
		return fmt.nb(str)
	end
	if not s then return end
	local r = s:gsub("[<>]+", rep):gsub("[ \t]", rep);
	return r
end

local keys_en = {
	"A", "B", "C", "D", "E", "F",
	"G", "H", "I", "J", "K", "L",
	"M", "N", "O", "P", "Q", "R",
	"S", "T", "U", "V", "W", "X",
	"Y", "Z"
}

local function str_strip(str)
	return std.strip(str)
end

local function str_split(str, delim)
	local a = std.split(str, delim)
	for k, _ in ipairs(a) do
		a[k] = str_strip(a[k])
	end
	return a
end

--- Returns true if parser mode is disabled
function mp:noparser()
	return std.here().noparser or game.noparser
end

instead.get_inv = std.cacheable('inv', function(horiz)
	if mp:noparser() then
		return
	end
	local delim = instead.hinv_delim
	if not horiz then
		delim = instead.inv_delim
	end
	local pre, post = mp:inp_split()
	local ret = iface:bold(mp.prompt) .. mp:esc(pre)..mp.cursor..mp:esc(post) .. '\n'
	if mp.autohelp then
		ret = iface:xref(ret, mp, "<clear>")
	end
	if not mp.autohelp and not std.here().forcehelp then
		local r = std.call(std.here(), 'help')
		return ret .. (r or '')
	end

	if mp.autohelp_noverbs and mp.inp:find("^[ \t]*$") then
		return ret
	end

	delim = delim or ' | '

	for _, v in ipairs(mp.completions) do
		local t = iface:xref(std.fmt(v.word), mp, v.word)
		if v.ob and have(v.ob) then t = iface:em(t) end
		if _ >= mp.autohelp_limit then
			ret = ret .. t .. ' ...' .. delim
			break
		end
		ret = ret .. t .. delim
	end
	if #mp.completions == 0 or mp.completions.eol then
		ret = ret .. iface:xref(mp.msg.enter or "<enter>", mp, "<enter>") .. delim
		if mp.completions.vargs then
			ret = ret .. iface:xref(mp.keyboard_space or "<space>", mp, "<space>") .. delim
			ret = ret .. iface:xref(mp.keyboard_backspace or "<backspace>", mp, "<backspace>") .. delim
			for _, v in ipairs(mp.keyboard or keys_en) do
				ret = ret .. iface:xref(v, mp, v, 'letter') .. delim
			end
		end
	end

	ret = ret:gsub(delim .."$", "")
	return ret
end)

--- Returns (add to) table with scope objects
-- @param wh where to start scope
-- @param oo table
-- @param recurs recursive flag
function mp:objects(wh, oo, recurs)
	local scope = self.scope
	wh:for_each(function(v)
		if v:disabled() then return nil, false end
		if scope:lookup(v) or v:visible() then
			table.insert(oo, v)
			if v.scope then
				if std.is_obj(v.scope, 'list') then
					scope:cat(v.scope)
				elseif type(v.scope) == 'function' then
					v:scope(scope)
				end
			end
		end
		if recurs == false or v:closed() then
			return nil, false
		end
		if std.is_obj(wh, 'list') then
			self:objects(v, oo, recurs)
		end
	end)
end

local darkness = std.obj {
	nam = '@darkness';
}

function mp:nouns()
	self.scope:zap()
	if type(std.here().nouns) == 'function' then
		return std.here():nouns()
	end
	local oo = {}
	self:objects(std.me():inroom(), oo)
	self:objects(std.me(), oo)
	self:objects(self.persistent, oo)
	table.insert(oo, std.me())
	if std.here().word then
		table.insert(oo, std.here())
	end
	if self:thedark() then
		table.insert(oo, darkness)
	end
	local dups = {}
	self.scope:for_each(function(v)
		if not dups[v] then
			table.insert(oo, v)
			dups[v] = true
		end
	end)
	return oo
end

function mp.token.noun_obj(w)
	return mp.token.noun(w)
end

function mp.token.noun(w)
	local attr = w.morph or ''
	local oo
	local ww = {}
	if w.pat == '{noun_obj}' then
		local hint = str_split(w.morph, ",")
		local o = std.ref(hint[1])
		oo = {}
		if o:visible() and not o:disabled() then
			table.insert(oo, o)
			mp:objects(o, oo)
		end
	else
		oo = mp:nouns()
	end

	local sm_dup = {
	}
	local syms = {}
	for _, o in ipairs(oo) do
		local d = {}
		local r = o:noun(attr, d)
		for k, v in ipairs(d) do
			local hidden = (k ~= 1) or w.hidden
			if o:has 'multi' then
				hidden = w.hidden or (v.idx ~= 1)
			end
			if o == std.me() and mp.myself then
				for _, vm in ipairs(mp:myself(o, w.morph)) do
					table.insert(ww, { optional = w.optional, word = vm, morph = attr, ob = o, alias = o.alias, hidden = hidden })
				end
				break
			else
				table.insert(ww, { optional = w.optional, word = r[k], ob = o, morph = attr, alias = v.alias, hidden = hidden })
			end
		end
		if o == mp.first_it then
			table.insert(syms, 1, o)
		elseif o == mp.second_it then
			table.insert(syms, o)
		end
	end

--	for k = 1, #syms do
--		table.insert(oo, k, syms[k])
--	end

	oo = syms

	for _, o in ipairs(oo) do
		for _, v in ipairs(mp:synonyms(o, w.morph)) do
			if not sm_dup[v] then
				table.insert(ww, { optional = w.optional, word = v, ob = o, morph = attr, alias = o.alias, hidden = true, synonym = true })
				sm_dup[v] = true
			end
		end
	end

	return ww
end

function mp.token.select(w)
	return mp.token.noun(w)
end

local norm_cache = { hash = {}, list = {}}

function mp:norm(t)
	local key = t
	local cc = norm_cache.hash[t]
	if cc then return cc end
	t = mrd.lang.lower(mrd.lang.norm(t)):gsub("[ \t]+", " ")
	table.insert(norm_cache.list, 1, t)
	norm_cache.hash[key] = t
	local len = #norm_cache.list
	if len > 512 then
		cc = norm_cache.list[len]
		table.remove(norm_cache.list, len)
		norm_cache.hash[cc] = nil
	end
	return t
end

--- Check if two strings are equal, using two possible check modes.
-- If lev is set, use it as Levenstein equality threshold.
-- If not, normalize the strings and check equality.
--
-- @see word_search
-- @see mp:lookup_noun
-- @param t1 first string
-- @param t2 second string
-- @param lev use levenstein or just normalize and compare
function mp:eq(t1, t2, lev)
	if t1:find("%*$") then
		local t = t1:gsub("%*$", "")
		t = mrd.lang.norm(t)
		return self:__startswith(t2, t)
	end
	if lev then
		local l = utf_lev(t1, t2)
		if l < lev and l / (utf_len(t1) + utf_len(t2)) <= self.lev_ratio then
			return l
		end
		return false
	end
	return self:norm(t1) == self:norm(t2)
end

local function starteq(t1, t2)
	if t2:len() >= t1:len() or utf_len(t2) < mp.compare_len then
		return mp:eq(t1, t2)
	end
	t1 = t1:sub(1, t2:len())
	return mp:norm(t1) == mp:norm(t2)
end

function mp:pattern(t, delim)
	local words = {}
	local pat = str_split(self:norm(t), delim or "|")
	for _, v in ipairs(pat) do
		local w = { }
		local ov = v
		if v:sub(1, 1) == '~' then
			v = v:sub(2)
			v = str_strip(v)
			w.hidden = true
		end
		if v:sub(1, 1) == '+' then
			v = v:sub(2)
			v = str_strip(v)
			w.optional = true
			w.default = true
		end
		if v:sub(1, 1) == '?' then
			v = v:sub(2)
			v = str_strip(v)
			w.optional = true
		end
		v = v:gsub("%+", " ") -- spaces
		if v:find("[^/]+/[^/]*$") then
			local s, e = v:find("/[^/]*$")
			w.morph = v:sub(s + 1, e)
			v = v:sub(1, s - 1)
			v = str_strip(v)
		end
		w.pat = v
		if v:find("^{[^}]+}$") then -- completion function
			v = v:gsub("^{", ""):gsub("}$", "")
			if type(self.token[v]) ~= 'function' then
				std.err("Wrong subst function: ".. v, 2);
			end
			local key = ov --  .. '/' .. (w.morph or '')
			local tok = self.cache.tokens[key]
			if not tok then
				tok = self.token[v](w)
				self.cache.tokens[key] = tok
			end
			while type(tok) == 'string' do
				tok = self:pattern(tok)
			end
			if type(tok) == 'table' then
				for _, xw in ipairs(tok) do
					table.insert(words, xw)
				end
			end
		else
			local vv = mp:pref_pattern(v)
			if #vv == 1 then
				w.word = v
				table.insert(words, w)
			else
				for _, exv in ipairs(vv) do
					local ww = std.clone(w)
					ww.word = exv
					table.insert(words, ww)
				end
			end
		end
	end
	return words
end

function mp:verb_find(tag, w)
	w = w or game
	for k, v in ipairs(w.__Verbs or {}) do
		if v.tag == tag then
			return v, k
		end
	end
end

function mp:verb_remove(tag, w)
	local v, k = self:verb_find(tag, w)
	if v then
		table.remove((w or game).__Verbs, k)
	end
	return v
end

function mp:pref_pattern(v)
	if not v:find("^%[[^%]]+%]") then
		return { v }
	end
	local _, e = v:find("]", 1, true)
	local pre = v:sub(2, e - 1)
	local post = v:sub(e + 1)
	pre = pre:gsub("^|", " |"):gsub("|$", "| "):gsub("||", "| |");
	pre = str_split(pre, "|")
	local ret = {}
	for _, pref in ipairs(pre) do
		table.insert(ret, pref .. post)
	end
	return ret
end

function mp:verb(t, w, extend)
	local rem
	w = w or game
	if type(t) ~= 'table' then
		std.err("Wrong 1-arg to mp:verb()", 2)
	end
	if type(w) ~= 'table' then
		std.err("Wrong 2-arg to mp:verb()", 2)
	end
	if not w.__Verbs then
		std.rawset(w, '__Verbs', {})
	end
	local verb = {}
	local n = 1
	if std.is_tag(t[1]) then
		verb.tag = t[1]
		rem = self:verb_remove(verb.tag, w)
		n = 2
	end
	if extend and (not rem or not verb.tag) then
		std.err("Extending non existing verb "..verb.tag or '#Undefined', 2)
	end
	if extend then
		verb.verb = rem.verb
		verb.dsc = rem.dsc
	else
		if type(t[n]) ~= 'string' then
			std.err("Wrong verb pattern in mp:verb()", 2)
		end
		verb.verb = self:pattern(t[n], ",")
		n = n + 1
		verb.dsc = {}
	end
	if type(t[n]) ~= 'string' then
		std.err("Wrong verb descriptor mp:verb()", 2)
	end
	while type(t[n]) == 'string' do
		local dsc = str_split(t[n], ":")
		local pat
		if #dsc == 1 then
			table.insert(verb.dsc, { pat = {}, ev = dsc[1] })
		elseif #dsc == 2 then
			pat = str_split(dsc[1], ' ')
			if pat[1] == '~' then
				table.remove(pat, 1)
				for k, v in ipairs(pat) do
					pat[k] = v:gsub("[^ |]+", function(s) return "~" .. s end)
				end
			end
			table.insert(verb.dsc, { pat = pat, ev = dsc[2] })
		else
			std.err("Wrong verb descriptor: " .. t[n])
		end
		n = n + 1
	end
	verb.hint = t.hint
	table.insert(w.__Verbs, 1, verb)
	return verb
end

function mp:verbs()
	local w = std.here().__Verbs or std.me().__Verbs or game.__Verbs or {}
	local t = {}
	for _, v in ipairs(w) do
		table.insert(t, v)
	end
	for _, v in ipairs(mp.__Verbs or {}) do
		table.insert(t, v)
	end
	return t
end

local function word_search(t, w, lev)
	local rlev
	w = str_split(w, inp_split)
	for k = 1, #t - #w + 1 do
		local found = true
		for i = 1, #w do
			local found2 = false
			for ii = k, k + #w - 1 do
				if type(lev) == 'function' then
					rlev = lev(w[i], t[ii])
				else
					rlev = mp:eq(w[i], t[ii], lev)
				end
				if rlev then
					found2 = true
					break
				end
			end
			if not found2 then
				found = false
				break
			end
		end
		if found then
			return k, #w, rlev
		end
	end
end

function mp:lookup_short(words, w)
	local ret = { }
	for _,v in ipairs(words) do
		if self:__startswith(v, w) then
			table.insert(ret, { i = _, w = v, pos = #ret })
		end
	end
	table.sort(ret, function(a, b)
		if a.w:len() == b.w:len() then return a.pos < b.pos end
		return a.w:len() < b.w:len()
	end)
	if #ret == 0 then return end
	return ret[1].i, 1
end

--- Return false if unparsed word is critical in parse sense
-- @param w table with skipped words
function mp:skip_filter()
	return true
end

function mp:lookup_verb(words, lev)
	local ret = {}
	local w = self:verbs()
	for _, v in ipairs(w) do -- verbs
		local lev_v = {}
		for _, vv in ipairs(v.verb) do
			local verb = vv.word .. (vv.morph or "")
			local i, len, rlev
			i, len, rlev = word_search(words, verb, lev and self.lev_thresh)
			if not i and not lev and verb ~= vv.word then
				i, len = self:lookup_short(words, vv.word)
			end
			if i and i > 1 and not self:skip_filter({words[i - 1]}) then
				i = nil
			end
			if i then
				if lev then
					table.insert(lev_v, { lev = rlev, verb = v, verb_nr = i, verb_len = len, word_nr = _ } )
				else
					local vc = std.clone(v)
					vc.verb_nr = i
					vc.verb_len = len
					vc.word_nr = _
					table.insert(ret, vc)
				end
			end
		end
		if lev and #lev_v > 0 then
			table.sort(lev_v, function(a, b)
					   if a.lev == b.lev then return a.word_nr < b.word_nr end
					   return a.lev < b.lev
			end)
			lev_v[1].verb.verb_nr = lev_v[1].verb_nr
			lev_v[1].verb.verb_len = lev_v[1].verb_len
			lev_v[1].verb.word_nr = lev_v[1].word_nr
			lev_v[1].verb.lev = lev_v[1].lev
			table.insert(ret, lev_v[1].verb)
		end
	end
	if lev then
		table.sort(ret, function(a, b)
				   if a.lev == b.lev then return a.word_nr < b.word_nr end
				   return a.lev < b.lev
		end)
	elseif #ret > 0 then
		table.sort(ret, function(a, b)
			if a.verb_nr == b.verb_nr then return a.word_nr < b.word_nr end
			return a.verb_nr < b.verb_nr
		end)
		local vlev = ret[1].verb_nr
		local ret2 = {}
		for _, v in ipairs(ret) do
			if v.verb_nr == vlev then
				table.insert(ret2, v)
			else
				break
			end
		end
		ret = ret2
	end
	return ret
end

local function tab_sub(t, s, e)
	local r = {}
	e = e or #t
	for i = s, e do
		table.insert(r, t[i])
	end
	return r
end

--[[
local function tab_exclude(t, s, e)
	local r = {}
	e = e or #t
	for i = 1, #t do
		if i < s or i > e then
			table.insert(r, t[i])
		end
	end
	return r
end
]]--

function mp:docompl(str, maxw)
	local full
	local force = maxw
	local inp, pre = self:compl_ctx()
	if utf_len(pre) < self.compl_thresh then
		return str
	end
	if not maxw then
		full = false
		local compl = self:compl(str)
		for _, v in ipairs(compl) do
			if not maxw then
				full = true
				maxw = v.word
			else
				local maxw2 = ''
				local utf_word = utf_chars(v.word)
				local utf_maxw = utf_chars(maxw)
				for k = 1, #utf_maxw do
					if mrd.lang.norm(utf_maxw[k]) == mrd.lang.norm(utf_word[k]) then
						maxw2 = maxw2 .. utf_maxw[k]
					else
						full = false
						break
					end
				end
				maxw = maxw2
			end
		end
		if full then
			if #compl > 1 then full = false end
		end
	else
		full = true
	end
	if maxw and maxw ~= '' then
		str = inp .. maxw
	end
	if force or full then
		str = str .. ' '
	end
	return str
end

function mp:__startswith(w, v)
	return w:find(v, 1, true) == 1
end

function mp:startswith(w, v)
	return (self:norm(w)):find(self:norm(v), 1, true) == 1
end

function mp:hint_verbs(v)
	if not v.tag then return true end
	if type(v.hint) == 'function' then
		return v:hint()
	end
	local r = true

	if std.here().hint_verbs_only then
		r = false
		for _, vv in ipairs(std.here().hint_verbs_only) do
			if v.tag == vv then
				r = true
				break
			end
		end
		return r
	end

	if game.hint_verbs then
		r = false
		for _, vv in ipairs(game.hint_verbs) do
			if v.tag == vv then
				r = true
				break
			end
		end
	end
	if r then return r end
	if std.here().hint_verbs then
		for _, vv in ipairs(std.here().hint_verbs) do
			if v.tag == vv then
				r = true
				break
			end
		end
	end
	return r
end
function mp:compl_verb(_)
	local poss = {}
	for _, v in ipairs(self:verbs()) do
		local filter = not self:hint_verbs(v)
		for _, vv in ipairs(v.verb) do
			local verb = vv.word .. (vv.morph or "")
			table.insert(poss, { word = verb, hidden = (_ ~= 1) or vv.hidden or filter})
		end
	end
	return poss
end

function mp:animate(w)
	if w:has'animate' == false then
		return false
	end
	return w:has'animate' or (self.auto_animate and w:hint'live')
end

local function holded_by(ob, holder)
	if not holder then
		return true
	end
	local h = holder.ob
	if not h then return false end
	if ob:where() == h then return true end
	for _, hm in ipairs(holder.multi or {}) do
		if ob:where() == hm then
			return true
		end
	end
	return false
end

local function multi_held(ob, attrs)
	if not attrs.held and not attrs.scene then
		return true
	end
	if ((attrs.held and have(ob)) or
		(attrs.scene and not have(ob))) then
		return true
	end
	return false
end

local function multi_select(vv, attrs, holder)
	local res = {}
	local ob = vv.ob
	if holded_by(ob, holder) and multi_held(ob, attrs) then
		table.insert(res, ob)
	end
	for _, h in ipairs(vv.multi or {}) do
		if holded_by(h, holder) then
			ob = h
			if multi_held(ob, attrs) then
				table.insert(res, ob)
			end
		end
	end
	local dist = -1;
	ob = res[1]
	for _, v in ipairs(res) do
		local d = mp:distance(v)
		if d < dist or dist == -1 then
			ob = v
			dist = d
		end
	end
	return ob or vv.ob, res
end

function mp:compl_filter(v)
	local hidden = v.hidden
	if not hidden and v.ob and v.ob.hint_noun ~= nil then
		if type(v.ob.hint_noun) == 'function' then
			hidden = not v.ob:hint_noun(v)
		else
			hidden = not v.ob.hint_noun
		end
	end
	if hidden and self.compl_thresh == 0 then
		return false
	end
	local _, pre = self:compl_ctx()
	if utf_len(pre) < self.compl_thresh then
		return false
	end
	if not v.ob or not v.morph then
		return true
	end
	local attrs = {
		held = false;
		scene = false;
		container = false;
		inside = false;
		enterable = false;
		edible = false;
		supporter = false;
		live = false,
		compass = false,
	}
	for _, h in ipairs(str_split(v.morph, ",")) do
		if attrs[h] ~= nil then attrs[h] = h end
	end
	for _, a in ipairs { 'container', 'enterable', 'supporter', 'edible' } do
		if attrs[a] and not v.ob:has(a) then return false end
	end
	if v.ob and mp:compass_dir(v.ob) and not attrs.compass then
		return false
	end
	if attrs.live and not self:animate(v.ob) then return false end
	if attrs.inside and not v.ob:has'container' and not v.ob:has'supporter' then return false end
	if not attrs.held and not attrs.scene then return true end
	if attrs.held and have(multi_select(v, attrs)) then return true end
	if attrs.scene and (not have(multi_select(v, attrs)) and v.ob ~= std.me()) then return true end
	return false
end

function mp:compl_fill(compl, eol, vargs)
	local ctx = self.completions.ctx
	self.completions = {}
	self.completions.ctx = ctx
	self.completions.eol = eol
	self.completions.vargs = vargs
	for _, v in ipairs(compl) do
		if self:compl_filter(v) then
			table.insert(self.completions, v)
		end
	end
end

function mp:compl_reset()
	self.completions = { ctx = {} }
end

function mp:compl_ctx_current()
	local ctx = self.completions.ctx
	local new = {}
	for _, v in ipairs(ctx) do
		if v.inp == '' and self.inp == '' then break end
		if self:startswith(self.inp, v.inp) then
			table.insert(new, v)
		else
			break
		end
	end
	self.completions.ctx = new
end

function mp:compl_ctx_push(poss)
	if #poss == 0 then
		return
	end
	local ctx = self.completions.ctx
	table.insert(ctx, poss)
	local top = #ctx
	ctx[top].inp = self.inp
end

function mp:compl_ctx()
	local ctx = self.completions.ctx
	local top = #ctx
	if top == 0 then
		return self.inp, ''
	end
	local inp = self.inp
	local ctx_inp = ctx[top].inp
	local _, e = inp:find(ctx_inp, 1, true)
	local pre = ''
	if e then
		pre = inp:sub(e + 1)
	end
	return ctx[top].inp, pre
end

function mp:compl_ctx_poss()
	local ctx = self.completions.ctx
	local top = #ctx
	local res = {}
	if top == 0 then
		return res
	end
	ctx = ctx[top]
	local _, pre = self:compl_ctx()
	for _, v in ipairs(ctx) do
		if self:__startswith(v.word, pre) or
			self:__startswith(self:norm(v.word), pre) then
			table.insert(res, v)
		end
	end
	return res
end

function mp:compl(str)
	local words = str_split(self:norm(str), inp_split)
	local poss
	local ret = {}
	local dups = {}
	local eol
	local e = str:find(" $")
	local vargs
	collectgarbage("stop")
	self:compl_ctx_current();
	poss = self:compl_ctx_poss()
	if (#poss == 0 and e) or #words == 0 then -- no context
		if #words == 0 or (#words == 1 and not e) then -- verb?
			poss, eol = self:compl_verb(words)
			local oo = self:nouns() -- and hidden nouns
			for _, o in ipairs(oo) do
				local ww = {}
				o:noun(ww)
				for _, n in ipairs(ww) do
					local hidden = true
					if o.raw_word then hidden = n.alias ~= 1 and not o:has'multi' end
					table.insert(poss, { word = n.word, hidden = hidden })
				end
			end
		else -- matches
			poss, eol, vargs = self:compl_match(words)
		end
		self:compl_ctx_push(poss)
	end
	local _, pre = self:compl_ctx()
	for _, v in ipairs(poss) do
		if v.word == '*' then vargs = true end
		if self:startswith(v.word, pre) and not v.word:find("%*$") then
			if not dups[v.word] then
				dups[v.word] = v
				table.insert(ret, v)
			else
				local o = dups[v.word]
				if o.hidden then
					o.hidden = v.hidden
				end
				if v.ob then
					if o.ob then
						o.multi = o.multi or {}
						table.insert(o.multi, v.ob)
					else
						o.ob = v.ob
					end
				end
			end
		end
	end
	table.sort(ret, function(a, b)
			   return a.word < b.word
	end)
	collectgarbage("restart")
	return ret, eol, vargs
end

local function lev_sort(t)
	for _, v in ipairs(t) do v.i = _ end
	table.sort(t, function(a, b)
			if a.lev == b.lev then
				return a.i < b.i
			end
			return a.lev > b.lev
	end)
	local lev = t[1] and t[1].lev
--	local fuzzy = t[1] and t[1].fuzzy

	local fuzzy = {}
	for _, v in ipairs(t) do if v.lev ~= lev then break end if v.fuzzy then table.insert(fuzzy, v) end end
	if #fuzzy > 0 then
		t = fuzzy
		t.fuzzy = true
	end

	local res = { lev = 0, match = #t > 0 and t[1].match }
	local dup = {}

	for _, v in ipairs(t) do
		if v.lev ~= lev then
			break
		end
		res.lev = lev
		if v.word then
			if not dup[v.word] then
				table.insert(res, v.word)
				dup[v.word] = true
			end
		else
			for _, vv in ipairs(v) do
				if not dup[vv] then
					table.insert(res, vv)
					dup[vv] = true
				end
			end
		end
	end
	return res
end

function mp:compl_match(words)
--	local verb = { words[1] }
	local verbs = self:lookup_verb(words)
--	table.remove(words, 1) -- remove verb
	local matches = {}
	local hints = {}
	local res = {}
	local multi
	collectgarbage("stop")
	for _, v in ipairs(verbs) do
		local m, h, _, mu = self:match(v, words, true)
		if #m > 0 then
			table.insert(matches, { verb = v, match = m[1] })
		end
		if #h > 0 then
			table.insert(hints, h)
		end
		multi = multi or (#mu > 0)
	end
	collectgarbage("restart")
	hints = lev_sort(hints)
	if multi then -- #matches > 0 or #hints == 0 or multi then
		return res
	end
	for _, v in ipairs(hints) do
		if #matches > 0 and #matches[1].match > hints.lev then
			return res, false, not not matches[1].match.vargs
		end
		local pat = self:pattern(v)
		for _, p in ipairs(pat) do
			table.insert(res, p)
		end
	end
	if #hints == 0 and #matches > 0 then
		return res, true, not not matches[1].match.vargs
	end
	return res, #matches > 0
end


function mp:match(verb, w, compl)
	local matches = {}
	local found
	local hints = {}
	local unknown = {}
	local multi = {}
	local vargs
	local parsed_verb = {}
	local fixed_verb = verb.verb[verb.word_nr]
	fixed_verb = fixed_verb.word .. (fixed_verb.morph or '')
	table.insert(parsed_verb, fixed_verb)
	for _, d in ipairs(verb.dsc) do -- verb variants
--		local was_noun = false
		local match = { args = {}, vargs = {}, ev = d.ev, wildcards = 0, verb = parsed_verb }
		local a = {}
		found = (#d.pat == 0)
		for k, v in ipairs(w) do
			if k < verb.verb_nr or k >= verb.verb_nr + verb.verb_len then
				table.insert(a, v)
			end
		end
		local skip = {}
		local all_optional = true
		local rlev = 1
		local need_required = false
		for lev, v in ipairs(d.pat) do -- pattern arguments
			if v == '*' or v == '~*' then
				vargs = true -- found
				v = '*'
			end
			local noun = not not v:find("^~?{noun}")
			local pat = self:pattern(v) -- pat -- possible words
			local best = #a + 1
			local best_len = 1
			local word
			local required = false
			found = false
			local wildcard = false
			for _, pp in ipairs(pat) do -- single argument
				if v == '*' then break end
				required = not pp.optional
				if not pp.optional then
					need_required = true
					all_optional = false
				end
				if pp.default then
					word = pp.word
				end
				local new_wildcard
				local k, len = word_search(a, pp.word)
				if not k and mp.compare_len > 0 then
					k, len = word_search(a, pp.word, starteq)
					new_wildcard = true
				else
					new_wildcard = false
				end
				if k and ((k < best or len > best_len) or
					(not new_wildcard and wildcard and k <= best and len >= best_len)) then
					wildcard = new_wildcard
					best = k
					word = pp.word
					found = pp
					best_len = len
					if pp.synonym or word:find("%*$") then -- subst
						word = found.ob:noun(found.morph, found.alias)
						wildcard = true
					end
				end
			end
			if found then
				need_required = false
				if found.ob then
					local exact
					for _, pp in ipairs(pat) do
						if pp.ob and pp.ob ~= found.ob and self:eq(found.word, pp.word) then
							if not found.multi then
								found.multi = {}
							end
							if not exact and pp.ob:noun(found.morph, pp.alias) == pp.word then -- excactly match
								exact = pp.ob
								table.insert(found.multi, found.ob)
							else
								table.insert(found.multi, pp.ob)
							end
							if found.ob:noun(found.alias) ~= pp.ob:noun(pp.alias) then
								table.insert(multi, { word = pp.ob:noun(pp.alias), lev = rlev })
							end
						end
					end
					if exact then
						found = std.clone(found)
						found.ob = exact
						multi = {}
					end
					if #multi > 0 and found.multi then
						table.insert(multi, 1, { word = found.ob:noun(found.alias), lev = rlev })
						found = false
						break
					end
				end
				if vargs then
					for i = 1, best - 1 do
						table.insert(match.vargs, a[i])
						table.insert(match, a[i])
					end
					if #match.vargs == 0 then -- * in the pattern center
						found = false
						break
					end
					rlev = rlev + 1
					vargs = false
				end
--				if false then
--					a = tab_exclude(a, best, best + best_len - 1)
--				else
--				if not was_noun then
					for i = 1, best - 1 do
						table.insert(skip, a[i])
					end
--				end
					a = tab_sub(a, best + best_len)
--					table.remove(a, 1)
--				end
				table.insert(match, word)
				table.insert(match.args, found)
				if wildcard then
					match.wildcards = match.wildcards + 1
				end
				rlev = rlev + 1
--				was_noun = not not found.ob
			elseif vargs then
				if lev == #d.pat then -- last?
					if #a == 0 then
						need_required = true
					end
					while #a > 0 do
						table.insert(match.vargs, a[1])
						table.insert(match, a[1])
						table.remove(a, 1)
					end
				else
					need_required = need_required or required
				end
				if not need_required then
					found = true
				else
					found = false
					if #a > 0 or #match.vargs > 0 then
						table.insert(hints, { word = v, lev = rlev })
					else
						table.insert(hints, { word = '*', lev = rlev })
					end
				end
				if not found then
					break
				end
			elseif required then
				for i = 1, best - 1 do
					table.insert(unknown, { word = a[i], lev = rlev, noun = noun })
				end
				if best <= 1 and #skip > 0 then
					for i = 1, #skip do
						table.insert(unknown, { word = skip[i], lev = rlev, skip = true })
					end
				end
				if not compl and mp.errhints then
					for _, pp in ipairs(pat) do -- single argument
						if utf_len(pp.word) >= 3 then
							local k, _ = word_search(a, pp.word, self.lev_thresh)
							if k then table.insert(hints, { word = pp.word, lev = rlev, fuzzy = true, match = match }) end
						end
					end
				end
				table.insert(hints, { word = v, lev = rlev, match = match })
				break
			else
				if word then
					table.insert(match, word)
				end
				table.insert(match.args, { word = false, optional = true } )
--				table.insert(hints, { word = v, lev = rlev })
				found = true
			end
		end
--		if #multi > 0 then
--			matches = {}
--			break
--		end
		if found or all_optional then
			match.extra = (#a ~= 0)
			table.insert(match, 1, fixed_verb) -- w[verb.verb_nr])
			if self:skip_filter(skip) then
				table.insert(matches, match)
			end
			if #match.vargs == 0 and not vargs then
				match.vargs = false
			end
		end
	end

	table.sort(matches,
		function(a, b)
			if #a == #b then
				return a.wildcards < b.wildcards
			end
			return #a > #b
		end)

	if #matches > 0 and matches[1].extra then
		local lev = #matches[1]
		if #unknown > 0 then
			for _, v in ipairs(unknown) do
				if v.lev >= lev and not v.skip then -- and v.noun then
					matches = {}
					break
				end
			end
		end
		if #multi > 0 and #matches > 0 then
			for _, v in ipairs(multi) do
				if v.lev >= lev and not v.skip then
					matches = {}
					break
				end
			end
		end
	end
--[[
	if #unknown > 0 then
		local nmatches = {}
		for _, v in ipairs(matches) do
			if not v.extra then
				table.insert(nmatches, v)
			end
		end
		matches = nmatches
	end
end
if false then
	print "MATCHES: "
	for _, v in ipairs(matches) do
		for _, vv in pairs(v) do
			print(_, vv)
		end
	end

--	for _, v in ipairs(hints) do
--		for _, vv in ipairs(hints) do
--			print(vv.word, vv.fuzzy, vv.lev)
--		end
--	end
end
]]--
	hints = lev_sort(hints)
	unknown = lev_sort(unknown)
	multi = lev_sort(multi)
	if #hints > 0 and #unknown > 0 then
		if hints.lev > unknown.lev then
			unknown = {}
		elseif hints.lev < unknown.lev then
			hints = {}
		end
	end
	return matches, hints, unknown, multi
end

local function get_events(self, ev)
	local events = {}
	self.aliases = {}
--	self.first_it = false
--	self.second_it = false
	self.multi = {}
	for _, v in ipairs(ev) do
		local ea = str_split(v)
		local e = ea[1]
		local args = {}
		table.remove(ea, 1)
		local reverse = false
		for _, vv in ipairs(ea) do
			if vv == 'reverse' then
				reverse = true
			end
		end
		local attrs = {}
		local holder
		for k, vv in ipairs(self.args) do
			if vv and std.is_obj(vv.ob) then
				attrs[k] = {}
				for _, h in ipairs(str_split(vv.morph, ",")) do
					attrs[k][h] = true
					if h == 'holder' then
						holder = vv
					end
				end
			end
		end

		for k, vv in ipairs(self.args) do
			if vv and std.is_obj(vv.ob) then
				local ob, m = multi_select(vv, attrs[k], holder)
				self.multi[ob] = m
				if reverse then
					table.insert(args, 1, ob)
				else
					table.insert(args, ob)
				end
				self.aliases[ob] = vv.alias
			end
		end

		if self.vargs and #self.vargs > 0 then
			local varg = ''
			for _, vv in ipairs(self.vargs) do
				if varg ~= '' then varg = varg .. ' ' end
				varg = varg .. vv
			end
			table.insert(args, varg)
		end
		if std.is_obj(args[1]) then
			self.first_it = args[1]
		end
		if std.is_obj(args[2]) then
			self.second_it = args[2]
		end
		table.insert(events, { ev = e, args = args })
	end
	return events
end

--- Take a value or run the function
--- returns two valuses. retval and true if method was called
-- @param wh what
-- @param fn function
function mp:runorval(wh, fn, ...)
	if wh[fn] == nil then
		return nil, false
	end
	if type(wh[fn]) == 'function' then
		local v
		local r = wh[fn](wh, ...)
		if r == false then v = false else v = true end
		return r, v
	end
	return wh[fn], true
end

function mp:call(ob, ev, ...)
--	self.event = ev
	for _, v in ipairs({ob, ...}) do
		if self.aliases[v] then
			std.rawset(v, '__word_alias', self.aliases[v])
		end
	end

--	self.reaction = std.pget() or false
	local r, v = std.call(ob, ev, ...)
--	std.cctx().txt = self.reaction
	self.reaction = self.reaction or v or false

	if self.debug.trace_action and v then
		dprint("mp:call ", ob, ev, ...)
		p("mp:call ", ob, " ", ev, " ")
		for _, t in ipairs {...} do
			pr (tostring(t), " ")
		end
		pn()
	end
	for _, a in ipairs(self.aliases) do
		std.rawset(a, '__word_alias', nil)
	end
	return r, v
end

function mp:events_call(events, oo, t)
	if not t then t = '' else t = t .. '_' end
	for _, o in ipairs(oo) do
		for _, e in ipairs(events) do
			self.event = e.ev
			local meta = self.event and self.event:find("Meta", 1, true)
			local ename = t .. e.ev
			local eany = t .. 'Any'
			local edef = t .. 'Default'
			local ob = o
			self.first = std.is_obj(e.args[1]) and e.args[1]
			self.second = std.is_obj(e.args[2]) and e.args[2]
			self.first_hint = self.first and self.first:gram().hint
			self.second_hint = self.second and self.second:gram().hint
			if o == 'obj' then
				ob = e.args[1]
				table.remove(e.args, 1)
			end
			local r, v
			if (meta and o == mp) or (not meta and std.is_obj(ob) and (o ~= 'obj' or ob ~= std.here())) then
				r, v = self:call(ob, eany, e.ev, std.unpack(e.args))
				if r then std.pn(r) end
				if not v then
					if ob[ename] then
						r, v = self:call(ob, ename, std.unpack(e.args))
						if r then std.pn(r) end
					else
						r, v = self:call(ob, edef, e.ev, std.unpack(e.args))
						if r then std.pn(r) end
					end
				end
			end
			if r then
				pn()
			end
			if o == 'obj' then
				table.insert(e.args, 1, ob)
			end
			if v and t ~= 'post_' then return v end
		end
	end
	return false
end

function mp:__action(events)
	local r
	self.reaction = false
	self.redirect = false
	r = self:events_call(events, { mp, game, std.here(), 'obj' }, 'before')
	if not r then
		r = self:events_call(events, { 'obj', std.here(), game, mp })
		if not r then
			self:events_call(events, { 'obj', std.here(), game, mp }, 'after')
		end
	end
	if not self.redirect then
		self:events_call(events, { 'obj', std.here(), game, mp }, 'post')
	end
end

function mp:save_ctx()
	return {
		first = self.first,
		second = self.second,
		first_hint = self.first_hint,
		second_hint = self.second_hint,
		event = self.event;
		xevent = self.xevent
	}
end

function mp:restore_ctx(ctx)
	self.first, self.second = ctx.first, ctx.second
	self.first_hint, self.second_hint = ctx.first_hint, ctx.second_hint
	self.event = ctx.event
	self.xevent = ctx.xevent
end

--- Execute a method
-- @usage mp:runmethods('before', 'LetGo', wh, w)
function mp:runmethods(t, verb, ...)
	local events = { {ev = verb, args = { ... }}}
	local ctx = self:save_ctx()
	self.xevent = self.event
	local r, v = self:events_call(events, { 'obj' }, t)
	self:restore_ctx(ctx)
	self.reaction = false
	return r, v
end

--- Execute a new sequence without terminating the current one
function mp:subaction(verb, ...)
	local events = { {ev = verb, args = { ... }}}
	local ctx = self:save_ctx()
	self.xevent = self.event
	local r, v = self:__action(events)
	self:restore_ctx(ctx)
	self.reaction = false
	return r, v
end

--- Switch the sequence to a new event
function mp:xaction(verb, ...)
	local events = { {ev = verb, args = { ... }}}
	local r, v = self:__action(events)
	self.redirect = true
	return r, v
end

function mp:action()
	local parsed = self.parsed
	local ev = str_split(parsed.ev, "|")
	local events = get_events(self, ev)
	self:__action(events)
end

function mp:correct(inp)
	if self:comment() then
		return
	end

	local rinp = ''

	for _, v in ipairs(self.parsed) do
		if rinp ~= '' then rinp = rinp .. ' ' end
		rinp = rinp .. v
	end
	local cmprinp = rinp:gsub("["..inp_split.."]+", " ")
	if not self:eq(cmprinp, inp) then
		pn(fmt.em("("..rinp..")"))
	end
end

function mp:log(t)
	if mp.logfile then
		t = std.fmt(t)
		local f = io.open(mp.logfile, "a+b")
		if not f then return end
		f:write((t or '').."\n\n")
		f:close()
	end
end

function mp:show_prompt(inp)
	if std.cmd[1] == 'look' then
		return false
	end
	if std.here():has 'cutscene' or std.here():has 'noprompt' or player_moved() or std.abort_cmd then
		return false
	end
	if self.prompt then
		pn(fmt.b(self.prompt .. inp))
	end
	return true
end

function mp:comment()
	if self.inp:find("^[ \t]*%*") then return true end
end

--- Main parse function. Input goes here
function mp:parse(inp)
	inp = std.strip(inp)

	if self.expert_mode and not self:comment() and not std.here():type'dlg' then
		local multi_inp = str_split(inp, ".\r\n") or {}

		inp = multi_inp[1] or inp

		for i = 2, #multi_inp do
			self:push(multi_inp[i])
		end
	end

	mp:log("> "..inp)

	local noprompt = not mp:show_prompt(inp)

	inp = inp:gsub("[ ]+", " "):gsub("["..inp_split.."]+", " "):gsub("[ \t]+$", "")

	local r, v

	if self:comment() then
		r = false
		v = nil
	else
		r, v = self:input(self:norm(inp))
	end
	self.cache = { tokens = {} }; -- to completion
	if not r then
		if v then
--			pn()
			self:err(v)
			local s = std.game
			s:reaction(std.pget())
			r = s:display(false)
			s:lastdisp(r)
			return r, false
		end
	else
		if std.cmd[1] ~= 'look' and not noprompt then
			self:correct(inp)
		end
		-- here we do action
		mp:action()
	end
	mp:post_action()
end

std.world.display = function(s, state)
	local l, av, pv
	if mp.text == '' and game:time() == 1 and state ~= false then
		local r = std.call(game, 'dsc')
		mp.text = r .. '^^'
	end
	if mp.clear_on_move then
		if player_moved() then mp:clear() end
	end
--	mp:trim()
	local reaction = s:reaction() or nil
	if state then
--		reaction = iface:em(reaction)
		av, pv = s:events()
		av = iface:em(av)
		pv = iface:em(pv)
		if s.player:need_scene() then
--			t = iface:bold(std.titleof(stead.here()))
			l = s.player:look() -- objects [and scene]
		end
	end
	l = std.par(std.scene_delim, reaction or false,
		    av or false, l or false,
		    pv or false) or ''
	mp:log(l)
	mp.text = mp.text ..  l .. '^^' -- .. fmt.anchor()
	return mp.text
end

function mp:completion(word)
	self.inp = self:docompl(self.inp, word)
	self.cur = self.inp:len() + 1
	self:compl_fill(self:compl(self.inp))
end

function mp:key_history_prev()
	if #self.history == 0 then
		return
	end
	self.history_pos = self.history_pos + 1
	if self.history_pos > #self.history then
		self.history_pos = #self.history
	end
	self.inp = self.history[self.history_pos]
	self.cur = self.inp:len() + 1
	return true
end

function mp:key_history_next()
	if #self.history == 0 then
		return
	end
	self.history_pos = self.history_pos - 1
	if self.history_pos < 1 then
		self.history_pos = 0
		self.inp = ''
		self.cur = 1
		return true
	end
	self.inp = self.history[self.history_pos]
	self.cur = self.inp:len() + 1
	return true
end

--- Add input string to auto execution mode
-- @param cmd input string
function mp:push(cmd)
	if not cmd then
		return false
	end
	table.insert(self.pushed, cmd)
end

--- Returns true if some auto command is pending
function mp:autoplay_pending()
	return self.autoplay or #self.pushed > 0 or self.autoplay_command
end

--- Internal function that gets commands from script or pushed commands
-- @see mp:push
function mp:autoplay_inp()
	local auto_inp = false
	self.autoplay_command = false
	if #self.pushed > 0 then
		auto_inp = table.remove(self.pushed, 1)
	elseif not self.autoplay then
		return false
	end
	self.inp = auto_inp or self.autoplay:read("*line") or false
	if not self.inp then
		self.inp = ''
		self.autoplay:close()
		self.autoplay = false
	else
		if not auto_inp then
			dprint("> ", self.inp)
		end
		self.autoplay_command = true
	end
	return true
end

function mp:key_enter()
	if self:noparser() then
		return
	end
	if not mp:autoplay_pending() and
		(#self.history == 0 or self.history[1] ~= self.inp) and std.strip(self.inp) ~= '' then
		table.insert(self.history, 1, self.inp)
	end
	self.history_pos = 0
	if #self.history > self.history_len then
		table.remove(self.history, #self.history)
	end
	self:compl_reset();
	local r, v = std.call(mp, 'parse', self.inp)
	self.inp = '';
--[[
	if std.here():has'cutscene' then
		self.inp = mp.cutscene.default_Verb or ''
		if self.inp ~= '' then
			self.inp = self.inp .. ' '
		end
	end
]]--
	self:autoplay_inp()

	self.cur = self.inp:len() + 1;
	post_inp()
--	self:completion()
	return r, v
end

function mp:lookup_noun(w, lev)
	local k, len
	local res = {}
	local oo = self:nouns()
	for _, o in ipairs(oo) do
		local ww = {}
		o:noun(ww)
		for _, d in ipairs(ww) do
			k, len = word_search(w, d.word, lev)
			if k and len == #w then
				d.ob = o
				table.insert(res, d)
				break
			end
		end
	end
	if #res == 0 then
		return res
	end
	local uniq = {}
	local same
	for _, v in ipairs(res) do
		local t = v.ob:noun(v.alias)
		if not uniq[t] then
			uniq[t] = v
		else
			same = true
		end
	end
	res = {}
	for _, v in pairs(uniq) do
		table.insert(res, v)
	end
	table.sort(res, function(a, b)
		return a.word:len() > b.word:len()
	end)
	if same then
		res = { res[1] }
	end
	self.aliases = {}
	for _, o in ipairs(res) do
		self.aliases[o.ob] = o.alias
	end
	return res
end

function mp:shorten_input(w)
	if #w < 1 or std.here():type 'dlg' then
		return
	end
	local str
	if #w == 1 and self.shorten[w[1]] then
		str = self.shorten[w[1]]
	end
	if self.expert_mode and not str and
		self.shorten_expert[w[1]] then
		str = self.shorten_expert[w[1]]
	end
	if not str then
		return
	end
	local t = str_split(str, inp_split)
	table.remove(w, 1)
	for i, v in ipairs(t) do
		table.insert(w, i, v)
	end
end

function mp:input(str)
--	self.cache = { tokens = {} };
	local hints = {}
	local unknown = {}
	local multi = {}
	self.hints = hints
	self.unknown = unknown
	self.multi = multi

	if (self.default_Verb or std.here().default_Verb) and str == "" then
		str = std.here().default_Verb or self.default_Verb
	end
	if type(mp.pre_input) == 'function' then
		str = mp:pre_input(str)
		if not str then return false end
	end
	local w = str_split(str, inp_split)
	mp:shorten_input(w)
	self.words = w
	if #w == 0 then
		return false, "EMPTY_INPUT"
	end
	local ob = self:lookup_noun(w)
	local verbs = {}
	if #ob == 0 then
		verbs = self:lookup_verb(w)
	end
	if #verbs == 0 then
		-- match object?
		if #ob > 1 then
			self.multi = {}
			for _, v in ipairs(ob) do
				table.insert(self.multi, v.ob:noun(v.alias))
			end
			return false, "MULTIPLE"
		end

		if #ob == 0 then -- try fuzzy
			if not mp.errhints then
				return false, "UNKNOWN_VERB"
			end
			ob = self:lookup_noun(w, self.lev_thresh)
			if #ob >= 1 then
				for _, v in ipairs(ob) do
					table.insert(self.hints, v.word)
				end
				return false, "UNKNOWN_WORD"
			end
			return false, "UNKNOWN_VERB"
		end

		-- it is the object!
		if ob[1].ob.default_Event then
			w = std.call(ob[1].ob, 'default_Event')
		else
			w = self.default_Event or "Exam"
		end
--		pn()
		mp.first_it = ob[1].ob
		self:xaction(w, ob[1].ob)
--		verbs = self:lookup_verb(w)
--		if #verbs == 0 then
--			return false, "UNKNOWN_VERB"
--		end
		return
	end
	local matches = {}
	for _, v in ipairs(verbs) do
		local m, h, u, mu = self:match(v, w)
		if #m > 0 then
			table.insert(matches, { verb = v, match = m[1] })
		end
		if #h > 0 then
			table.insert(hints, h)
		end
		if #u > 0 then
			table.insert(unknown, u)
		end
		if #mu > 0 then
			table.insert(multi, mu)
		end
	end
	table.sort(matches, function(a, b) return #a.match > #b.match end)
	hints = lev_sort(hints)
	unknown = lev_sort(unknown)
	multi = lev_sort(multi)
	local mlev = #matches > 0 and #matches[1].match or 0
	if (hints.lev or 0)> mlev or (unknown.lev or 0) > mlev then
		matches = {}
	end

	if #matches == 0 then
		self.hints = hints
		self.unknown = unknown
		self.multi = multi
		if #multi > 0 then
			self.multi = multi
			return false, "MULTIPLE"
		end
		return false, "INCOMPLETE"
	end
	self.parsed = matches[1].match
	self.args = self.parsed.args
	self.vargs = self.parsed.vargs or {}
	return true
end

function MetaVerb(t)
	return mp:verb(t, mp)
end

function Verb(t, w)
	return mp:verb(t, w)
end

function VerbExtend(t, w)
	return mp:verb(t, w or false, true)
end

function VerbRemove(t, w)
	return mp:verb_remove(t, w)
end

function VerbHint(t, fn, w)
	local v = mp:verb_find(t, w)
	if not v then
		dprint("Unknown verb: " .. tostring(t))
		return
	end
	if v then v.hint = fn end
end
std.rawset(_G, 'mp', mp)
std.mod_cmd(
function(cmd)
	if cmd[1] == '@metaparser' then
		mp.inp = cmd[2] or ''
		cmd[1] = '@mp_key'
		cmd[2] = 'enter'
	end
	if cmd[2] == '@metaparser' then
		if cmd[3] == '<clear>' then
			mp.inp = '';
			mp.cur = 1;
			mp:compl_fill(mp:compl(mp.inp))
			return true, false
		elseif cmd[3] == '<enter>' then
			return mp:key_enter()
		end
		if cmd[3] == '<space>' then
			mp:inp_insert(' ')
			mp:compl_fill(mp:compl(mp.inp))
			return true, false
		end
		if cmd[3] == '<backspace>' then
			mp:inp_remove()
			mp:compl_fill(mp:compl(mp.inp))
			return true, false
		end
		if cmd[4] == 'letter' then
			mp.inp = mp.inp .. cmd[3]
			mp.cur = mp.inp:len() + 1
		else
			mp:completion(cmd[3])
		end
		return true, false
	end
	if (cmd[1] == '@mp_key' and cmd[2] == 'enter') or cmd[1] == 'look' then
		mp:trim()
		if not std.game.__started and cmd[1] == 'look' then
			std.game:__start()
		end
		if mp:noparser() then
			return true, false
		end
--		mp.inp = mp:docompl(mp.inp)
		local r, v, n
		repeat
			if n then
				std.abort_cmd = false
				std.me():moved(false)
				std.me():need_scene(false)
			end
			r, v = mp:key_enter(cmd[1] == 'look')
			n = true
		until not mp:autoplay_pending() or mp:noparser()
		return r, v
	end
	if cmd[1] ~= '@mp_key' then
		return
	end
	return true, false
end)

function mp:autoscript(w)
	if self.autoplay then
		self.autoplay:close()
	end
	self.autoplay = io.open(w or 'autoscript') or false
	if self.autoplay then
		self:MetaTranscriptOn();
		std.cmd = { 'autoscript' }
		return true
	end
	return false
end

std.mod_init(
function()
	if DEBUG and mp.undo == 0 then mp.undo = 5 end
	_'game'.__daemons = std.list {}
end)

function mp:init(lang)
	if type(std.SOURCES_DIRS) == 'table' then
		mrd.dirs = std.SOURCES_DIRS
	end
	mrd:init(lang)
	cutscene = mp.cutscene
	gameover = mp.gameover
	door = mp.door
end
std.mod_start(function()
	mp:compl_reset()
	mp:compl_fill(mp:compl(""))
--	if instead.text_input then instead.text_input(true) end
end, 2)
instead.mouse_filter(0)
-- speedup undo
local obusy = std.busy
local busy_count = 0
function std.busy()
	busy_count = busy_count + 1
	if (busy_count % 100) == 0 then
		obusy()
	end
end
function instead.fading()
	return instead.need_fading() or player_moved()
end

instead.notitle = true

instead.noways = true

local opr = std.pr

local function shortcut(ob, hint)
	return ob:noun(hint)
end

function mp.shortcut.where(hint)
	return shortcut(std.me():where(), hint)
end

function mp.shortcut.firstwhere(hint)
	return shortcut(mp.first:where(), hint)
end

function mp.shortcut.secondwhere(hint)
	return shortcut(mp.second:where(), hint)
end

function mp.shortcut.here(hint)
	return shortcut(std.here(), hint)
end

function mp.shortcut.first(hint)
	return shortcut(mp.first, hint)
end

function mp.shortcut.firstit(hint)
	return mp.first:it(hint)
end

function mp.shortcut.second(hint)
	return shortcut(mp.second, hint)
end

function mp.shortcut.me(hint)
	return shortcut(std.me(), hint)
end

mp.msg.verbs = {}

function mp.shortcut.verb(hint)
	local verb = mp.msg.verbs[hint]
	if not verb then
		return hint
	end
	return mp.shortcut.word(verb)
end

function mp:shortcut_obj(ob)
	if ob == '#first' then
		ob = mp.first
	elseif ob == '#second' then
		ob = mp.second
	elseif ob == '#firstwhere' then
		ob = mp.first:where()
	elseif ob == '#secondwhere' then
		ob = mp.second:where()
	elseif ob == '#me' then
		ob = std.me()
	elseif ob == '#where' then
		ob = std.me():where()
	elseif ob == '#here' then
		ob = std.here()
	else
		ob = false
	end
	return ob
end

local function hint_append(hint, h)
	if h == "" or not h then return hint end
	if hint == "" or not hint then return h end
	return hint .. ',' .. h
end

function mp.shortcut.word(hint)
	local w = str_split(hint, ",")
	if #w == 0 then
		return hint
	end
	local verb = w[1]
	table.remove(w, 1)
	hint = ''
	for _, k in ipairs(w) do
		if k == '#first' then
			hint = hint_append(hint, mp.first_hint)
		elseif k == '#second' then
			hint = hint_append(hint, mp.second_hint)
		elseif k:find("#", 1, true) == 1 then
			local ob = mp:shortcut_obj(k)
			if not ob then
				std.err("Wrong shortcut word: "..k, 2)
			end
			hint = hint_append(hint, ob:gram().hint)
		else
			hint = hint_append(hint, k)
		end
	end
	local t = mp.mrd:noun(verb .. '/' .. hint)
	return t
end

function mp.shortcut.if_hint(hint)
	local w = str_split(hint, ",")
	if #w < 3 then
		return hint
	end
	local attr = w[2]
	local ob = w[1]
	ob = mp:shortcut_obj(ob)
	if not ob then
		std.err("Wrong object in if_has shortcut: "..hint, 2)
	end
	if not ob:hint(attr) then
		return w[4] or ''
	end
	return w[3] or ''
end

function mp.shortcut.if_has(hint)
	local w = str_split(hint, ",")
	if #w < 3 then
		return hint
	end
	local attr = w[2]
	local ob = w[1]
	ob = mp:shortcut_obj(ob)
	if not ob then
		std.err("Wrong object in if_has shortcut: "..hint, 2)
	end
	if not ob:has(attr) then
		return w[4] or ''
	end
	return w[3] or ''
end

function std.pr(...)
	local args = {}
	local ctx = std.cctx()
	if not ctx or not ctx.self then
		return opr(...)
	end
	for _, v in ipairs({...}) do
		local finish
		if type(v) == 'string' then
		repeat
			finish = true
			v = v:gsub("{#[^{}]*}", function(w)
				local ww = w
				w = w:gsub("^{#", ""):gsub("}$", "")
				local hint = w:gsub("^[^/]*/?", "")
				w = w:gsub("/[^/]*$", "")
				local cap = mp.mrd.lang.is_cap(w)
				w = w:lower()
				if mp.shortcut[w] then
					w = mp.shortcut[w](hint)
					if cap then
						w = mp.mrd.lang.cap(w)
					end
				else
					std.err("Wrong shortcut: ".. ww, 2)
				end
				finish = false
				return w
			end)
		until finish
		end
		table.insert(args, v)
	end
	return opr(std.unpack(args))
end

function std.obj:persist()
	self:attr 'persist'
	mp.persistent:add(self)
	return self
end

function std.obj:hint(hint)
	return self:gram()[mrd.lang.gram_t[hint] or hint]
end

--- Return a pronoun for the object (capitalized).
-- @see mp:it
function mp:It(w, hint)
	local t = self:it(w, hint)
	return mp.mrd.lang.cap(t)
end

--- Return a pronoun for the object.
-- This is language-dependent.
-- @param hint pronoun case
-- @see mp:it
function std.obj:it(hint)
	if mp.it then
		return mp:it(self, hint)
	else
		if self:hint'plural' then
			return 'they'
		elseif self:hint'female' then
			return 'she'
		elseif self:hint 'male' then
			return 'he'
		else
			return "it"
		end
	end
end

function std.obj:It(hint)
	local t = self:it(hint)
	return mp.mrd.lang.cap(t)
end

function mp:traceinside(w, fn)
	local ww = w and w.obj or std.here().obj
	while #ww > 0 do
		local nww = {}
		for _, o in ipairs(ww) do
			local r, v = fn(o)
			if r ~= nil then
				return r
			end
			if v ~= false then
				for _, vv in ipairs(o.obj) do
					table.insert(nww, vv)
				end
			end
		end
		ww = nww
	end
end

--- Trace an object upwards (check every parent)
-- @param w where
-- @param fn function
function mp:trace(w, fn)
	local ww = {}
	w:where(ww)
	while #ww > 0 do
		local nww = {}
		for _, o in ipairs(ww) do
			local r, v = fn(o)
			if r ~= nil then
				return r
			end
			if v ~= false then
				o:where(nww)
			end
		end
		ww = nww
	end
end

function std.obj:attr(str)
	local a = str_split(str, ", ")
	for _, v in ipairs(a) do
		local val =  (v:find("~", 1, true) ~= 1)
		v = v:gsub("^~", "")
		self['__attr__' .. v] = val
	end
	return self
end

function std.obj:hasnt(attr)
	return not self:has(attr)
end

function std.obj:has(attr)
	attr = std.strip(attr)
	local val =  (attr:find("~", 1, true) ~= 1)
	attr = attr:gsub("^~", "")
	if val then
		return self['__attr__' .. attr]
	else
		return not self['__attr__' .. attr]
	end
end

function iface:title(t)
	return(iface:bold( mrd.lang.cap(t)))
end
