require "fmt"
if std.ref'@theme' then
	std.ref'@theme'.set ('win.scroll.mode', 3)
end

local mrd = require "morph/mrd"
local inp_split = " :.,!?"

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
	while b:byte(i) >= 0x80 and b:byte(i) <= 0xbf do
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
	local n = 0
	local s
	local res = {}
	while i <= b:len() do
		s = i
		i = i + utf_ff(b, i)
		table.insert(res,  b:sub(s, i - 1))
	end
	return res
end

-- Returns the Levenshtein distance between the two given strings
-- https://gist.github.com/Badgerati/3261142

local function utf_lev(str1, str2)
	str1 = str1 or ''
	str2 = str2 or ''
	local chars1 = utf_chars(str1)
	local chars2 = utf_chars(str2)
	local len1 = #chars1
	local len2 = #chars2
	local matrix = {}
	local cost = 0

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

function input:key(press, key)
	local a
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
			if mp.autohelp then
				mp:compl_fill(mp:compl(mp.inp))
			elseif mp.autocompl then
				mp:compl(mp.inp)
			end
			return '@mp_key '..tostring(key)
		end
	end
	if okey then
		return okey(self, press, key)
	end
end

mp = std.obj {
	nam = '@metaparser';
	autohelp = false;
	autocompl = true;
	compl_thresh = 0;
	daemons = std.list {};
	{
		version = "0.1";
		cache = { tokens = {} };
		scope = std.list {};
		logfile = false;
		lognum = 0;
		inp = '';
		cur = 1;
		utf = {
			bb = utf_bb;
			ff = utf_ff;
			len = utf_len;
			char = utf_char;
		};
		lev_thresh = 3;
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
		aliases = {};
		first = false;
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
	};
	text = '';
	-- dict = {};
}

function mp:trim()
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
	if key == 'f1' then
		self.autohelp = not self.autohelp
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

instead.get_inv = std.cacheable('inv', function(horiz)
	if std.here().noparser or game.noparser then
		return
	end
	local delim = instead.hinv_delim
	if not horiz then
		delim = instead.inv_delim
	end
	local pre, post = mp:inp_split()
	local ret = iface:bold(mp.prompt) .. mp:esc(pre)..mp.cursor..mp:esc(post) .. '\n'
	if not mp.autohelp and not std.here().forcehelp then
		return ret
	end
	delim = delim or ' | '

--	local ww = str_split(mp.inp, inp_split)

--	if utf_len(ww[#ww]) < 3 or mp.inp:find(" $") or true then
--		return ret
--	end

	for _, v in ipairs(mp.completions) do
		local t = iface:xref(std.fmt(v.word), mp, v.word)
		if v.ob and have(v.ob) then t = iface:em(t) end
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
	if not self:offerslight(std.me():where()) then
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
	for _, o in ipairs(oo) do
		local d = {}
		local r = o:noun(attr, d)
		for k, v in ipairs(d) do
			local hidden = (k ~= 1) or w.hidden
			if o:has 'multi' then
				hidden = w.hidden or (v.idx ~= 1)
			end
			if o == std.me() and mp.myself then
				for _, v in ipairs(mp:myself(o, w.morph)) do
					table.insert(ww, { optional = w.optional, word = v, morph = attr, ob = o, alias = o.alias, hidden = hidden })
				end
				break
			else
				table.insert(ww, { optional = w.optional, word = r[k], ob = o, morph = attr, alias = v.alias, hidden = hidden })
			end
		end
		if o == mp.first then
			for _, v in ipairs(mp:synonyms(o, w.morph)) do
				table.insert(ww, { optional = w.optional, word = v, ob = o, morph = attr, alias = o.alias, hidden = true })
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

function mp:eq(t1, t2, lev)
	if t1:find("%*$") then
		local t = t1:gsub("%*$", "")
		return self:__startswith(t2, t)
	end
	if lev then
		local l = utf_lev(t1, t2)
		if l < lev then
			return l
		end
		return false
	end
	return self:norm(t1) == self:norm(t2)
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
			w.word = v
			table.insert(words, w)
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
		table.remove(w or game, k)
	end
	return v
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
			local hidden = false
			if pat[1] == '~' then
				table.remove(pat, 1)
				hidden = true
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
	local ret = {}
	local w = std.here().__Verbs or std.me().__Verbs or game.__Verbs or {}
	return w
end

local function word_search(t, w, lev)
	local rlev
	w = str_split(w, inp_split)
	for k = 1, #t - #w + 1 do
		local found = true
		for i = 1, #w do
			local found2 = false
			for ii = k, k + #w - 1 do
				rlev = mp:eq(w[i], t[ii], lev)
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

function mp:lookup_verb(words, lev)
	local ret = {}
	local w = self:verbs()
	for _, v in ipairs(w) do -- verbs
		local found = false
		local lev_v = {}
		for _, vv in ipairs(v.verb) do
			local verb = vv.word .. (vv.morph or "")
			local i, len, rlev
			i, len, rlev = word_search(words, verb, lev and self.lev_thresh)
			if not i and not lev and verb ~= vv.word then
				i, len = self:lookup_short(words, vv.word)
			end
			if i then
				if lev then
					table.insert(lev_v, { lev = rlev, verb = v, verb_nr = i, verb_len = len, word_nr = _ } )
				else
					v.verb_nr = i
					v.verb_len = len
					v.word_nr = _
					table.insert(ret, v)
				end
			end
		end
		if lev and #lev_v > 0 then
			table.sort(lev_v, function(a, b)
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
				   return a.lev < b.lev
		end)
		ret = { ret[1] }
	elseif #ret > 0 then
		table.sort(ret, function(a, b)
			return a.verb_nr < b.verb_nr
		end)
		local lev = ret[1].verb_nr
		local ret2 = {}
		for _, v in ipairs(ret) do
			if v.verb_nr == lev then
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

function mp:docompl(str, maxw)
	local full = false
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
					if utf_maxw[k] == utf_word[k] then
						maxw2 = maxw2 .. utf_maxw[k]
					else
						full = false
						break
					end
				end
				maxw = maxw2
			end
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
		for _, vv in ipairs(game.hint_verbs) do
			if v.tag == vv then
				r = true
				break
			end
		end
	end
	return r
end
function mp:compl_verb(words)
	local dups = {}
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
	return w:has'animate' or w:hint'live'
end

function mp:compl_filter(v)
	if v.hidden then return false end
	local inp, pre = self:compl_ctx()
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
		supporter = false;
		live = false,
	}
	for _, h in ipairs(str_split(v.morph, ",")) do
		if attrs[h] ~= nil then attrs[h] = h end
	end
	for _, a in ipairs { 'container', 'enterable', 'supporter' } do
		if attrs[a] and not v.ob:has(a) then return false end
	end
	if attrs.live and not self:animate(v.ob) then return false end
	if attrs.inside and not v.ob:has'container' and not v.ob:has'supporter' then return false end
	if not attrs.held and not attrs.scene then return true end
	if attrs.held and have(v.ob) then return true end
	if attrs.scene and (not have(v.ob) and v.ob ~= std.me()) then return true end
	return false
end

function mp:compl_fill(compl, eol, vargs)
	local ctx = self.completions.ctx
	self.completions = {}
	self.completions.ctx = ctx
	self.completions.eol = eol
	self.completions.vargs = vargs
	local w = str_split(self.inp, inp_split)
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
	local top = 0
	for k, v in ipairs(ctx) do
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
	local inp = self:norm(self.inp)
	local ctx_inp = self:norm(ctx[top].inp)
	local s, e = inp:find(ctx_inp, 1, true)
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
		if self:startswith(v.word, pre) then
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
				dups[v.word] = true
				table.insert(ret, v)
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
	local fuzzy = {}
	for _, v in ipairs(t) do if v.fuzzy then table.insert(fuzzy, v) end end
	if #fuzzy > 0 then
		t = fuzzy
		t.fuzzy = true
	end
	for _, v in ipairs(t) do v.i = _ end
	table.sort(t, function(a, b)
			   if a.lev == b.lev then return a.i < b.i end
			   return a.lev > b.lev
	end)
	local lev = t[1] and t[1].lev
	local res = {}
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
	local verb = { words[1] }
	local verbs = self:lookup_verb(verb)
--	table.remove(words, 1) -- remove verb
	local matches = {}
	local hints = {}
	local res = {}
	local dup = {}
	local multi
	collectgarbage("stop")
	for _, v in ipairs(verbs) do
		local m, h, u, mu = self:match(v, words, true)
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
	for _, d in ipairs(verb.dsc) do -- verb variants
		local match = { args = {}, vargs = {}, ev = d.ev }
		local a = {}
		found = (#d.pat == 0)
		for k, v in ipairs(w) do
			if k < verb.verb_nr or k >= verb.verb_nr + verb.verb_len then
				table.insert(a, v)
			end
		end
		local all_optional = true
		local rlev = 1
		local need_required = false
		for lev, v in ipairs(d.pat) do -- pattern arguments
			if v == '*' or v == '~*' then
				vargs = true -- found
				v = '*'
			end
			local pat = self:pattern(v) -- pat -- possible words
			local best = #a + 1
			local best_len = 1
			local word
			local required
			found = false
			for _, pp in ipairs(pat) do -- single argument
				if v == '*' then break end
				if not pp.optional then
					required = true
					need_required = true
					all_optional = false
				end
				if pp.default then
					word = pp.word
				end
				local k, len = word_search(a, pp.word)
				if k and (k < best or len > best_len) then
					best = k
					word = pp.word
					found = pp
					best_len = len
					if word:find("%*$") then -- subst
						word = found.ob:noun(found.morph, found.alias)
					end
				end
			end
			if found then
				need_required = false
				if found.ob then
					local same
					for _, pp in ipairs(pat) do
						if pp.ob and self:eq(found.word, pp.word) then
							if not found.multi then
								found.multi = {}
							end
							table.insert(found.multi, pp.ob)
							if found.ob:noun(found.alias) ~= pp.ob:noun(pp.alias) then
								table.insert(multi, { word = pp.ob:noun(pp.alias), lev = rlev })
							end
						end
					end
					if #multi > 0 then
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
					rlev = rlev + 1
					vargs = false
				end
				if false then
					a = tab_exclude(a, best, best + best_len - 1)
				else
					a = tab_sub(a, best + best_len)
--					table.remove(a, 1)
				end
				table.insert(match, word)
				table.insert(match.args, found)
				rlev = rlev + 1
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
					table.insert(unknown, { word = a[i], lev = rlev })
				end
				if not compl then
					for _, pp in ipairs(pat) do -- single argument
						local k, len = word_search(a, pp.word, self.lev_thresh)
						if k then table.insert(hints, { word = pp.word, lev = rlev, fuzzy2 = true }) end
					end
				end
				table.insert(hints, { word = v, lev = rlev })
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
		if #multi > 0 then
			matches = {}
			break
		end
		if found or all_optional then
			local fixed = verb.verb[verb.word_nr]
			fixed = fixed.word .. (fixed.morph or '')
			match.extra = (#a ~= 0)
			table.insert(match, 1, fixed) -- w[verb.verb_nr])
			table.insert(matches, match)
			if #match.vargs == 0 and not vargs then
				match.vargs = false
			end
		end
	end

	table.sort(matches, function(a, b) return #a > #b end)

	if #unknown > 0 and #matches > 0 then
		local lev = #matches[1]
		for k, v in ipairs(unknown) do
			if v.lev >= lev then
				matches = {}
				break
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
]]--
if false then
	print "MATCHES: "
	for _, v in ipairs(matches) do
		for _, vv in pairs(v.args) do
			print(_, vv)
		end
	end

	for _, v in ipairs(hints) do
		for _, vv in ipairs(hints) do
			print(vv.word, vv.fuzzy, vv.lev)
		end
	end
end
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

function mp:err(err)
	if std.here().OnError then
		std.here():OnError(err)
		return
	end
	if err == "UNKNOWN_VERB" then
		local verbs = self:lookup_verb(self.words, true)
		local hint = false
		if verbs and #verbs > 0 then
			for _, verb in ipairs(verbs) do
				local fixed = verb.verb[verb.word_nr]
				if verb.lev < self.lev_thresh and verb.verb_nr == 1 then
					hint = true
					p (self.msg.UNKNOWN_VERB, " ", iface:em(self.words[verb.verb_nr]), ".")
					pn(self.msg.UNKNOWN_VERB_HINT, " ", iface:em(fixed.word .. (fixed.morph or "")), "?")
				end
			end
		end
		if not hint then
			p (self.msg.UNKNOWN_VERB or "Unknown verb:", " ", iface:em(self.words[1]), ".")
		end
	elseif err == "EMPTY_INPUT" then
		p (self.msg.EMPTY or "Empty input.")
	elseif err == "INCOMPLETE" or err == "UNKNOWN_WORD" then
		local need_noun
		for _, v in ipairs(self.hints) do
			if v:find("^~?{noun}") then need_noun = true break end
		end
		if #self.unknown > 0 then
			local unk = ''
			for _, v in ipairs(self.unknown) do
				if unk ~= '' then unk = unk .. ' ' end
				unk = unk .. v
			end
			if need_noun then
				p (self.msg.UNKNOWN_OBJ, iface:em(" (" .. unk .. ")."))
			else
				p (self.msg.UNKNOWN_WORD, iface:em(" ("..unk..")."))
			end
			if mp:thedark() and need_noun then
				p (self.msg.UNKNOWN_THEDARK)
				return
			end
			if need_noun then
--				return
			end
		elseif err == "UNKNOWN_WORD" then
			p (self.msg.UNKNOWN_WORD, ".")
		else
			p (self.msg.INCOMPLETE)
		end

		local words = {}
		local dups = {}
		for kk, v in ipairs(self.hints) do
			if v:find("^~?{noun}") or v == '*' then
				v = mp:err_noun(v)
				if not dups[v] then
					table.insert(words, v)
					dups[v] = true
				end
			else
				local pat = self:pattern(v)
				for _, v in ipairs(pat) do
					if not v.hidden and not dups[v.word] then
						table.insert(words, v.word)
						dups[v.word] = true
					end
				end
			end
			if need_noun then
				break
			end
		end
		if #words > 0 then
			p (self.msg.HINT_WORDS, " ")
		end

		for k, v in ipairs(words) do
			if k ~= 1 then
				if k == #words then
					pr (" ", mp.msg.HINT_OR, " ")
				else
					pr (", ")
				end
			end
			pr(iface:em(v))
		end
		if #words > 0 then
			p "?"
		end
	elseif err == "MULTIPLE" then
		pr (self.msg.MULTIPLE, " ", self.multi[1])
		for k = 2, #self.multi do
			if k == #self.multi then
				pr (" ", mp.msg.HINT_AND, " ", self.multi[k])
			else
				pr (", ", self.multi[k])
			end
		end
		pr "."
	end
end

local function get_events(self, ev)
	local events = {}
	self.aliases = {}
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
		for _, vv in ipairs(self.args) do
			if vv and std.is_obj(vv.ob) then
				local attrs = {}
				for _, h in ipairs(str_split(vv.morph, ",")) do
					attrs[h] = true
				end
				local ob = vv.ob
				for _, h in ipairs(vv.multi) do
					if attrs.held and not have(vv.ob) and have(h) then
						ob = h
						break
					elseif attrs.scene and have(vv.ob) and not have(h) then
						ob = h
						break
					end
				end
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
		table.insert(events, { ev = e, args = args })
	end
	return events
end

function mp:runorval(wh, fn, ...)
	if wh[fn] == nil then
		return nil, false
	end
	if type(wh[fn]) == 'function' then
		local v
		local r = wh[fn](...)
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
	for _, v in ipairs(self.aliases) do
		std.rawset(v, '__word_alias', nil)
	end
	return r, v
end

function mp:events_call(events, oo, t)
	if not t then t = '' else t = t .. '_' end
	for _, o in ipairs(oo) do
		for _, e in ipairs(events) do
			self.event = e.ev
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
			if std.is_obj(ob) and (o ~= 'obj' or ob ~= std.here()) then
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
	r = self:events_call(events, { parser, game, std.here(), 'obj' }, 'before')
	if not r then
		r = self:events_call(events, { 'obj', std.here(), game, parser })
		if not r then
			r = self:events_call(events, { 'obj', std.here(), game, parser }, 'after')
		end
	end
	if not self.redirect then
		self:events_call(events, { 'obj', std.here(), game, parser }, 'post')
	end
end

function mp:save_ctx()
	return {
		first = self.first,
		second = self.second,
		first_hint = self.first_hint,
		second_hint = self.second_hint,
		event = self.event;
	}
end

function mp:restore_ctx(ctx)
	self.first, self.second = ctx.first, ctx.second
	self.first_hint, self.second_hint = ctx.first_hint, ctx.second_hint
	self.event = ctx.event
end

function mp:runmethods(t, verb, ...)
	local events = { {ev = verb, args = { ... }}}
	local ctx = self:save_ctx()
	local r, v = self:events_call(events, { 'obj' }, t)
	self:restore_ctx(ctx)
	self.reaction = false
	return r, v
end

function mp:subaction(verb, ...)
	local events = { {ev = verb, args = { ... }}}
	local ctx = self:save_ctx()
	local r, v = self:__action(events)
	self:restore_ctx(ctx)
	self.reaction = false
	return r, v
end

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
	local r
	self:__action(events)
end

function mp:correct(inp)
	local rinp = ''
	for _, v in ipairs(self.parsed) do
		if rinp ~= '' then rinp = rinp .. ' ' end
		rinp = rinp .. v
	end
	if not self:eq(rinp, inp) then
		pn(fmt.em("("..rinp..")"))
	end
end
function mp:log(t)
	if mp.logfile then
		t = std.fmt(t)
		local f = io.open(mp.logfile, "a+b")
		if not f then return end
		f:write((t or '').."\n")
		f:close()
	end
end
function mp:parse(inp)
	inp = std.strip(inp)
	if std.cmd[1] ~= 'look' then
		pn(fmt.b(self.prompt .. inp))
	end
	inp = inp:gsub("[ ]+", " "):gsub("["..inp_split.."]+", " ")
	local r, v = self:input(self:norm(inp))
	self.cache = { tokens = {} }; -- to completion
	if not r then
		if v then
			pn()
			self:err(v)
		end
		return
	end
	if std.cmd[1] ~= 'look' then
		self:correct(inp)
		pn()
	end
	local t = std.pget()
	std.pclr()
	-- here we do action
	mp:action()
	local tt = std.pget()
	std.pclr()
	pr(t or '', tt or '')
end

std.world.display = function(s, state)
	local l, av, pv
	if mp.text == '' and game:time() == 1 then
		local r = std.call(game, 'dsc')
		mp.text = r .. '^^'
	end
	if player_moved() then mp.text = '' end
	mp:trim()
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

function mp:key_enter()
	if std.here().noparser or game.noparser then
		return
	end
	if (#self.history == 0 or self.history[1] ~= self.inp) and std.strip(self.inp) ~= '' then
		table.insert(self.history, 1, self.inp)
	end
	self.history_pos = 0
	if #self.history > self.history_len then
		table.remove(self.history, #self.history)
	end
	self:compl_reset();
	local r, v = std.call(mp, 'parse', self.inp)
	self.inp = '';
	self.cur = 1;
	if self.autohelp then
		self:compl_fill(self:compl(self.inp))
	elseif self.autocompl then
		self:compl(self.inp)
	end
--	self:completion()
	return r, v
end

function mp:lookup_noun(w, lev)
	local oo = {}
	local k, len
	local res = {}
	oo = self:nouns()
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
	for k, v in pairs(uniq) do
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
	local w = str_split(str, inp_split)
	self.words = w
	if #w == 0 then
		return false, "EMPTY_INPUT"
	end
	local verbs = self:lookup_verb(w)
	if #verbs == 0 then
		-- match object?
		local ob = self:lookup_noun(w)
		if #ob > 1 then
			self.multi = {}
			for _, v in ipairs(ob) do
				table.insert(self.multi, v.ob:noun(v.alias))
			end
			return false, "MULTIPLE"
		end

		if #ob == 0 then -- try fuzzy
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
		pn()
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
		table.insert(hints, h)
		table.insert(unknown, u)
		table.insert(multi, mu)
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
	if v then v.hint = fn end
end
std.rawset(_G, 'mp', mp)
std.mod_cmd(
function(cmd)
	if cmd[2] == '@metaparser' then
		if cmd[3] == '<enter>' then
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
		if std.here().noparser or game.noparser then
			return true, false
		end
--		mp.inp = mp:docompl(mp.inp)
		return mp:key_enter(cmd[1] == 'look')
	end
	if cmd[1] ~= '@mp_key' then
		return
	end
	return true, false
end)
std.mod_init(
function(load)
	_'game'.__daemons = std.list {}
end)

function mp:init()
	mrd:gramtab("morph/rgramtab.tab")
	local _, crc = mrd:load("dict.mrd")
	mrd:create("dict.mrd", crc) -- create or update
end
std.mod_start(function()
	mp:compl_reset()
	mp:compl_fill(mp:compl(""))
end)
instead.mouse_filter(0)

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

function mp.shortcut.word(hint)
	local w = str_split(hint, ",")
	if #w == 0 then
		return hint
	end
	local verb = w[1]
	table.remove(w, 1)
	local hint = ''
	for _, k in ipairs(w) do
		if k == '#me' then
			hint = hint .. std.me():gram().hint .. ','
		elseif k == '#first' then
			hint = hint .. mp.first_hint .. ','
		elseif k == '#second' then
			hint = hint .. mp.second_hint .. ','
		else
			hint = hint .. k .. ','
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

	if ob == '#first' then
		ob = mp.first
	elseif ob == '#second' then
		ob = mp.second
	elseif ob == '#me' then
		ob = std.me()
	elseif ob == '#where' then
		ob = std.me():where()
	elseif ob == '#here' then
		ob = std.here()
	else
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

	if ob == '#first' then
		ob = mp.first
	elseif ob == '#second' then
		ob = mp.second
	elseif ob == '#me' then
		ob = std.me()
	elseif ob == '#where' then
		ob = std.me():where()
	elseif ob == '#here' then
		ob = std.here()
	else
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
	return self:gram()[mp.hint[hint] or hint]
end

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
