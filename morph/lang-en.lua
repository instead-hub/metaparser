local type = type
local kbden = {
	shifted = {
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["/"] = "?",
	[","] = "<",
	["."] = ">",
	["`"] = "~",
	["a"] = "A",
	["b"] = "B",
	["c"] = "C",
	["d"] = "D",
	["e"] = "E",
	["f"] = "F",
	["g"] = "G",
	["h"] = "H",
	["i"] = "I",
	["j"] = "J",
	["k"] = "K",
	["l"] = "L",
	["m"] = "M",
	["n"] = "N",
	["o"] = "O",
	["p"] = "P",
	["q"] = "Q",
	["r"] = "R",
	["s"] = "S",
	["t"] = "T",
	["u"] = "U",
	["v"] = "V",
	["w"] = "W",
	["x"] = "X",
	["y"] = "Y",
	["z"] = "Z",
	}
}

local function lower(str)
	if type(str) ~= 'string' then
		return str
	end
	return str:lower()
end

local function upper(str)
	if type(str) ~= 'string' then
		return str
	end
	return str:upper()
end

local function is_cap(str)
	if type(str) ~= 'string' then
		return false
	end
	local s, e
	if str:find("^[A-Z]") then
		s = true
	end
	if str:find("[A-Z]$") then
		e = true
	end
	return s, e
end

local function cap(str)
	if type(str) ~= 'string' then
		return str
	end
	str = str:gsub("^.", function(v) return v:upper() end)
	return str
end

local lang

local function norm(str)
	return str
end

local vowels = {
	["a"] = true,
	["e"] = true,
	["i"] = true,
	["o"] = true,
	["u"] = true,
}

local function is_vowel(l)
	l = lower(l);
	return vowels[l]
end

lang = { yo = false,
	kbd = kbden,
	norm = norm,
	upper = upper,
	lower = lower,
	cap = cap,
	is_cap = is_cap,
	is_vowel = is_vowel,
	flex_filter = function() return false end,
	gram_compat = function() return false end,
	gram_score = function() return 0 end,
	gram_t = {
		noun = '',
		live = 'live',
		nonlive = 'nonlive',
		neuter = 'neutwe',
		male = 'male',
		female = 'female',
		plural = 'plural',
		proper = 'proper',
		surname = 'surname',
		first = 'first',
		second = 'second',
		third = 'third',
	}
}

return lang
