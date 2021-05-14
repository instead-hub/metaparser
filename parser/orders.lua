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

local EXPERIMENTAL = false

require "parser/hooks"

if EXPERIMENTAL then
	std.obj.need_scene = function() end
	std.obj.have = std.player.have
	std.obj.inventory = std.player.inventory

	function std.here()
		return std.ref(std.me():inroom())
	end
end

mp.correct = std.hook(mp.correct, function(f, self, inp)
	if self.inp_prefix then
		for i, v in ipairs(self.inp_prefix) do
			table.insert(self.parsed, i, v)
		end
	end
	local r, v = f(self, inp)
	if self.inp_prefix then
		for _ = 1, #self.inp_prefix do
			table.remove(self.parsed, 1)
		end
	end
	self.inp_prefix = false
	return r, v
end)

local table = std.table
mp.order = false
mp.inp_prefix = false
mp:hook('before_Any', function(_, ev, w, wh, ...)
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

function mp:Order(w, ev, ...)
	if not mp:animate(w) then
		mp:message 'Talk.NOTLIVE'
	else
if EXPERIMENTAL then
		if w:has'npc' then
			local op = game.player
			game.player = w
			mp:xaction(ev, ...)
			game.player = op
			return
		end
end
		mp:message 'Talk.LIVE'
	end
end

mp:hook('pre_input', function(self, str)
	local w = std.split(str, " ")
	if #w > 1 then
		local ww = {}
		local len = #w - 1
		for _ = 1, len do
			table.insert(ww, w[1])
			table.remove(w, 1)
			local o = mp:lookup_noun(ww)
			if #o > 0 and o[1].ob and o[1].ob ~= std.me() then
				mp.order = o[1].ob
				mp.hook_args = {self, table.concat(w, ' ')}
				mp.inp_prefix = ww
				return mp.hook_args[2]
			end
		end
	end
	return false, str
end, -10)
