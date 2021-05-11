--[[ include 'parser/orders'
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

mp:hook('before_Any', function(s, ev, w, wh, ...)
	if (ev == 'AskTo' or ev == 'AskFor') and not mp.order then
		mp.order = w
		mp:parse(wh)
		std.pclr()
		return
	end
	if not mp.order or ev == 'Order' then
		return false
	end
	local o = mp.order
	mp.order = false
	mp:xaction("Order", o, ev, w, wh, ...)
end, -10)

function mp:Order(w, ev)
	if not mp:animate(w) then
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
			if #o > 0 and o[1].ob and o[1].ob ~= std.me() then
				mp.order = o[1].ob
				mp.hook_args = {self, table.concat(w, ' ')}
				return mp.hook_args[2]
			end
		end
	end
	return false, str
end, -10)
