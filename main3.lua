--$Name:МЕТАПАРСЕР$

local oreset = std.reset

function std.reset(s, fname, ...)
	if fname then
		local dir = fname:gsub("^(.+[\\/])[^\\/]+$", "%1");
		std.DICT_FILE = dir.."/dict.mrd";
		std.SOURCES_DIRS = { dir };
	end
	return oreset(s, fname, ...)
end

obj {
	nam = '@select';
	act = function(s, t)
		gamefile("demos/"..t.."/main3.lua", true)
	end;
}
local function get_name(f)
	local i = 1
	for l in f:lines() do
		if l:find("^[ \t]*--[ \t]*%$Name:") then
			local nam = l:gsub("^--[ \t]*--[ \t]*%$Name:([^%$]+)%$?$", "%1");
			return nam
		end
		i = i + 1
		if i > 10 then
			break
		end
	end
end
room {
	title = "Выбор игры";
	nam = 'main';
	dsc = function(s)
		local games = {}
		for d in std.readdir("demos") do
			if d ~= '.' and d ~= '..' then
				local f = io.open("demos/"..d.."/main3.lua", "r")
				if f then
					local name = get_name(f) or d
					table.insert(games, {d, name})
					f:close()
				end
			end
		end
		table.sort(games, function(a, b) return a[2] < b[2] end)
		for _, v in ipairs(games) do
			pn("{@select ", v[1], "|", v[2], "}");
		end
	end;
}
