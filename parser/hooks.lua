local table = std.table

local hooks = { }
mp.hook_args = {}
function mp:hook(ev, fn, pri)
	if not hooks[ev] then
		std.rawset(mp, ev, function(...)
			mp.hook_args = {...}
			local r, v
			for _, vv in ipairs(hooks[ev]) do
				r, v = vv.fn(std.unpack(mp.hook_args))
				if r ~= false then
					return r, v
				end
			end
			if v == nil and r == false then v = false end
			return v
		end)
	end
	hooks[ev] = hooks[ev] or {}
	table.insert(hooks[ev], { fn = fn, pri = pri or 1 })
	table.sort(hooks[ev], function(a, b) return a.pri < b.pri end)
end
