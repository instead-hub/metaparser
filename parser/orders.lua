local table = std.table
mp.order = false

if not mp.pre_input then
	function mp:pre_input(str)
		return str
	end
end

function mp:before_Any(ev, ...)
	if not mp.order or ev == 'Order' then
		return false
	end
	mp:xaction("Order", mp.order, ev, ...)
end

function mp:Order(ev)
	if not mp:animate(mp.order) then
		mp:message 'Talk.NOTLIVE'
	else
		mp:message 'Talk.LIVE'
	end
end

mp.pre_input = std.hook(mp.pre_input, function(f, self, str)
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
				return f(self, table.concat(w, ' '))
			end
		end
	end
	mp.order = false
	return f(self, str)
end)
