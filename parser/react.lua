-- react_ and postreact_ event module for reactions near the object

--[[ include 'parser/react'
obj {
	nam = 'npc';
	react_Take = "Player in this room is taking something. Reject!";
}:listen();
]]--

--luacheck: globals mp
--luacheck: no self

require "parser/hooks"

game.react_list = std.list {}

mp:hook('before_Any', function(self, ev, ...)
	for _, v in ipairs(game.react_list) do
		if v:visible() then
			local r = mp:runmethods('react', ev, v, ...)
			if r ~= false then
				return
			end
		end
	end
	return false
end, -5)

mp:hook('post_Any', function(self, ev, ...)
	for _, v in ipairs(game.react_list) do
		if v:visible() then
			local r = mp:runmethods('postreact', ev, v, ...)
			if r ~= false then
				return
			end
		end
	end
	return false
end, -5)

function std.obj.listen(s)
	game.react_list:add(s)
	return s
end
