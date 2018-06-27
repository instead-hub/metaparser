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

local weights = {
--	["мр"] = 2;
--	["жр"] = 2;
--	["мн"] = 4;
--	["ед"] = 4;
}

lang = { yo = false, kbd = kbdru, norm = norm, upper = upper, lower = lower, cap = cap, is_cap = is_cap, is_vowel = is_vowel, weights = weights }

return lang
