--[[ include 'orders'
obj {
	nam = 'npc';
	before_Order = function(s, ev, w, wh)
		p(ev, ' ', w, ' ', wh)
	end
};
-- > npc take apple
]]--

--luacheck: globals mp
--luacheck: no self

require "parser/hooks"

local table = std.table
mp.order = false

mp:hook('before_Any', function(s, ev, ...)
	if not mp.order or ev == 'Order' then
		return false
	end
	mp:xaction("Order", mp.order, ev, ...)
end, -10)

function mp:Order(ev)
	if not mp:animate(mp.order) then
		mp:message 'Talk.NOTLIVE'
	else
		mp:message 'Talk.LIVE'
	end
end

mp:hook('pre_input', function(self, str)
	local w = std.split(str, " ")
	if #w > 1 then
		local ww = {}
		local len = #w - 1
		for i = 1, len do
			table.insert(ww, w[1])
			table.remove(w, 1)
			local o = mp:lookup_noun(ww)
			if #o > 0 and o[1].ob then
				mp.order = o[1].ob
				mp.hook_args = {self, table.concat(w, ' ')}
				return mp.hook_args[2]
			end
		end
	end
	mp.order = false
	return false, str
end, -10)
