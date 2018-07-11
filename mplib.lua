function mp:clear()
	self.text = ''
end

mp.door = std.class({
	before_Walk = function(s)
		return s:before_Enter();
	end;
	before_Enter = function(s)
		if mp:check_inside(s) then
			return
		end
		if not s:has 'open' then
			p (mp.msg.Enter.DOOR_CLOSED)
			return
		end
		local r, v = mp:runorval(s, 'door_to')
		if not v then
			p (mp.msg.Enter.DOOR_NOWHERE)
			return
		end
		if r then
			if not mp:move(std.me(), r) then
				return true
			end
		end
		return v
	end;
}, std.obj):attr 'enterable,openable,door'
door = mp.door

local function pnoun(noun, ...)
	local ctx = mp:save_ctx()
	mp.first = noun
	mp.first_hint = noun:gram().hint
	p(...)
	mp:restore_ctx(ctx)
end

mp.cutscene =
std.class({
	enter = function(s)
		s.__num = 1
	end;
	ini = function(s, load)
		std.rawset(s, 'text', s.text)
		std.rawset(s.__var, 'text', nil)
		if not load then
			s.__num = 1
		end
	end;
	title = false;
	nouns = function() return {} end;
	dsc = function(s)
		if type(s.text) == 'function' then
			local t = std.call(s, 'text', s.__num)
			if not t then
				s:Next(true)
			end
			p (t)
			return
		end
		if type(s.text) == 'string' then
			p (s.text)
		else
			p (s.text[s.__num])
		end
	end;
	OnError = function(s, err)
		p(mp.msg.CUTSCENE_HELP)
	end;
	Next = function(s, force)
		if game:time() == 0 then
			return
		end
		s.__num = s.__num + 1
		if force or type(s.text) == 'string' or (type(s.text) == 'table' and s.__num > #s.text) then
			local r, v = mp:runorval(s, 'next_to')
			if r then
				walk(r)
			elseif v == false then
				walkback()
			end
			return
		end
		s:dsc()
	end;
}, std.room):attr'cutscene'

-- player
mp.msg.Look = {}

function std.obj:multi_alias(n)
	if n then
		self.__word_alias = n
	end
	return self.__word_alias
end

std.room.dsc = function(s)
	p (mp.msg.SCENE);
end

function mp:thedark()
	return not mp:offerslight()
end

function std.obj:scene()
	local s = self
	local sc = mp:visible_scope(s)
	local title = iface:title(std.titleof(sc))
	if s ~= sc then
		title = title .. ' '..(mp.msg.TITLE_INSIDE)
	end
	return title
end

std.room.scene = std.obj.scene

local owalk = std.player.walk

std.obj.from = std.room.from

function std.player:walk(w, doexit, doenter, dofrom)
	w = std.object(w)
	if std.is_obj(w, 'room') then
		if w == std.here() then
			self.__room_where = false
			self:need_scene(true)
			return nil, true
		end
		local r, v = owalk(self, w, doexit, doenter, dofrom)
		self.__room_where = false
		return r, v
	end
	if std.is_obj(w) then -- into object
		if dofrom ~= false and std.me():where() ~= w then
			w.__from = std.me():where()
		end
		self.__room_where = w
		if w:inroom() == std.ref(self.room) then
			self:need_scene(true)
			return nil, true
		end
		return owalk(self, w:inroom(), doexit, doenter, dofrom)
	end
	std.err("Can not enter into: "..std.tostr(w), 2)
end

function std.player:walkout(w, ...)
	if w == nil then
		w = self:where():from()
	end
	return self:walk(w, true, false, ...)
end;

std.player.where = function(s, where)
	if type(where) == 'table' then
		table.insert(where, std.ref(s.__room_where or s.room))
	end
	return std.ref(s.__room_where or s.room)
end

std.room.display = function(s)
	local c = std.call(mp, 'content', s)
	return c
end
function mp:visible_scope(s)
	local h = s
	if s:has 'transparent' or s:has 'supporter' then
		mp:trace(s, function(v)
				 h = v
				 if not v:has'transparent' and not v:has'supporter' then
					 return nil, false
				 end
		end)
	end
	return h
end

std.obj.display = function(s)
	local c = std.call(mp, 'content', mp:visible_scope(s))
	return c
end

std.player.look = function(s)
	local scene
	local r = s:where()
	if s:need_scene() then
		scene = r:scene()
	end
	return (std.par(std.scene_delim, scene or false, r:display() or false))
end;

--
local function check_persist(w)
	if not w:has 'persist' then
		return false
	end
	if not w.found_in then
		return true
	end
	local r, v = std.call(w, 'found_in')
	return v
end

function std.obj:access()
	local plw = {}
	local ww = {}
	if std.me():where() == self then
		return true
	end

	if self:has 'persist' then
		if not self.found_in then
			return true
		end
		local r, v = std.call(self, 'found_in')
		return v
	end
	if mp.scope:lookup(self) then
		return true
	end
	mp:trace(std.me(), function(v)
--		if v:has 'concealed' then
--			return nil, false
--		end
		table.insert(plw, v)
		if v:has 'container' then -- or v:has 'supporter' then
			return nil, false
		end
	end)
	return mp:trace(self, function(v)
--		if v:has 'concealed' then
--			return nil, false
--		end
		if check_persist(v) then
			return true
		end
		for _, o in ipairs(plw) do
			if v == o then
				return true
			end
		end
		if v:has 'container' and not v:has 'open' then
			return nil, false
		end
	end)
end

function mp:offerslight(what)
	local w = std.me()
	if w:has'light' then
		return true
	end
	if what and (what:has'light' or std.me():lookup(what)) then
		return true
	end
	local l = mp:trace(w, function(v)
		if v:has 'light' then
			return true
		end
		if not v:has 'transparent' and not v:has 'open' and not v:has 'supporter' then
			return nil, false
		end
	end)
	return l
end

function std.obj:visible()
	local plw = { }
	local ww = {}
	if not mp:offerslight(self) then
		return false
	end
	if std.me():where() == self then
		return true
	end

	if check_persist(self) then
		return true
	end

	if mp.scope:lookup(self) then
		return true
	end

	mp:trace(std.me(), function(v)
--		if v:has 'concealed' then
--			return nil, false
--		end
		table.insert(plw, v)
		if v:has 'container' and not v:has 'transparent' and not v:has 'open' then
			return nil, false
		end
	end)
	return mp:trace(self, function(v)
--		if v:has 'concealed' then
--			return nil, false
--		end
		if check_persist(v) then
			return true
		end
		for _, o in ipairs(plw) do
			if v == o then
				return true
			end
		end
		if v:has 'container' and not v:has 'transparent' and not v:has 'open' then
			return nil, false
		end
	end)
end

-- dialogs
std.phr.raw_word = function(s)
	local dsc = std.call(s, 'dsc')
	return dsc .. '|'.. (tostring(s.__ph_idx) or std.dispof(s))
end

std.phr.Exam = function(s, ...)
	std.me():need_scene(true)
	return s:act(...)
end

std.phr.__xref = function(s, str)
	return str
end

std.dlg.scene = std.obj.scene
std.dlg.title = false
std.dlg.OnError = function(s, err)
	p(mp.msg.DLG_HELP)
end;

std.dlg.nouns = function(s)
	local r, nr
	local nouns = {}
	nr = 1
	local oo = s.current
	if not oo then -- nothing to show
		return
	end

	for i = 1, #oo.obj do
		local o = oo.obj[i]
		o = o:__alias()
		std.rawset(o, '__ph_idx', nr)
	end

	for i = 1, #oo.obj do
		local o = oo.obj[i]
		o = o:__alias()
		if o:visible() then
			std.rawset(o, '__ph_idx', nr)
			nr = nr + 1
			table.insert(nouns, o)
		end
	end
	return nouns
end;

std.phrase_prefix = function(n)
	if not n then
		return ''
	end
	return (string.format("%d) ", n))
end

local function compass_dir(dir)
	return obj {
		nam = '@'..dir;
		default_Event = 'Walk';
		before_Any = function(s, ev, ...)
			return _'@compass':action(dir, ev, ...)
		end
	}:attr'light,enterable,concealed':persist()
end

obj {
	nam = '@compass';
	visible = function() return false end;
	action = function(s, dir, ev, ...)
		if ev == 'Exam' then
			local d = dir
			local r, v = mp:runorval(std.here(), d)
			if r then -- somewhat?
				if std.object(r):type 'room' then
					p (mp.msg.COMPASS_EXAM_NO)
					return
				end
				p (mp.msg.COMPASS_EXAM(d, std.object(r)))
				return
			end
			if not v then
				p (mp.msg.COMPASS_EXAM_NO)
				return
			end
			return v
		end
		if ev == 'Walk' or ev == 'Enter' then
			local d = dir
			if not std.me():where():type'room' then
				p (mp.msg.Enter.EXITBEFORE)
				return
			end
			if std.here()[d] == nil and d == 'out_to' then
				mp:xaction("Exit")
				return
			end
			local r, v = mp:runorval(std.here(), d)
			if not v then
				local r, v = mp:runorval(std.here(), 'cant_go', dir)
				p ((v and r) or mp.msg.COMPASS_NOWAY)
				return
			end
			if not r then
				return v
			end
			if std.object(r):type 'room' then
				if not mp:move(std.me(), r) then return true end
			else
				mp:xaction("Enter", std.object(r))
			end
			return
		end
		return std.call(s, 'before_Default', ...)
	end;
}:persist():attr'~light,transparent':with {
	compass_dir 'n_to',
	compass_dir 'ne_to',
	compass_dir 'e_to',
	compass_dir 'se_to',
	compass_dir 's_to',
	compass_dir 'sw_to',
	compass_dir 'w_to',
	compass_dir 'nw_to',
	compass_dir 'd_to',
	compass_dir 'u_to',
	compass_dir 'in_to',
	compass_dir 'out_to',
}


mp.compass_dir = function(self, w, dir)
	if not dir then
		local nam = tostring(w.nam):gsub("^@", "")
		return w:where() and w:where() ^ '@compass' and nam
	end
	return w ^ '@dir'
end

-- VERBS
local function if_has(w, a, t, f)
	return w:has(a) and t or f
end

function mp:multidsc(oo, inv)
	local t = {}
	local dup = {}
	for _, v in ipairs(oo) do
		local n
		if not v:has'concealed' then
			if inv then
				n = std.call(v, 'inv')
			end
			n = n or v:noun(1)
			if dup[n] then
				dup[n] = dup[n] + 1
			else
				table.insert(t, { ob = v, noun = n })
				dup[n] = 1
			end
		end
	end
	for _, vv in ipairs(t) do
		local v = vv.noun
		local ob = vv.ob
		if _ ~= 1 then
			if _ == #t then
				p (" ", mp.msg.AND or "and")
			else
				p ","
			end
		end
		if dup[v] > 1 then
			pr (vv.ob:noun('мн', 1), " (", dup[v], " ", mp.msg.ENUM, ")")
		else
			pr (v)
			if ob:has'worn' then
				mp.msg.WORN(ob)
			elseif ob:has'openable' and ob:has'open' then
				mp.msg.OPEN(ob)
			end
		end
	end
	p "."
end

mp.msg.Exam = {}
function mp:content(w)
	if w:type 'dlg' then
		return
	end
	local oo = {}
	local ooo = {}
	if (w == std.me():where() or std.here() == w) and
		(mp.event == 'Look' or mp.event == 'Exam' or std.me():need_scene()) then
		pn()
		local dsc, v
		if not mp:offerslight(w) then
			dsc, v = std.call(w, 'dark_dsc')
			if dsc then p(dsc) end
			if not v then
				p(mp.msg.WHEN_DARK)
			end
		else
			dsc, v = std.call(w, w:type'room' and 'dsc' or 'inside_dsc')
			if dsc then p(dsc) end
			if not v then
				p(mp.msg.INSIDE_SCENE)
			end
		end
		p(std.scene_delim)
	end
	self:objects(w, oo, false)
	local something
	for _, v in ipairs(oo) do
		local r, rc
		if not v:has'scenery' and not v:has'concealed' then
			if std.me():where() == v then
				r, rc = std.call(v, 'inside_dsc')
				if r then p(r); something = true; end
			end
			if not rc and not v:has 'moved' then
				r, rc = std.call(v, 'init_dsc')
				if r then p(r); something = true; end
			end
			if not rc then
				r, rc = std.call(v, 'dsc')
				if r then p(r); something = true; end
			end
			if not rc and (v:has'openable') then
				if v.when_open ~= nil and v:has'open' then
					r, rc = std.call(v, 'when_open')
				elseif v.when_closed ~= nil and not v:has'open' then
					r, rc = std.call(v, 'when_closed')
				end
				if r then p(r); something = true; end
			elseif not rc and (v:has'switchable') then
				if v.when_on ~= nil and v:has'on' then
					r, rc = std.call(v, 'when_on')
				elseif v.when_off ~= nil and not v:has'on' then
					r, rc = std.call(v, 'when_off')
				end
				if r then p(r); something = true; end
			end
			if not rc and not v:has'scenery' then
				table.insert(ooo, v)
			end
		end
	end
--	if #ooo > 0 then
--		p(std.scene_delim)
--	end
	oo = ooo
	if #oo == 0 then
		if mp.first == w and not something then
			if w:has 'supporter' then
				pnoun (w, mp.msg.Exam.ON)
			else
				pnoun (w, mp.msg.Exam.IN)
			end
			p (mp.msg.Exam.NOTHING)
		end
	elseif #oo == 1 and not oo[1]:hint 'plural' then
		if std.me():where() == w or std.here() == w then
			p (mp.msg.Look.HEREIS)
		else
			if w:has 'supporter' then
				pnoun (w, mp.msg.Exam.ON)
			else
				pnoun (w, mp.msg.Exam.IN)
			end
			p (mp.msg.Exam.IS)
		end
		p(oo[1]:noun(1), ".")
	else
		if std.me():where() == w or std.here() == w then
			p (mp.msg.Look.HEREARE)
		else
			if w:has 'supporter' then
				pnoun (w, mp.msg.Exam.ON)
			else
				pnoun (w, mp.msg.Exam.IN)
			end
			p (mp.msg.Exam.ARE)
		end
		mp:multidsc(oo)
	end
-- expand?
	for _, o in ipairs(oo) do
		if (o:has'supporter' or o:has'transparent' or (o:has'container' and o:has'open')) and not o:closed() then
			self:content(o)
		end
	end
end

std.room:attr 'enterable,light'

function mp:step()
	game.__daemons:for_each(function(o)
		if o:disabled() then
			return nil, false
		end
		local r, v = std.call(o, 'daemon')
		if r then p(r) end
		if o:closed() then
			return nil, false
		end
	end)
	local oo = mp:nouns()
	std.here():attr 'visited'
	for _, v in ipairs(oo) do
		if v.each_turn ~= nil then
			local r, v = std.call(v, 'each_turn')
			if r then pr(r) end
		end
	end
end

function mp:post_Any()
	if std.here().noparser or game.noparser then return end
	if self.event and self.event:find("Meta", 1, true) then
		return
	end

	if self.score and (self.score ~= (self.__old_score or 0)) then
		mp.msg.SCORE(self.score - (self.__old_score or 0))
		self.__old_score = self.score
	end

	if game.player:need_scene() then
--		pn(iface:nb'')
		local l = game.player:look() -- objects [and scene]
		if std.here().gfx ~= nil then
			local p = std.call(std.here(), 'gfx')
			pn(fmt.c(fmt.img(p)))
		end
		p(l, std.scene_delim)
		game.player:need_scene(false)
	end

	mp:step()
end
function mp:check_touch()
	if self.first and not self.first:access() and not self.first:type'room' then
		p (self.msg.ACCESS1 or "{#First} is not accessible.")
		if std.here() ~= std.me():where() then
			p (mp.msg.EXITBEFORE)
		end
		return true
	end
	if self.second and not self.second:access() and not self.first:type'room' then
		p (self.msg.ACCESS2 or "{#Second} is not accessible.")
		if std.here() ~= std.me():where() then
			p (mp.msg.EXITBEFORE)
		end
		return true
	end
	return false
end

--[[
function mp:before_Any(ev)
	if ev == 'Exam' then
		return false
	end
	if self.first and not self.first:access() and not self.first:type'room' then
		p (self.msg.ACCESS1 or "{#First} is not accessible.")
		if std.here() ~= std.me():where() then
			p (mp.msg.EXITBEFORE)
		end
		return
	end

	if self.second and not self.second:access() and not self.first:type'room' then
		p (self.msg.ACCESS2 or "{#Second} is not accessible.")
		if std.here() ~= std.me():where() then
			p (mp.msg.EXITBEFORE)
		end
		return
	end
	return false
end
]]--
function mp:Look()
	std.me():need_scene(true)
	return false
end

function mp:after_Look()
end

function mp:Exam(w)
	return false
end

function mp:after_Exam(w)
	local r, v = std.call(w, 'description')
	if r then
		p(r)
	end
	if v then
		return false
	end
	if w:has 'container' and (w:has'transparent' or w:has'open') then
		self:content(w)
	elseif w:has 'supporter' then
		self:content(w)
	else
		if w:has'openable' then
			if w:has 'open' then
				local r = std.call(w, 'when_open')
				p (r or mp.msg.Exam.OPENED);
			else
				local r = std.call(w, 'when_closed')
				p (r or mp.msg.Exam.CLOSED);
			end
			return
		end
		if w:has'switchable' then
			local r
			if w:has'on' and w.when_on ~= nil then
				r = std.call(w, 'when_on')
			else
				r = std.call(w, 'when_off')
			end
			p (r or mp.msg.Exam.SWITCHSTATE)
			return
		end
		if w == std.here() then
			std.me():need_scene(true)
		else
			if w == std.me() then
				p (mp.msg.Exam.SELF);
			else
				p (mp.msg.Exam.DEFAULT);
			end
		end
	end
end

mp.msg.Enter = {}

function mp:Enter(w)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	if w == std.me():where() then
		p (mp.msg.Enter.ALREADY)
		return
	end

	if seen(w, me()) then
		p (mp.msg.Enter.INV)
		return
	end

	if not w:has 'enterable' then
		p (mp.msg.Enter.IMPOSSIBLE)
		return
	end

	if w:has 'container' and not w:has 'open' then
		p (mp.msg.Enter.CLOSED)
		return
	end

	if mp:check_inside(w) then
		return
	end

	if not mp:move(std.me(), w) then return true end
	return false
end

function mp:after_Enter(w)
	p (mp.msg.Enter.ENTERED)
end

mp.msg.Walk = {}

function mp:Walk(w)
	if mp:check_touch() then
		return
	end
	if w == std.me():where() then
		p (mp.msg.Walk.ALREADY)
		return
	end

	if seen(w, me()) then
		p (mp.msg.Walk.INV)
		return
	end

--	if std.me():where() ~= std.here() then
--		p (mp.msg.Enter.EXITBEFORE)
--		return
--	end
	return false
end

function mp:after_Walk(w)
	p (mp.msg.Walk.WALK)
end

mp.msg.Exit = {}

function mp:before_Exit(w)
	if not w then
		self:xaction('Exit', std.me():where())
		return true
	end
	return false
end

function mp:Exit(w)
	if mp:check_touch() then
		return
	end
	local wh = std.me():where()
	w = w or std.me():where()
	if wh ~= w then
		p (mp.msg.Exit.NOTHERE)
		return
	end
	if wh:has'container' and not wh:has'open' then
		p (mp.msg.Exit.CLOSED)
		return
	end

	if wh:type'room' and wh.out_to ~= nil then
		mp:xaction("Walk", _'@out_to')
		return
	end

	if wh:from() == wh then
		p (mp.msg.Exit.NOWHERE)
		return
	end
	if wh:type'room' then
--	local r = std.call(w, 'out_to')
		walkback()
	else
		walkback(wh:where())
	end
	return false
end

function mp:after_Exit(w)
	if w then
		p (mp.msg.Exit.EXITED)
	end
end

mp.msg.Inv = {}

function mp:detailed_Inv(wh, indent)
	local oo = {}
	self:objects(wh, oo, false)
	for _, o in ipairs(oo) do
		if not o:has'concealed' then
			for i = 1, indent do pr(iface:nb' ') end
			local inv = std.call(o, 'inv') or o:noun(1)
			pr(inv)
			if o:has'worn' then
				mp.msg.WORN(o)
			elseif o:has'openable' and o:has'open' then
				mp.msg.OPEN(o)
			end
			pn()
			if o:has'supporter' or o:has'container' then
				mp:detailed_Inv(o, indent + 1)
			end
		end
	end
end

function mp:after_Inv()
	local oo = {}
	self:objects(std.me(), oo, false)
	if #oo == 0 then
		p(mp.msg.Inv.NOTHING)
		return
	end
	local empty = true
	for _, v in ipairs(oo) do
		if not v:has'concealed' then empty = false break end
	end
	if empty then
		p(mp.msg.Inv.NOTHING)
		return
	end
	pr(mp.msg.Inv.INV)
	if mp.detailed_inv then
		pn(":")
		mp:detailed_Inv(std.me(), 1)
	else
		p()
		mp:multidsc(oo, true)
	end
end

mp.msg.Open = {}

function mp:Open(w)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	if not w:has'openable' then
		p(mp.msg.Open.NOTOPENABLE)
		return
	end
	if w:has'open' then
		p(mp.msg.Open.WHENOPEN)
		return
	end
	if w:has'locked' then
		p(mp.msg.Open.WHENLOCKED)
		return
	end
	w:attr'open'
	return false
end

function mp:after_Open(w)
	p(mp.msg.Open.OPEN)
	if w:has'container' then
		self:content(w)
	end
end

mp.msg.Close = {}

function mp:Close(w)
	if mp:check_touch() then
		return
	end
	if not w:has'openable' then
		p(mp.msg.Close.NOTOPENABLE)
		return
	end
	if not w:has'open' then
		p(mp.msg.Close.WHENCLOSED)
		return
	end
	w:attr'~open'
	return false
end

function mp:after_Close(w)
	p(mp.msg.Close.CLOSE)
end
function mp:check_live(w)
	if self:animate(w) then
		p(mp.msg.LIVE_ACTION)
		return true
	end
	return false
end

function mp:check_held(t)
	if have(t) or std.me() == t then
--	if (std:me():lookup(t) and t:visible()) or std.me() == t then
		return false
	end
	mp.msg.TAKE_BEFORE(t)
	mp:subaction('Take', t)
	if not have(t) then
--		mp.msg.NOTINV(t)
		return true
	end
	return false
end

function mp:check_inside(w)
	if std.me():where() ~= std.here() and not w:inside(std.me():where()) then
		p (mp.msg.Enter.EXITBEFORE)
		return true
	end
	return false
end

function mp:check_worn(w)
	if w:has'worn' then
		mp.msg.DISROBE_BEFORE(w)
		mp:subaction('Disrobe', w)
		if w:has'worn' then
--			p (mp.msg.Drop.WORN)
			return true
		end
	end
	return false
end

mp.msg.Lock = {}
function mp:Lock(w, t)
	if mp:check_touch() then
		return
	end
	if mp:check_held(t) then
		return
	end
	local r = std.call(w, 'with_key')
	if not w:has 'lockable' or not r then
		p(mp.msg.Lock.IMPOSSIBLE)
		return
	end
	if w:has 'locked' then
		p(mp.msg.Lock.LOCKED)
		return
	end
	if w:has 'open' then
		mp.msg.CLOSE_BEFORE(w)
		mp:subaction('Close', w)
		if w:has 'open' then
			p(mp.msg.Lock.OPEN)
			return
		end
	end
	if std.object(r) ~= t then
		p(mp.msg.Lock.WRONGKEY)
		return
	end
	w:attr'locked'
	return false
end

function mp:after_Lock(w, t)
	p(mp.msg.Lock.LOCK)
end

mp.msg.Unlock = {}
function mp:Unlock(w, t)
	if mp:check_touch() then
		return
	end
	if mp:check_held(t) then
		return
	end
	local r = std.call(w, 'with_key')
	if not w:has 'lockable' or not r then
		p(mp.msg.Unlock.IMPOSSIBLE)
		return
	end
	if not w:has 'locked' then
		p(mp.msg.Unlock.NOTLOCKED)
		return
	end
	if std.object(r) ~= t then
		p(mp.msg.Unlock.WRONGKEY)
		return
	end
	w:attr'~locked'
--	w:attr'open'
	return false
end

function mp:after_Unlock(w, t)
	p(mp.msg.Unlock.UNLOCK)
end

function mp:inside(w, wh)
	wh = std.object(wh)
	w = std.object(w)
	return mp:trace(w, function(v)
			 if v == wh then return true end
	end)
end
function inside(w, wh)
	return mp:inside(w, wh)
end
std.obj.inside = function(s, wh)
	return mp:inside(s, wh)
end

std.obj.move = function(s, wh)
	return mp:move(s, wh)
end

function move(w, wh)
	return mp:move(w, wh, true)
end
function mp:move(w, wh, force)
	wh = wh or std.here()
	wh = std.object(wh)
	w = std.object(w)
	local r, v
	local ww = {}

	if not force then
		local n = self:runorval(wh, 'capacity')
		local capacity = n and tonumber(n)
		if capacity and #wh.obj >= capacity then
			mp.msg.NOROOM(wh)
			return false
		end
		w:where(ww)
	end

	for _, o in ipairs(ww) do
		if mp:runmethods('before', 'LetGo', w, wh) then
			return false
		end
	end

	if w:type'player' then
		r, v = w:walk(wh)
		if r then p(r) end
	else
		place(w, wh)
		if mp:inside(std.me(), w) then
			r, v = std.me():walk(w)
			if r then p(r) end
		end
	end
	w:attr 'moved'
	for _, o in ipairs(ww) do
		if mp:runmethods('after', 'LetGo', w, wh) then
			return false
		end
	end
	return true
end

mp.msg.Take = {}
function mp:Take(w, ww)
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		p (mp.msg.Take.SELF)
		return
	end
	if have(w) then
		p (mp.msg.Take.HAVE)
		return
	end
	local n = mp:trace(std.me(), function(v)
		if v == w then return true end
	end)
	if n then
		p (mp.msg.Take.WHERE)
		return
	end
	if mp:animate(w) then
		p (mp.msg.Take.LIFE)
		return
	end
	if w:has'static' then
		p (mp.msg.Take.STATIC)
		return
	end
	if w:has'scenery' then
		p (mp.msg.Take.SCENERY)
		return
	end
	if not w:where():type'room' and
		not w:where():has'container' and
		not w:where():has'supporter' then
		if w:has'worn' then
			p (mp.msg.Take.WORN)
		else
			p (mp.msg.Take.PARTOF)
		end
		return
	end
	if not mp:move(w, std.me()) then return true end
	return false
end

function mp:after_Take(w)
	p (mp.msg.Take.TAKE)
end
mp.msg.Remove = {}
function mp:Remove(w, wh)
	if mp:check_touch() then
		return
	end
	if w:where() ~= wh then
		p (mp.msg.Remove.WHERE)
		return
	end
	mp:xaction('Take', w)
end

function mp:after_Remove(w, wh)
	p (mp.msg.Remove.REMOVE)
end

mp.msg.Drop = {}
function mp:Drop(w)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	if mp:check_worn(w) then
		return
	end
	if w == std.me() then
		p (mp.msg.Drop.SELF)
		return
	end
	if not mp:move(w, std.me():where()) then return true end
	return false
end

function mp:after_Drop(w)
	p (mp.msg.Drop.DROP)
end

mp.msg.Insert = {}

function mp:Insert(w, wh)
	if mp:check_touch() then
		return
	end
	if wh == std.me() then
		mp:xaction('Take', w)
		return
	end
	if w == std.me() then
		mp:xaction('Enter', wh)
		return
	end
	if wh == w:where() then
		p (mp.msg.Insert.ALREADY)
		return
	end
	if wh == std.me():where() or mp:compass_dir(wh, 'd_to') then
		mp:xaction('Drop', w)
		return
	end
	if mp:check_held(w) then
		return
	end
	if mp:check_worn(w) then
		return
	end
	if mp:check_live(wh) then
		return
	end

	local n = mp:trace(wh, function(v)
		if v == w then return true end
	end)
	if n or w == wh then
		p (mp.msg.Insert.WHERE)
		return
	end

	if mp:runmethods('before', 'Receive', wh, w) then
		return
	end

	if not wh:has'container' then
		if wh:has'supporter' then
			mp:xaction("PutOn", w, wh)
			return
		end
		p(mp.msg.Insert.NOTCONTAINER)
		return
	end
	if not wh:has'open' then
		p(mp.msg.Insert.CLOSED)
		return
	end
	if not mp:move(w, wh) then return true end
	return false
end

function mp:after_Insert(w, wh)
	if mp:runmethods('after', 'Receive', wh, w) then
		return
	end
	p(mp.msg.Insert.INSERT)
end

mp.msg.PutOn = {}

function mp:PutOn(w, wh)
	if mp:check_touch() then
		return
	end
	if wh == std.me() then
		mp:xaction('Take', w)
		return
	end
	if w == std.me() then
		mp:xaction('Enter', wh)
		return
	end
	if wh == std.me():where() or mp:compass_dir(wh, 'd_to') then
		mp:xaction('Drop', w)
		return
	end
	if mp:check_held(w) then
		return
	end
	if mp:check_live(wh) then
		return
	end
	if mp:check_worn(w) then
		return
	end
	local n = mp:trace(wh, function(v)
		if v == w then return true end
	end)
	if n or w == wh then
		p (mp.msg.PutOn.WHERE)
		return
	end
	if mp:runmethods('before', 'Receive', wh, w) then
		return
	end
	if not wh:has'supporter' then
		p(mp.msg.PutOn.NOTSUPPORTER)
		return
	end
	if not mp:move(w, wh) then return true end
	return false
end

function mp:after_PutOn(w, wh)
	if mp:runmethods('after', 'Receive', wh, w) then
		return
	end
	p(mp.msg.PutOn.PUTON)
end

mp.msg.ThrowAt = {}

function mp:ThrowAt(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	if mp:check_worn(w) then
		return
	end
	if mp:runmethods('before', 'ThrownAt', wh, w) then
		return
	end
	if not self:animate(wh) then
		if wh:has'container' then
			mp:xaction("Insert", w, wh)
			return
		end
		p(mp.msg.ThrowAt.NOTLIFE)
		return
	end
	if mp:runmethods('life', 'ThrowAt', wh, w) then
		return
	end
	p(mp.msg.ThrowAt.THROW)
end

mp.msg.Wear = {}

function mp:Wear(w)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	if not w:has'clothing' then
		p (mp.msg.Wear.NOTCLOTHES)
		return
	end
	if w:has'worn' then
		p (mp.msg.Wear.WORN)
		return
	end
	w:attr'worn'
	return false
end

function mp:after_Wear(w)
	p (mp.msg.Wear.WEAR)
end

mp.msg.Disrobe = {}

function mp:Disrobe(w)
	if mp:check_touch() then
		return
	end
	if not have(w) or not w:has'worn' then
		p (mp.msg.Disrobe.NOTWORN)
		return
	end
	w:attr'~worn'
	return false
end

function mp:after_Disrobe(w)
	p (mp.msg.Disrobe.DISROBE)
end

mp.msg.SwitchOn = {}

function mp:SwitchOn(w)
	if mp:check_touch() then
		return
	end
	if not w:has'switchable' then
		p (mp.msg.SwitchOn.NONSWITCHABLE)
		return
	end
	if w:has'on' then
		p (mp.msg.SwitchOn.ALREADY)
		return
	end
	w:attr'on'
	return false
end

function mp:after_SwitchOn(w)
	p (mp.msg.SwitchOn.SWITCHON)
end

mp.msg.SwitchOff = {}

function mp:SwitchOff(w)
	if mp:check_touch() then
		return
	end
	if not w:has'switchable' then
		p (mp.msg.SwitchOff.NONSWITCHABLE)
		return
	end
	if not w:has'on' then
		p (mp.msg.SwitchOn.ALREADY)
		return
	end
	w:attr'~on'
	return false
end

function mp:after_SwitchOff(w)
	p (mp.msg.SwitchOff.SWITCHOFF)
end

mp.msg.Search = {}

function mp:Search(w)
	mp:xaction('Exam', w)
end

mp.msg.LookUnder = {}
function mp:LookUnder(w)
	p (mp.msg.LookUnder.NOTHING)
end

mp.msg.Eat = {}

function mp:Eat(w)
	if mp:check_touch() then
		return
	end
	if not w:has'edible' then
		p (mp.msg.Eat.NOTEDIBLE)
		return
	end
	if mp:check_held(w) then
		return
	end
	if mp:check_worn(w) then
		return
	end
	remove(w)
	return false
end

function mp:after_Eat(w)
	p (mp.msg.Eat.EAT)
end

mp.msg.Taste = {}

function mp:Taste(w)
	if mp:check_touch() then
		return
	end
	if w:has'edible' then
		mp:xaction("Eat", w)
		return
	end
	return false
end

function mp:after_Taste(w)
	p (mp.msg.Taste.TASTE)
end

mp.msg.Drink = {}

function mp:after_Drink(w)
	p (mp.msg.Drink.IMPOSSIBLE)
end

mp.msg.Transfer = {}

function mp:Transfer(w, ww)
	if mp:check_touch() then
		return
	end
	if mp:compass_dir(ww) then
		mp:xaction('PushDir', w, ww)
		return
	end
	if ww:has 'supporter' then
		mp:xaction('PutOn', w, ww)
		return
	end
	mp:xaction('Insert', w, ww)
end

mp.msg.Push = {}

function mp:Push(w)
	if mp:check_touch() then
		return
	end
	if w:has 'switchable' then
		if w:has'on' then
			mp:xaction('SwitchOff', w)
		else
			mp:xaction('SwitchOn', w)
		end
		return
	end
	if w:has 'static' then
		p (mp.msg.Push.STATIC)
		return
	end
	if w:has 'scenery' then
		p (mp.msg.Push.SCENERY)
		return
	end
	if mp:check_live(w) then
		return
	end
	p (mp.msg.Push.PUSH)
end

mp.msg.Pull = {}

function mp:Pull(w)
	if mp:check_touch() then
		return
	end
	if w:has 'static' then
		p (mp.msg.Pull.STATIC)
		return
	end
	if w:has 'scenery' then
		p (mp.msg.Pull.SCENERY)
		return
	end
	if mp:check_live(w) then
		return
	end
	p (mp.msg.Pull.PULL)
end

mp.msg.Turn = {}

function mp:Turn(w)
	if mp:check_touch() then
		return
	end
	if w:has 'static' then
		p (mp.msg.Turn.STATIC)
		return
	end
	if w:has 'scenery' then
		p (mp.msg.Turn.SCENERY)
		return
	end
	if mp:check_live(w) then
		return
	end
	p (mp.msg.Turn.TURN)
end

mp.msg.Wait = {}
function mp:after_Wait()
	p (mp.msg.Wait.WAIT)
end

mp.msg.Rub = {}

function mp:Rub(w)
	if mp:check_touch() then
		return
	end
	p (mp.msg.Rub.RUB)
end

mp.msg.Sing = {}

function mp:Sing(w)
	p (mp.msg.Sing.SING)
end

mp.msg.Touch = {}

function mp:Touch(w)
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		p (mp.msg.Touch.MYSELF)
		return
	end
	if self:animate(w) then
		p (mp.msg.Touch.LIVE)
		return
	end
	p (mp.msg.Touch.TOUCH)
end

mp.msg.Give = {}

function mp:Give(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	if wh == std.me() then
		p (mp.msg.Give.MYSELF)
		return
	end
	if mp:runmethods('life', 'Give', wh, w) then
		return
	end
	p (mp.msg.Give.GIVE)
end

mp.msg.Show = {}

function mp:Show(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	if wh == std.me() then
		mp:xaction("Exam", w)
		return
	end
	if mp:runmethods('life', 'Show', wh, w) then
		return
	end
	p (mp.msg.Show.SHOW)
end

mp.msg.Burn = {}

function mp:Burn(w, wh)
	if mp:check_touch() then
		return
	end
	if wh and mp:check_held(wh) then
		return
	end
	if wh then
		p (mp.msg.Burn.BURN2)
	else
		p (mp.msg.Burn.BURN)
	end
end

mp.msg.Wake = {}

function mp:Wake()
	p (mp.msg.Wake.WAKE)
end

mp.msg.WakeOther = {}

function mp:WakeOther(w)
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		mp:xaction('Wake')
		return
	end
	if not mp:animate(w) then
		p (mp.msg.WakeOther.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'WakeOther', w) then
		return
	end
	p (mp.msg.WakeOther.WAKE)
end

mp.msg.PushDir = {}
function mp:PushDir(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	p (mp.msg.PushDir.PUSH)
end

mp.msg.Kiss = {}
function mp:Kiss(w)
	if mp:check_touch() then
		return
	end
	if not mp:animate(w) then
		p (mp.msg.Kiss.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'Kiss', w) then
		return
	end
	if w == std.me() then
		p (mp.msg.Kiss.MYSELF)
		return
	end
	p (mp.msg.Kiss.KISS)
end

mp.msg.Think = {}
function mp:Think()
	p (mp.msg.Think.THINK)
end

mp.msg.Smell = {}
function mp:Smell(w)
	if mp:check_touch() then
		return
	end
	if w then
		p (mp.msg.Smell.SMELL2)
		return
	end
	p (mp.msg.Smell.SMELL)
end

mp.msg.Listen = {}
function mp:Listen(w)
	if mp:check_touch() then
		return
	end
	if w then
		p (mp.msg.Listen.LISTEN2)
		return
	end
	p (mp.msg.Listen.LISTEN)
end

mp.msg.Dig = {}
function mp:Dig(w, wh)
	if mp:check_touch() then
		return
	end
	if w and mp:check_live(w) then
		return
	end
	if wh then
		if mp:check_held(wh) then
			return
		end
		p (mp.msg.Dig.DIG3)
		return
	end
	if w then
		p (mp.msg.Dig.DIG2)
		return
	end
	p (mp.msg.Dig.DIG)
end

mp.msg.Cut = {}
function mp:Cut(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	if wh then
		if mp:check_live(wh) then
			return
		end
		if mp:check_held(wh) then
			return
		end
		p (mp.msg.Cut.CUT2)
		return
	end
	if w then
		p (mp.msg.Cut.CUT)
		return
	end
end

mp.msg.Tie = {}

function mp:Tie(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	if wh and mp:check_live(wh) then
		return
	end
	if wh then
		p (mp.msg.Tie.TIE2)
		return
	end
	p (mp.msg.Tie.TIE)
end

mp.msg.Blow = {}

function mp:Blow(w)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	p (mp.msg.Blow.BLOW)
end

mp.msg.Attack = {}

function mp:Attack(w)
	if mp:check_touch() then
		return
	end
	if mp:animate(w) and mp:runmethods('life', 'Attack', w) then
		return
	end
	if mp:animate(w) then
		p (mp.msg.Attack.LIFE)
		return
	end
	p (mp.msg.Attack.ATTACK)
end

mp.msg.Sleep = {}

function mp:Sleep()
	p (mp.msg.Sleep.SLEEP)
end

mp.msg.Swim = {}

function mp:Swim()
	p (mp.msg.Swim.SWIM)
end

mp.msg.Consult = {}

function mp:Consult(w, a)
	if mp:check_touch() then
		return
	end
	p (mp.msg.Consult.CONSULT)
end

mp.msg.Fill = {}
function mp:Fill(w)
	if mp:check_touch() then
		return
	end
	p (mp.msg.Fill.FILL)
end

mp.msg.Jump = {}
function mp:Jump()
	p (mp.msg.Jump.JUMP)
end

mp.msg.JumpOver = {}
function mp:JumpOver(w)
	if mp:check_touch() then
		return
	end
	p (mp.msg.JumpOver.JUMPOVER)
end

mp.msg.WaveHands = {}
function mp:WaveHands()
	p (mp.msg.WaveHands.WAVE)
end

mp.msg.Wave = {}
function mp:Wave(w)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	p (mp.msg.Wave.WAVE)
end

function mp:Climb(w)
	mp:xaction('Enter', w)
end

function mp:GetOff(w)
	mp:xaction('Exit', w)
end

mp.msg.Buy = {}
function mp:Buy(w)
	if mp:check_touch() then
		return
	end
	p (mp.msg.Buy.BUY)
end

mp.msg.Talk = {}
function mp:Talk(w)
	if mp:check_touch() then
		return
	end
	local r = std.call(w, 'talk_to')
	if r then
		walkin(r)
		return
	end
	if w == std.me() then
		p (mp.msg.Talk.SELF)
		return
	end
	if not mp:animate(w) then
		p (mp.msg.Talk.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'Talk', w) then
		return
	end
	p (mp.msg.Talk.LIVE)
end

mp.msg.Tell = {}
function mp:Tell(w, t)
	if mp:check_touch() then
		return
	end
	if #self.vargs == 0 then
		p (mp.msg.Tell.EMPTY)
		return
	end
	if w == std.me() then
		p (mp.msg.Tell.SELF)
		return
	end
	if not mp:animate(w) then
		p (mp.msg.Tell.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'Tell', w, t) then
		return
	end
	p (mp.msg.Tell.LIVE)
end

mp.msg.Ask = {}
function mp:Ask(w, t)
	if mp:check_touch() then
		return
	end
	if #self.vargs == 0 then
		p (mp.msg.Ask.EMPTY)
		return
	end
	if w == std.me() then
		p (mp.msg.Ask.SELF)
		return
	end
	if not mp:animate(w) then
		p (mp.msg.Ask.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'Ask', w, t) then
		return
	end
	p (mp.msg.Ask.LIVE)
end

function mp:AskFor(w, t)
	if w == std.me() then
		mp:xaction('Inv')
		return
	end
	mp:xaction('Ask', w, t)
end

function mp:AskTo(w, t)
	mp:xaction('Ask', w, t)
end

mp.msg.Answer = {}

function mp:Answer(w, t)
	if mp:check_touch() then
		return
	end
	if #self.vargs == 0 then
		p (mp.msg.Answer.EMPTY)
		return
	end
	if w == std.me() then
		p (mp.msg.Answer.SELF)
		return
	end
	if not mp:animate(w) then
		p (mp.msg.Answer.NOTLIVE)
		return
	end
	if mp:runmethods('life', 'Answer', w, t) then
		return
	end
	p (mp.msg.Answer.LIVE)
end

mp.msg.Yes = {}

function mp:Yes()
	p (mp.msg.Yes.YES)
end

function mp:No()
	p (mp.msg.Yes.YES)
end

function mp:Transcript()
	if self.logfile then
		p("Log file: ", self.logfile)
	else
		self:TranscriptOn()
	end
end

function mp:TranscriptOff()
	self.logfile = false
	self.lognum = self.lognum + 1
	p("Logging is stopped.")
end

function mp:TranscriptOn()
	while true do
		local logfile = string.format("%s/log%03d.txt", instead.gamepath(), self.lognum)
		local f = io.open(logfile, "rb")
		if not f then
			self.logfile = logfile
			p ("Logging is enabled: ", logfile)
			return
		end
		f:close()
		self.lognum = self.lognum + 1
	end
end

function mp:MetaSave()
	instead.menu 'save'
end

function mp:MetaLoad()
	instead.menu 'load'
end

function mp:MetaWord(w)
	w = w:gsub("_", "/")
	local w, g = self.mrd:word(w)
	pn(w)
	for _, v in ipairs(g) do
		pn (_, ":")
		for k, vv in pairs(v) do
			pn(k, " = ", vv)
		end
	end
end

local function getobj(w)
	if std.is_tag(w) then
		return std.here():lookup(w) or std.me():lookup(w)
	end
	return std.ref(w)
end

function mp:MetaNoun(w)
	local varg = self.vargs
	local o = getobj(varg[1])
	if not o then
		p ("Wrong object: ", varg[1])
		return
	end
	local t = {}
	local w
	if #varg == 2 then
		w = o:noun(varg[2], t)
	else
		w = o:noun(t)
	end
	pn "== Words:"
	for _, v in ipairs(w or {}) do
		pn(v)
	end
	pn "== Grams:"
	for _, v in ipairs(t or {}) do
		for kk, vv in pairs(v) do
			pn(kk, " = ", vv)
		end
	end

end
function mp:MetaTraceOn()
	pn "Tracing is on"
	self.debug.trace_action = true
end
function mp:MetaTraceOff()
	pn "Tracing is off"
	self.debug.trace_action = false
end

local __oini = std.obj.__ini

local function fn_aliases(wh)
	local new = {}
	for k, f in pairs(wh) do -- "before_Take,Drop..."
		if (type(f) == 'function' or type(f) == 'string') and k:find("[a-zA-Z]+,") then
			local ss, ee = k:find("^[a-z]+_")
			local pref = ''
			local str = k
			if ss then pref = k:sub(1, ee); str = k:sub(ee + 1) end
			local m = std.split(str, ",")
			for _, v in ipairs(m) do
				new[pref .. v] = f
			end
		end
	end
	for k, v in pairs(new) do
		wh[k] = v
	end
end
std.obj.__ini = function(s, ...)
	if s.__mp_ini then
		return __oini(s, ...)
	end
	if type(s.found_in) == 'string' then
		s.found_in = { s.found_in }
	end
	if type(s.found_in) == 'table' then
		for _, v in ipairs(s.found_in) do
			local vv = v
			v = std.ref(v)
			if not v then
				std.err("Wrong object in found_in list of: "..tostring(s).."/"..vv, 2)
			end
			v.obj:add(s)
		end
		std.rawset(s, 'found_in', nil)
	elseif type(s.found_in) == 'function' then
		s:persist()
	end
	if type(s.scope) == 'table' and not std.is_obj('list', s.scope) then
		s.scope = std.list (s.scope)
	end
	fn_aliases(s.__ro)
	std.rawset(s, "__mp_ini", true)
	return __oini(s, ...)
end

function parent(w)
	w = std.object(w)
	return w:where()
end

function Class(t, w)
	fn_aliases(t)
	if not w then
		return std.class(t, std.obj)
	end
	return std.class(t, w)
end

std.obj.once = function(s, n)
	if type(n) == 'string' then
		n = '__once_'..n
	else
		n = '__once'
	end
	if not s[n] then
		s[n] = true
		return true
	end
	return false
end

std.obj.daemonStart = function(s)
	game.__daemons:add(s)
end

std.obj.daemonStop = function(s)
	game.__daemons:del(s)
end

function DaemonStart(w)
	std.object(w):daemonStart()
end

function DaemonStop(w)
	std.object(w):daemonStop()
end
