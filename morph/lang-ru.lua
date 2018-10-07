local type = type
local kbdru = {
	["q"] = "й",
	["w"] = "ц",
	["e"] = "у",
	["r"] = "к",
	["t"] = "е",
	["y"] = "н",
	["u"] = "г",
	["i"] = "ш",
	["o"] = "щ",
	["p"] = "з",
	["["] = "х",
	["]"] = "ъ",
	["a"] = "ф",
	["s"] = "ы",
	["d"] = "в",
	["f"] = "а",
	["g"] = "п",
	["h"] = "р",
	["j"] = "о",
	["k"] = "л",
	["l"] = "д",
	[";"] = "ж",
	["'"] = "э",
	["z"] = "я",
	["x"] = "ч",
	["c"] = "с",
	["v"] = "м",
	["b"] = "и",
	["n"] = "т",
	["m"] = "ь",
	[","] = "б",
	["."] = "ю",
	["`"] = "ё",
	["/"] = ".",
	shifted = {
	["q"] = "Й",
	["w"] = "Ц",
	["e"] = "У",
	["r"] = "К",
	["t"] = "Е",
	["y"] = "Н",
	["u"] = "Г",
	["i"] = "Ш",
	["o"] = "Щ",
	["p"] = "З",
	["["] = "Х",
	["]"] = "Ъ",
	["a"] = "Ф",
	["s"] = "Ы",
	["d"] = "В",
	["f"] = "А",
	["g"] = "П",
	["h"] = "Р",
	["j"] = "О",
	["k"] = "Л",
	["l"] = "Д",
	[";"] = "Ж",
	["'"] = "Э",
	["z"] = "Я",
	["x"] = "Ч",
	["c"] = "С",
	["v"] = "М",
	["b"] = "И",
	["n"] = "Т",
	["m"] = "Ь",
	[","] = "Б",
	["."] = "Ю",
	["`"] = "Ё",
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = ";",
	["5"] = "%",
	["6"] = ":",
	["7"] = "?",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["/"] = ",",
	}
}

local toupper = {
	["й"] = "Й",
	["ц"] = "Ц",
	["у"] = "У",
	["к"] = "К",
	["е"] = "Е",
	["н"] = "Н",
	["г"] = "Г",
	["ш"] = "Ш",
	["щ"] = "Щ",
	["з"] = "З",
	["х"] = "Х",
	["ъ"] = "Ъ",
	["ф"] = "Ф",
	["ы"] = "Ы",
	["в"] = "В",
	["а"] = "А",
	["п"] = "П",
	["р"] = "Р",
	["о"] = "О",
	["л"] = "Л",
	["д"] = "Д",
	["ж"] = "Ж",
	["э"] = "Э",
	["я"] = "Я",
	["ч"] = "Ч",
	["с"] = "С",
	["м"] = "М",
	["и"] = "И",
	["т"] = "Т",
	["ь"] = "Ь",
	["б"] = "Б",
	["ю"] = "Ю",
	["ё"] = "Ё",
}

local function lower(str)
	if type(str) ~= 'string' then
		return str
	end
	for k, v in pairs(toupper) do
		str = str:gsub(v, k)
	end
	return str
end

local function upper(str)
	if type(str) ~= 'string' then
		return str
	end
	for k, v in pairs(toupper) do
		str = str:gsub(k, v)
	end
	return str
end

local function is_cap(str)
	if type(str) ~= 'string' then
		return false
	end
	local s, e
	for k, v in pairs(toupper) do
		if not s and str:find("^"..v) then
			s = true
		end
		if not e and str:find(v.."$") then
			e = true
		end
		if not s and str:find("^[A-Z]") then
			s = true
		end
		if not e and str:find("[A-Z]$") then
			e = true
		end
	end
	return s, e
end

local function cap(str)
	if type(str) ~= 'string' then
		return str
	end
	for k, v in pairs(toupper) do
		local s = str:gsub("^"..k, v)
		if s ~= str then
			return s
		end
	end
	return str
end

local lang

local function norm(str)
	if type(str) ~= 'string' then
		return str
	end
	if not lang.yo then
		str = str:gsub("ё", "е"):gsub("Ё", "Е")
	end
	return str
end

local vowels = {
	["у"] = true,
	["е"] = true,
	["ы"] = true,
	["а"] = true,
	["о"] = true,
	["и"] = true,
	["ю"] = true,
	["ё"] = true,
	["э"] = true,
	["я"] = true,
}

local function is_vowel(l)
	l = lower(l);
	return vowels[l]
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
	if an["0"] then
		return true
	end
	return gram_tt[an.t]
end

local function gram_info(a)
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

local function gram_eq(a, b)
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

local function gram_compat(base, aa, bb)
	if not gram_eq(base.t, aa.t) then
		return false
	end
	local a, b = aa.t, bb.t
	local g1, g2 = gram_info(aa), gram_info(bb)
	if bb.noun then
		if not base['им'] then
			return false
		end
		local g0 = gram_info(base)
		if not __gram_compat(g0, g1, true) then return false end
		if not __gram_compat(g0, g2, true) then return false end
	end
	return __gram_compat(g1, g2)
end

local function gram_norm(an)
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

local function gram_score(an, g)
	local score = 0
	g = gram_norm(g)
	if an["фам"] then score = score - 0.1 end
	if an["арх"] then score = score - 0.1 end
	for kk, vv in ipairs(g or {}) do
		if vv:sub(1, 1) == '~' then
			vv = vv:sub(2)
			if an[vv] then
				score = score - 1
			elseif an.t == vv then
				score = score - 10
			end
		else
			if an[vv] then
				score = score + 1
			elseif an.t == vv then
				score = score + 10
			end
		end
	end
	return score
end

lang = { yo = false,
	kbd = kbdru,
	norm = norm,
	upper = upper,
	lower = lower,
	cap = cap,
	is_cap = is_cap,
	is_vowel = is_vowel,
	flex_filter = flex_filter,
	gram_compat = gram_compat,
	gram_score = gram_score,
	gram_t = {
		noun = 'С';
	}
}

return lang
