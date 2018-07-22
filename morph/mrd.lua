local lang = {
	norm = function(str)
		return str
	end;
	upper = function(str)
		return str:upper()
	end;
	lower = function(str)
		return str:lower()
	end;
}

local mrd = {
	lang = lang;
	dirs = {''};
}

local msg = print

local function strip(str)
	str = str:gsub("^[ \t]+", ""):gsub("[ \t]$", "")
	return str
end

local function split(str, sep)
	local words = {}
	if not str then
		return words
	end
	for w in str:gmatch(sep or "[^ \t]+") do
		table.insert(words, w)
	end
	return words
end

local function empty(l)
	l = l:gsub("[ \t]+", "")
	return l == ""
end

function mrd:gramtab(path)
	local f, e = io.open(path or 'rgramtab.tab', 'rb')
	if not f then
		return false, e
	end
	self.gram = {
		an = {}; -- by ancodes
		t = {}; -- by types
	}
	for l in f:lines() do
		if not l:find("^[ \t]*//") and not empty(l) then -- not comments
			local w = split(l)
			if #w < 3 then
				msg("Skipping gram: "..l)
			else
				local a = split(w[4], '[^,]+')
				local an = {}
				for k, v in ipairs(a) do
					an[v] = true
				end
				an.t = w[3] -- type
				self.gram.an[w[1]] = an;
				self.gram.t[w[3]] = an;
			end
		end
	end
	f:close()
end

local function section(f, fn, ...)
	local n = tonumber(f:read("*line"))
	if not n then
		return false
	end
	if n == 0 then
		return true
	end
	for l in f:lines() do -- skip accents
		if fn then fn(l, ...) end
		n = n - 1
		if n == 0 then
			break
		end
	end
	return true
end

local gram_tt = {
	["ИНФИНИТИВ"] = true;
	["КР_ПРИЛ"] = true;
	["КР_ПРИЧАСТИЕ"] = true;
	["Г"] = true;
}
local function flex_filter(v)
	local an = v.an
	if an["им"] then
		return true
	end
	if an["рд"] or an["дт"] or an["тв"] or an["пр"] or an["вн"] then
		return false
	end
	return gram_tt[an.t]
end

local function flex_fn(l, flex, an)
	l = l:gsub("//.*$", "")
	local fl = {}
	for w in l:gmatch("[^%%]+") do
		local ww = split(w, "[^%*]+")
		if #ww > 3 or #ww < 1 then
			msg("Skip lex: ", w, l);
		else
			local f = { }
			if #ww == 1 then
				f.an = ww[1]
				f.post = ''
			else
				f.post = ww[1]
				f.an = ww[2]
			end
			f.pre = ww[3] or ''
			local a = an[f.an]
			if not a then
				msg("Gram not found. Skip lex: "..f.an)
			else
				f.an_name = f.an
				f.an = a
				if flex_filter(f) then
					f.filter = true
				end
				table.insert(fl, f)
			end
		end
	end
	table.insert(flex, fl)
end

local function pref_fn(l, pref)
	local p = split(l, "[^,]+")
	table.insert(pref, p)
end

local function dump(vv)
	local s = ''
	if type(vv) ~= 'table' then
		return string.format("%s", tostring(vv))
	end
	for k, v in pairs(vv) do
		s = s .. string.format("%s = %s ", k, v)
	end
	return s
end

local function gram_dump(v)
	for _, f in ipairs(v.flex) do
		local tt = v.pref .. f.pre .. v.t .. f.post
		print("=== ", tt)
		for _, v in pairs(f.an) do
			print(_, v)
		end
	end
end


local busy_cnt = 0


local function word_fn(l, self, dict)
	local norm = mrd.lang.norm
	local words = self.words
	local words_list = self.words_list
	local w = split(l)
	if #w ~= 6 then
		msg("Skipping word: "..l)
		return
	end
	if w[1] == '#' then w[1] = '' end
	local nflex = tonumber(w[2]) or false
	local an = w[5]
	if an == '-' then an = false end
	local an_name = an
	local npref = tonumber(w[6]) or false
	if not nflex then
		msg("Skipping word:"..l)
		return
	end
	nflex = self.flex[nflex + 1]
	if not nflex then
		msg("Wrong paradigm number for word: "..l)
		return
	end
	if an then
		an = self.gram.an[an]
		if not an then
			msg("Wrong ancode for word: "..l)
			return
		end
	end
	if npref then
		npref = self.pref[npref + 1]
		if not npref then
			msg("Wrong prefix for word: "..l)
			return
		end
	end
	local t = w[1]
	local num = 0
	local used = false
	for k, v in ipairs(nflex) do
		if v.filter then
		for _, pref in ipairs(npref or { '' }) do
			local tt = norm(pref .. v.pre .. t .. v.post)
--			if tt == 'ЗАКРЕПЛЕН' then
--				gram_dump { t = t, pref = pref, flex = nflex, an = v.an }
--			end
			if not dict or dict[tt] then
				local a = {}
				for kk, vv in pairs(an or {}) do
					a[kk] = an[kk]
				end
				for kk, vv in pairs(v.an) do
					a[kk] = v.an[kk]
				end
				local w = { t = t, pref = pref, flex = nflex, an = a }
				local wds = words[tt] or {}
				table.insert(wds, w)
				nflex.used = true
				used = true
				if npref then
					npref.used = true
				end
				num = num + 1
				if #wds == 1 then
					words[tt] = wds
				end
			end
		end
		end
	end
	if used then
		table.insert(words_list, { t = w[1], flex = nflex, pref = npref, an = an_name })
	end
	self.words_nr = self.words_nr + num
	busy_cnt = busy_cnt + 1
	if busy_cnt > 1000 then
		if std then std.busy(true) end
		busy_cnt = 0
	end
	return
end

function mrd:load(path, dict)
	local f, e = io.open(path or 'morphs.mrd', 'rb')
	if not f then
		return false, e
	end
	local flex = {}
	if not section(f, flex_fn, flex, self.gram.an) then
		return false, "Error in section 1"
	end
	self.flex = flex
	if not section(f) then
		return false, "Error in section 2"
	end
	if not section(f) then
		return false, "Error in section 3"
	end
	local pref = {}
	if not section(f, pref_fn, pref) then
		return false, "Error in section 4"
	end
	self.pref = pref
	self.words_nr = 0
	self.words = {}
	self.words_list = {}
	collectgarbage("stop")
	if not section(f, word_fn, self, dict) then
		collectgarbage("restart")
		return false, "Error in section 4"
	end
	collectgarbage("restart")
	msg("Generated: "..tostring(self.words_nr).." word(s)");
	local crc = f:read("*line")
	if crc then crc = tonumber(crc) end
	f:close()
	if std then std.busy(false) end
	return true, crc
end

function mrd:dump(path, crc)
	local f, e = io.open(path or 'dict.mrd', 'wb')
	if not f then
		return false, e
	end
	local n = 0
	for k, v in ipairs(self.flex) do
		if v.used then
			v.norm_no = n
			n = n + 1
		end
	end
	f:write(string.format("%d\n", n))
	for k, v in ipairs(self.flex) do
		if v.used then
			local s = ''
			for kk, vv in ipairs(v) do
				s = s .. '%'
				if vv.post == '' then
					s = s..vv.an_name
				else
					s = s..vv.post..'*'..vv.an_name
				end
				if vv.pre ~= '' then
					s = s .. '*'..vv.pre
				end
			end
			f:write(s.."\n")
		end
	end
	f:write("0\n")
	f:write("0\n")
	n = 0
	for k, v in ipairs(self.pref) do
		if v.used then
			v.norm_no = n
			n = n + 1
		end
	end
	f:write(string.format("%d\n", n))
	for k, v in ipairs(self.pref) do
		if v.used then
			local s = ''
			for kk, vv in ipairs(v) do
				if s ~= '' then s = s .. ',' end
				s = s .. vv
			end
			f:write(s.."\n")
		end
	end
	f:write(string.format("%d\n", #self.words_list))
	for k, v in ipairs(self.words_list) do
		local s = ''
		if v.t == '' then
			s = '#'
		else
			s = v.t
		end
		s = s ..' '..tostring(v.flex.norm_no)
		s = s..' - -'
		if v.an then
			s = s .. ' '..v.an
		else
			s = s .. ' -'
		end
		if v.pref then
			s = s ..' '..tostring(v.pref.norm_no)
		else
			s = s .. ' -'
		end
		f:write(s..'\n')
	end
	if crc then
		f:write(string.format("%d\n", crc))
	end
	f:close()
end

function mrd:gram_norm(an)
	local a = {}
	local g = {}
	for _, v in ipairs(an) do
		a[v] = true
		table.insert(g, v)
	end
	if not a['1л'] and not a['2л'] and not a['3л'] then
		table.insert(g, '3л')
	end
	return g
end

function mrd:score(an, g)
	local score = 0
	g = self:gram_norm(g)
	if an["фам"] then score = score - 0.1 end
	if an["арх"] then score = score - 0.1 end
	for kk, vv in ipairs(g or {}) do
		if vv:sub(1, 1) == '~' then
			vv = vv:sub(2)
			if an[vv] then
				score = score - 1 * (self.lang.weights[vv] or 1)
			elseif an.t == vv then
				score = score - 10
			end
		else
			if an[vv] then
				score = score + 1 * (self.lang.weights[vv] or 1)
			elseif an.t == vv then
				score = score + 10
			end
		end
	end
	return score
end

function mrd:gram_info(a)
	local t = { }
	if a['мр'] then
		t.gen = 'male'
	elseif a['жр'] then
		t.gen = 'female'
	elseif a['ср'] then
		t.gen = 'neuter'
	else
		t.gen = 'any'
	end

	if a['мн'] then
		t.num = 'singular'
	elseif a['ед'] then
		t.num = 'plural'
	else
		t.num = 'any'
	end

	if a['буд'] then
		t.time = 'future'
	elseif a['прш'] then
		t.time = 'past'
	elseif a['нст'] then
		t.time = 'present'
	else
		t.time = 'any'
	end

	if a['1л'] then
		t.face = 'first'
	elseif a['2л'] then
		t.face = 'second'
	elseif a['3л'] then
		t.face = 'third'
	else
		t.face = 'any'
	end

	return t
end

local function __gram_compat(g1, g2, time)
	if g1.gen ~= g2.gen and g1.gen ~= 'any' and g2.gen ~= 'any' then return false end
	if not time then
		if g1.num ~= g2.num and g1.num ~= 'any' and g2.num ~= 'any' then return false end
	end
	if g1.time ~= g2.time and g1.time ~= 'any' and g2.time ~= 'any' then return false end
	if g1.face ~= g2.face and g1.face ~= 'any' and g2.face ~= 'any' then return false end
	return true
end

function mrd:gram_compat(base, aa, bb)
	local a, b = aa.t, bb.t
	local g1, g2 = self:gram_info(aa), self:gram_info(bb)
	if bb.noun then
		if not base['им'] then
			return false
		end
		local g0 = self:gram_info(base)
--		if not __gram_compat(g0, g1) then return false end
		if not __gram_compat(g0, g2, true) then return false end
	end
	return __gram_compat(g1, g2)
end

function mrd:gram_eq(a, b)
	if not a or not b then return true end
	if a == 'ИНФИНИТИВ' or b == 'ИНФИНИТИВ' then
		return b == a or b == 'Г' or a == 'Г'
	end
	if a == 'КР_ПРИЛ' or b == 'КР_ПРИЛ' then
		return b == a -- or b == 'П'
	end
	if a == 'КР_ПРИЧАСТИЕ' or b == 'КР_ПРИЧАСТИЕ' then
		return b == a
	end
	if a == 'ПРИЧАСТИЕ' or b == 'ПРИЧАСТИЕ' then
		return b == a
	end
	if a == 'Г' or b == 'Г' then return a == b end
	return true
end

local function gram2an(g)
	local a = {}
	for _, v in ipairs(g) do
		if v:sub(1, 1) == '~' then
			a[v:sub(2)] = false
		else
			a[v] = true
		end
	end
	a.t = nil
	return a
end

local cache = {
	hash = {};
	list = {};
}
function mrd:lookup(w, g)
	local key  = ""
	for _, v in ipairs(g or {}) do
		key = key ..','.. v
	end
	key = w .. '/'..key
	local cc = cache.hash[key]
	if cc then
		return cc.w, cc.g
	end
	w, g = self:__lookup(w, g)
	cache.hash[key] = { w = w, g = g }
	table.insert(cache.list, 1, key)
	if #cache.list > 512 then
		key = cache.list[#cache.list]
		cache.hash[key] = nil
		table.remove(cache.list, #cache.list)
	end
	return w, g
end
function mrd:__lookup(w, g)
	local ow = w
	local cap, upper = self.lang.is_cap(w)
	local t = self.lang.upper(self.lang.norm(w))
	w = self.words[t]
	if not w then
		return false, "No word in dictionary"
	end
	local res = {}
	for k, v in ipairs(w) do
		local flex = v.flex
		local score = self:score(v.an, g)
		local t = v.an.t
		for _, f in ipairs(flex) do
			if self:gram_eq(v.an.t, f.an.t) and self:gram_compat(v.an, f.an, gram2an(g)) then
				local sc = self:score(f.an, g)
				if sc >= 0 then
					if t ~= f.an.t then sc = sc - 1 end -- todo
if false then
				local tt = v.pref .. f.pre .. v.t .. f.post
				if tt == 'ШЛЕМ' or tt == 'ШЛЁТ' or tt == 'ШЛЕМОМ' then
					print ("======looking for:", g.noun)
					for _, v in pairs(g) do
						print(_, v)
					end
					print ("======looking got:", score + sc, sc)
					print(tt, v.t, score + sc)
					for _, v in pairs(f.an) do
						print(_, v)
					end
				end
end
					table.insert(res, { score = score + sc, pos = #res, word = v, flex = f })
				end
			end
		end
	end
	if #res == 0 then
		return ow, gram2an(g) -- false, "No gram"
	end
	table.sort(res, function(a, b)
		if a.score == b.score then
			return a.pos < b.pos
		end
		return a.score > b.score
	end)
if false then
	for i = 1, #res do
		local w = res[i]
		local tt = self.lang.lower(w.word.pref .. w.flex.pre .. w.word.t .. w.flex.post)
		print(i, "res: ", tt, w.score)
		if tt == 'красный' or tt == 'красного' then
			for _, v in pairs(w.flex.an) do
				print(_, v)
			end
		end
--		print(tt, w.score)
	end
end
	w = res[1]
	local gram = {}
	for k, v in pairs(w.flex.an) do
		gram[k] = v
	end

	for k, v in pairs(w.word.an) do
		gram[k] = v
	end

	w = self.lang.lower(w.word.pref .. w.flex.pre .. w.word.t .. w.flex.post)
	if upper then
		w = self.lang.upper(w)
	elseif cap then
		w = self.lang.cap(w)
	end

	return w, gram
end
local word_match = "[^ \t,%-!/:%+&]+"
local missed_words = {}
function mrd:word(w)
	local ow = w
	local s, e = w:find("/[^/]*$")
	local g = {}
	local grams = {}
	if s then
		local gg = w:sub(s + 1)
		w = w:sub(1, s - 1)
		g = split(gg, "[^, ]+")
	end
	local found = true
	w = w:gsub(word_match,
		function(w)
			local ww, gg = self:lookup(w, g)
			if not ww then
				found = false
			else
				table.insert(grams, gg)
			end
			return ww or w
		end)
	if not found then
		if DEBUG and not tonumber(w) and not missed_words[w] then
			missed_words[w] = true
			msg("Can not find word: '"..ow.."'")
		end
	end
	return w, grams
end

function mrd:file(f, dict)
	dict = dict or {}
	local ff, e = io.open(f, "rb")
	if not ff then
		return false, e
	end
	print("Added file: ", f)
	for l in ff:lines() do
		for w in l:gmatch('%-"[^"]+"') do
			w = w:gsub('^%-"', ""):gsub('"$', "")
			local words = split(w, '[^|]+')
			for _, word in ipairs(words) do
				word = word:gsub("/[^/]*$", "")
				for ww in word:gmatch(word_match) do
					local t = self.lang.upper(self.lang.norm(ww))
					if not dict[t] and not t:find("%*$") then
						dict[t] = true;
						dprint("mrd: Added word: ", ww)
					end
				end
			end
		end
	end
	ff:close()
	return dict
end

local function str_hint(str)
--	str = str:gsub("^%+", "")
	local s, e = str:find("/[^/]*$")
	if not s then
		return str, ""
	end
	if s == 1 then
		return "", str:sub(2)
	end
	return str:sub(1, s - 1), str:sub(s + 1)
end

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

function mrd:dict(dict, word)
	local tab = {}
	local w, hints = str_hint(word)
	hints = str_split(hints, ",")
	for k, v in pairs(dict) do
		local ww, hh = str_hint(k)
		local hints2 = {}
		for _, v in ipairs(str_split(hh, ",")) do
			hints2[v] = true
		end
		if ww == w then
			local t = { ww, score = 0, pos = #tab, w = v }
			for _, v in ipairs(hints) do
				if v:sub(1, 1) ~= '~' then
					if hints2[v] then
						t.score = t.score + 1
					end
				else
					if hints2[str_strip(v:sub(2))] then
						t.score = t.score - 1
					end
				end
			end
			table.insert(tab, t)
		end
	end
	if #tab > 0 then
		table.sort(tab,
			   function(a, b)
				   if a.score == b.score then
					   return a.pos < b.pos
				   end
				   return a.score > b.score
		end)
		if tab[1].score > 0 then
			return tab[1].w
		end
	end
end

function mrd.dispof(w)
	local d
	if w.raw_word ~= nil then
		local d = std.call(w, 'raw_word')
		return d, true
	end
	if w.word ~= nil then
		local d = std.call(w, 'word')
		return d
	end
	return std.titleof(w) or std.nameof(w)
end

local obj_cache = { hash = {}, list = {}}

function mrd:obj(w, n, nn)
	local hint = ''
	local hint2, disp, ob, raw
	if type(w) == 'string' then
		w, hint = str_hint(w)
	elseif type(n) == 'string' then
		hint = n
		n = nn
	end
	if type(w) ~= 'string' then
--		w = std.object(w)
		ob = w
		disp, raw = self.dispof(w)
	else
		disp = w
	end
	local d = obj_cache.hash[disp]
	if not d then
		d = str_split(disp, '|')
		if #d == 0 then
			std.err("Wrong object display: ".. (disp or 'nil'), 2)
		end
	-- normalize
		local nd = {}
		for k, v in ipairs(d) do
			w, hint2 = str_hint(v)
			local dd = raw and { w } or str_split(w, ',')
			for _, vv in ipairs(dd) do
				table.insert(nd, { word = vv, hint = hint2 or '', alias = k, idx = _ })
			end
		end
		d = nd
		table.insert(obj_cache.list, 1, disp)
		local len = #obj_cache.list
		if len > 128 then
			local key = obj_cache.list[len]
			table.remove(obj_cache.list, len)
			obj_cache.hash[key] = nil
		end
		obj_cache.hash[disp] = d
	end
	
	if type(n) == 'table' then
		local ret = n
		for _, v in ipairs(d) do
			table.insert(ret, { word = v.word, hint = hint ..','..v.hint, alias = v.alias, idx = v.idx });
		end
		return ob, ret
	end
	n = n or (ob and ob.__word_alias) or 1
	for k, v in ipairs(d) do
		if v.alias == n then
			n = k
			break
		end
	end
	if not d[n] then n = 1  end
	w = d[n].word
	hint2 = d[n].hint
	return ob, w, hint .. ',' .. hint2
end

local function noun_append(rc, tab, w)
--	w = mrd.lang.norm(w)
	if tab then
		table.insert(tab, w)
	else
		if rc ~= '' then rc = rc .. '|' end
		rc = rc .. w
	end
	return rc
end

function mrd:noun_hint(ob, ...)
	local g = ob and ob:gram(...) or {}
	local hint = ''
	for _, v in ipairs { mp.hint.male, mp.hint.female, mp.hint.neuter, mp.hint.plural, mp.hint.live } do
		if g[v] then
			hint = hint ..','..v
		end
	end
	if not g[mp.hint.live] then
		hint = hint .. ',' .. mp.hint.nonlive
	end
	if ob then
		hint = hint..",noun"
	end
	return hint
end

function mrd:noun(w, n, nn)
	local hint, ob, found
	local rc = ''
	local tab = false
	ob, w, hint = self:obj(w, n, nn)
	if type(w) ~= 'table' then
		local alias = nn
		if type(alias) ~= 'number' then alias = n end
		w = {{ word = w, hint = hint, alias = alias }}
	else
		tab = {}
	end
	for _, v in ipairs(w) do
		local hint2 = self:noun_hint(ob, v.alias)
		found = false
		if ob and type(ob.__dict) == 'table' then
			local ww = self:dict(ob.__dict, v.word .. '/'.. v.hint .. hint2)
			if ww then
				found = true
				rc = noun_append(rc, tab, ww)
			end
		end
		if not found and type(game.__dict) == 'table' then
			local ww = self:dict(game.__dict, v.word .. '/'.. v.hint .. hint2)
			if ww then
				found = true
				rc = noun_append(rc, tab, ww)
			end
		end
		if not found then
			local m = self:word(v.word .. '/'.. v.hint .. hint2)
			rc = noun_append(rc, tab, m)
		end
	end
	return tab and tab or rc
end

local function str_hash(str)
	local sum = 0
	for i = 1, str:len() do
		sum = sum + string.byte(str, i)
	end
	return sum
end

function mrd:create(fname, crc)
	local dict = {}
	if not std.readdir then
		return
	end
	for _, d in ipairs(self.dirs) do
		for f in std.readdir(instead.gamepath() .. '/'..d) do
			if f:find("%.lua$") or f:find("%.LUA$") then
				mrd:file(f, dict)
			end
		end
	end
	local sum = 0
	for w, _ in pairs(dict) do
		sum = sum + str_hash(w)
		sum = sum % 4294967291;
	end
	if crc ~= sum then
		dprint("Generating dict.mrd with sum: ", sum)
		if mrd:load("morph/morphs.mrd", dict) then
			mrd:dump(fname or 'dict.mrd', sum)
		else
			dprint("Can not find morph/morphs.mrd")
		end
	else
		dprint("Using dict.mrd")
	end
end
if std then
std.obj.noun = function(self, ...)
	return mrd:noun(self, ...)
end

std.obj.Noun = function(self, ...)
	return mrd.lang.cap(mrd:noun(self, ...))
end

std.obj.gram = function(self, n)
	local hint, ob, w
	ob, w, hint = mrd:obj(self, n)
	local _, gram = mrd:word(w .. '/'..hint)
	local thint = ''
	hint = str_split(hint, ",")
	local g = gram and gram[1] or {}
	for _, v in ipairs(gram or {}) do
		if v.t == 'С' then
			g = v
			break
		end
	end
	local gg = std.clone(g)
	for _, v in ipairs(hint) do
		gg[v] = true
	end
	for k, v in pairs(gg) do
		if v then
			thint = thint .. k .. ','
		end
	end
	gg.hint = thint
	return gg
end

std.obj.dict = function(self, v)
	std.rawset(self, '__dict', v)
	return self
end

local onew = std.obj.new
std.obj.new = function(self, v)
	if type(v[1]) == 'string' or type(v[1]) == 'function' then
		v.word = v[1]
		table.remove(v, 1)
	end
	return onew(self, v)
end
end
local mt = getmetatable("")
function mt.__unm(v)
	return v
end

return mrd
--mrd:gramtab()
--mrd.lang = require "lang-ru"
--mrd:load(false, { [mrd.lang.upper "подосиновики"] = true, [mrd.lang.upper "красные"] = true })
--local w = mrd:word(-"красные подосиновики/рд")
--print(w)
--mrd:file("mrd.lua")
