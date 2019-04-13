-- react_ and postreact_ event module for reactions near the object

--[[ include 'listen'
obj {
	nam = 'npc';
	react_Take = "Player in this room is taking something. Reject!";
}:listen();
]]--

--luacheck: globals mp
--luacheck: no self
game.react_list = std.list {}

function game:before_Any(ev, ...)
	for _, v in ipairs(game.react_list) do
		if v:inroom() == std.here() then
			local r = mp:runmethods('react', ev, v, ...)
			if r ~= false then
				return
			end
		end
	end
	return false
end

function game:post_Any(ev, ...)
	for _, v in ipairs(game.react_list) do
		if v:inroom() == std.here() then
			local r = mp:runmethods('postreact', ev, v, ...)
			if r ~= false then
				return
			end
		end
	end
	return false
end

function std.obj.listen(s)
	game.react_list:add(s)
	return s
end
