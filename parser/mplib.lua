--luacheck: globals mp
--luacheck: no self

local tostring = std.tostr
local table = std.table
local type = type
local string = string
--- Error handler
-- @param err error code
function mp:err(err)
	local parsed = false
	if self:comment() then
		return
	end
	if std.here().OnError then
		std.here():OnError(err)
		return
	end
	if err == "UNKNOWN_VERB" then
		local verbs
		if mp.errhints then
			verbs = self:lookup_verb(self.words, true)
		end
		local hint = false
		if verbs and #verbs > 0 then
			for _, verb in ipairs(verbs) do
				local fixed = verb.verb[verb.word_nr]
				if verb.verb_nr == 1 then
					hint = true
					mp:message('UNKNOWN_VERB', self.words[verb.verb_nr])
					mp:message('UNKNOWN_VERB_HINT', fixed.word .. (fixed.morph or ""))
					break
				end
			end
		end
		if not hint then
			mp:message('UNKNOWN_VERB', self.words[1])
		end
	elseif err == "EMPTY_INPUT" then
		p (mp:mesg('EMPTY') or "Empty input.")
	elseif err == "INCOMPLETE" or err == "UNKNOWN_WORD" then
		local need_noun
		local second_noun
		for _, v in ipairs(self.hints) do
			local verb = ''
			if self.hints.match then
				for _, vv in pairs(self.hints.match.verb) do
					verb = verb .. vv .. ' '
				end
				verb = verb:gsub(" $", "")
				for _, vv in ipairs(self.hints.match) do
					verb = verb .. ' '.. vv
				end
				for _, vv in pairs(self.hints.match.args) do
					if vv.ob then
						second_noun = true
					end
				end
				if not parsed then
					parsed = verb
				end
				if second_noun then second_noun = verb end
			end
			if v:find("^~?{noun}") then need_noun = v break end
		end
		if #self.unknown > 0 and (not need_noun or
				self.unknown.lev == self.hints.lev) then
			local unk = ''
			for _, v in ipairs(self.unknown) do
				if unk ~= '' then unk = unk .. ' ' end
				unk = unk .. v
			end
			if need_noun then
				if mp.errhints then
					mp:message('UNKNOWN_OBJ', unk);
				else
					mp:message('UNKNOWN_OBJ');
				end
			else
				if mp.errhints then
					mp:message('UNKNOWN_WORD', unk);
				else
					mp:message('UNKNOWN_WORD');
				end
			end
			if mp:thedark() and need_noun then
				mp:message 'UNKNOWN_THEDARK'
				return
			end
			if need_noun then
				if #self.hints == 0 or not self.hints.fuzzy then
					return
				end
			end
		elseif err == "UNKNOWN_WORD" then
			mp:message('UNKNOWN_WORD')
		else
			if need_noun then
				if second_noun then
					mp:message('INCOMPLETE_SECOND_NOUN', second_noun .." " ..mp:err_noun(need_noun))
				else
					mp:message('INCOMPLETE_NOUN', parsed)
				end
			else
				mp:message 'INCOMPLETE'
			end
		end
		if not mp.errhints or need_noun then
			return
		end
		local words = {}
		local dups = {}
		for _, v in ipairs(self.hints) do
			if v:find("^~?{noun}") or v == '*' or v == '~*' then
				if v:sub(1,1) == '~' then v = v:sub(2) end
				v = mp:err_noun(v)
				if not dups[v] then
					table.insert(words, v)
					dups[v] = true
				end
			else
				local pat = self:pattern(v)
				local empty = true
				for _, vv in ipairs(pat) do
					if not vv.hidden then
						empty = false
						break
					end
				end
				for _, vv in ipairs(pat) do
					if (empty or not vv.hidden) and not dups[vv.word] then
						table.insert(words, vv.word)
						dups[vv.word] = true
					end
				end
			end
--			if need_noun then
--				break
--			end
		end
		if #words > 0 then
			if err == 'INCOMPLETE' then
				if #words > 2 and parsed then
					parsed = parsed .. ': '
				end
				p (mp:mesg 'HINT_WORDS', ", ", parsed or '')
			else
				p (mp:mesg 'HINT_WORDS', ", ")
			end
		end

		for k, v in ipairs(words) do
			if k ~= 1 then
				if k == #words then
					pr (" ", mp.msg.OR, " ")
				else
					pr (", ")
				end
			end
			pr(iface:em(v))
		end
		if #words > 0 then
			p "?"
		end
	elseif err == "MULTIPLE" then
		pr (mp:mesg 'MULTIPLE', " ", self.multi[1])
		for k = 2, #self.multi do
			if k == #self.multi then
				pr (" ", mp.msg.AND, " ", self.multi[k])
			else
				pr (", ", self.multi[k])
			end
		end
		pr "."
	elseif err then
		pr (err)
	end
end


local everything = std.obj {
	nam = '@all';
	hint_noun = false;
	before_Any = function(_, ev)
		if ev == 'Exam' then
			mp:xaction("Look")
			return
		end
		if not mp.expert_mode or
			(ev ~= 'Drop' and ev ~= 'Take' and ev ~= 'Remove') then
			mp:message 'NO_ALL'
			return
		end
		return false
	end;
}:attr 'concealed':persist()

--- Clear the metaparser window
function mp:clear()
	self.text = ''
end

--- Clear the metaparser prompt
-- @see mp.clear_on_move
function mp:cls_prompt()
	if std.call_ctx[1] then
		std.call_ctx[1].txt = ''
	end
end

--- Standard door class
mp.door = std.class({
	before_Walk = function(s)
		return s:before_Enter();
	end;
	before_Enter = function(s)
		if mp:check_inside(s) then
			return
		end
		if not s:has 'open' then
			local t = std.call(s, 'when_closed')
			if t then
				p(t)
			else
				mp:message 'Enter.DOOR_CLOSED'
			end
			return
		end
		local r, v = mp:runorval(s, 'door_to')
		if not v then
			mp:message 'Enter.DOOR_NOWHERE'
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

function mp:pnoun(noun, msg)
	local ctx = mp:save_ctx()
	mp.first = noun
	mp.first_hint = noun:gram().hint
	std.p(mp.fmt(msg)) -- first is available only here, so fmt is forced
	mp:restore_ctx(ctx)
end

mp.cutscene =
std.class({
	enter = function(s)
		s.__num = 1
	end;
	ini = function(s)
		std.rawset(s, 'text', s.text)
		std.rawset(s.__var, 'text', nil)
		if not s.__num then
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
		else
			if type(s.text) == 'string' then
				p (s.text)
			else
				p (s.text[s.__num])
			end
		end
		if mp.msg.CUTSCENE_MORE then
			p("^", mp.msg.CUTSCENE_MORE)
		end
	end;
	OnError = function(_, _) -- s, err
		mp:message 'CUTSCENE_HELP'
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

mp.gameover =
std.class({
	before_Default = function()
		mp:message 'GAMEOVER_HELP';
	end;
	before_Look = function()
		mp:message 'GAMEOVER_HELP';
	end;
	OnError = function()
		mp:message 'GAMEOVER_HELP';
	end;
}, std.room)

-- player
mp.msg.Look = {}

function std.obj:multi_alias(n)
	if n then
		self.__word_alias = n
	end
	return self.__word_alias
end

std.room.dsc = function(_)
	mp:message 'SCENE';
end

local function trace_light(v)
	if v:has 'light' then
		return true
	end
	if v:has 'container' and not v:has 'transparent' and not v:has 'open' then
		return nil, false
	end
end

--- Check if the player or the specified object is in darkness
-- @param what check if this is in darkness; player by default
function mp:thedark(what)
	if std.me():has'light' or mp:traceinside(std.me(), trace_light) then
		return false
	end
	local w = what or std.me():where()
	local h = mp:light_scope(w)
	if h:has'light' then return false end
	return not mp:traceinside(h, trace_light)
end

function std.obj:scene()
	local s = self
	local sc = mp:visible_scope(s)
	local title = iface:title(std.titleof(sc))
	if s ~= sc then
		local r = std.call(std.me():where(), "title")
		title = title .. ' '..mp.fmt("(".. (r or mp:mesg('TITLE_INSIDE')) .. ")")
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
		if mp.clear_on_move and player_moved() then
			mp:cls_prompt()
		end
		self.__room_where = false
		return r, v
	end
	if std.is_obj(w) then -- into object
		if dofrom ~= false and std.me():where() ~= w then
			w.__from = std.me():where()
		end
		if w:inroom() == std.ref(self.room) then
			self.__room_where = w
			self:need_scene(true)
			return nil, true
		end
		local r, v = owalk(self, w:inroom(), doexit, doenter, dofrom)
		if mp.clear_on_move and player_moved() then
			mp:cls_prompt()
		end
		self.__room_where = w
		return r, v
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
	local inexit = s.__in_onexit or s.__in_exit
	local inwalk = (s.__room_where and s.__room_where:inroom() ~= std.here())
	if inexit or inwalk then -- fallback to room
		if type(where) == 'table' then
			table.insert(where, std.ref(s.room))
		end
		return std.ref(s.room)
	end
	if type(where) == 'table' then
		table.insert(where, std.ref(s.__room_where or s.room))
	end
	return std.ref(s.__room_where or s.room)
end

std.room.display = function(s)
	local c = std.call(mp, 'content', s)
	return c
end

function mp:light_scope(s)
	local h = s
	if not s:has 'container' or s:has 'transparent' or s:has 'open' then
		mp:trace(s, function(v)
				h = v
				if v:has 'container' and not v:has'transparent' and not v:has 'open' then
					return nil, false
				end
		end)
	end
	return h
end

--- Find the maximum visible scope for an object
-- @param s where
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

local last_gfx = false

std.player.look = function(s)
	local scene, img
	local r = s:where()
	if s:need_scene() then
		local gfx
		gfx = std.call(std.here(), 'gfx') or std.call(std.game, 'gfx')
		if not gfx and instead.tiny then
			gfx = stead.call(std.here(), 'pic') or stead.call(std.ref 'game', 'pic')
		end
		if gfx and gfx ~= last_gfx then
			img = fmt.c(fmt.img(gfx))
			last_gfx = gfx
		end
		scene = r:scene()
	end
	return (std.par(std.scene_delim, img or false, scene or false, r:display() or false, std.call(mp, 'footer') or false))
end

--
local function check_persist(w)
	if not w:has 'persist' then
		return false
	end
	if not w.found_in then
		return true
	end
	local _, v = std.call(w, 'found_in')
	return v
end

function std.obj:access()
	local plw = {}
	if std.me():where() == self then
		return true
	end

	if self:has 'persist' then
		if not self.found_in then
			return true
		end
		local _, v = std.call(self, 'found_in')
		return v
	end
	if mp.scope:lookup(self) then
		return true
	end
	mp:trace(std.me(), function(v)
--		if v:has 'concealed' then
--			return nil, false
--		end
		plw[v] = true
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
		if plw[v] then
			return true
		end
		if v:has 'container' and not v:has 'open' then
			return nil, false
		end
	end)
end

function mp:distance(v, wh)
	local plw = {}
	wh = wh or std.me()
	local a = 0
	mp:trace(wh, function(s)
		plw[s] = a
		table.insert(plw, s)
		a = a + 1
		if s:has 'container' then
			return nil, false
		end
	end)

	local dist
	if v:where() ~= wh then
		dist = 1
		if not mp:trace(v, function(o)
			if plw[o] then
				dist = dist + plw[o]
				return true
			end
			dist = dist + 1
		end) then
			dist = 10000 -- infinity
		end
	else
		dist = 0
	end
	return dist
end

--- Check if the object is lit
-- @param what
function mp:offerslight(what)
	if what and what:has'light' or what:has'luminous' or mp:inside(what, std.me()) then
		return true
	end
	return not mp:thedark()
end

function std.obj:visible()
	local plw = { }
	if std.me():where() == self then
		return true
	end

	if not mp:offerslight(self) then
		return false
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
	if type(dsc) ~= 'string' then
		std.err("Empty dsc in phrase", 2)
	end
	return dsc .. '|'.. (tostring(s.__ph_idx) or std.dispof(s))
end

std.phr.Exam = function(s, ...)
	std.me():need_scene(true)
	return s:act(...)
end

std.phr.__xref = function(_, str)
	return str
end

std.dlg.ini = function(s, load)
	if std.here() == s and not visited(s) and not load then
		s:enter()
	end
end
std.dlg.scene = std.obj.scene
std.dlg.title = false
std.dlg.OnError = function(_, _) -- s, err
	mp:message 'DLG_HELP'
end;

std.dlg.nouns = function(s)
	local nr
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
		return '-- '
	end
	return (string.format("%d) ", n))
end

--- Construct a compass direction from action name.
local function compass_dir(dir)
	return obj {
		nam = '@'..dir;
		default_Event = 'Walk';
		before_Any = function(_, ev, ...)
			return std.object '@compass':action(dir, ev, ...)
		end
	}:attr'light,enterable,concealed':persist()
end

obj {
	nam = '@compass';
	visible = function() return false end;
	action = function(s, dir, ev, ...)
		if ev == 'Exam' then
			local d = dir
			local r, v, _
			_, v = mp:runorval(std.here(), 'compass_look', d)
			if v then
				return
			end
			r, v = mp:runorval(std.here(), d, d)
			if r then -- somewhat?
				if std.object(r):type 'room' then
					mp:message 'COMPASS_EXAM_NO'
					return
				end
				mp:message('COMPASS_EXAM', d, std.object(r))
				return
			end
			if not v then
				mp:message 'COMPASS_EXAM_NO'
				return
			end
			return v
		end
		if ev == 'Walk' or ev == 'Enter' then
			local d = dir
			if not std.me():where():type'room' then
				mp:message 'Enter.EXITBEFORE'
				return
			end
			if std.here()[d] == nil and d == 'out_to' then
				mp:xaction("Exit")
				return
			end
			local r, v = mp:runorval(std.here(), d, d)
			if not v then
				local t, vv = mp:runorval(std.here(), 'cant_go', dir)
				if vv then
					if t then p(t) end
					return
				end
				mp:message 'COMPASS_NOWAY'
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
		return std.call(s, 'before_Default', ev, ...)
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


--- Check if object is a compass direction.
-- @param w the object to check
-- @param dir optional arg to check againist selected dir
mp.compass_dir = function(_, w, dir)
	if not dir then
		local nam = tostring(w.nam):gsub("^@", "")
		return w:where() and w:where() ^ '@compass' and nam
	end
	return w ^ ('@'..dir)
end

mp.msg.INFODSC = function(o)
	return mp:infodsc(o)
end

mp.detailed_attr = {
	{ 'worn' },
	{ 'open', 'openable'},
--	{ 'on', 'switchable'},
--	{ 'light' }
}

function mp:infodsc(ob)
	local info = {}
	for _, v in ipairs(self.detailed_attr) do
		local hit = #v > 0
		for _, vv in ipairs(v) do
			if ob:hasnt(vv) then
				hit = false
				break
			end
		end
		if hit then
			local n = 'HAS_'..string.upper(v[1])
			if mp.msg[n] then
				table.insert(info, mp:mesg(n, ob))
			end
		end
	end

	if #info > 0 then
		pr(" (")
		for k, i in ipairs(info) do
			if #info > 1 and k == #info then
				pr(' ', mp.msg.AND, ' ')
			elseif k > 1 then
				pr(", ")
			end
			pr(i)
		end
		pr(")")
	end
end

function mp:multidsc(oo, inv)
	local t = {}
	local dup = {}
	local hint = type(inv) == 'string' and inv or ''
	for _, v in ipairs(oo) do
		local n
		if not v:has'concealed' then
			if inv == true then
				n = std.call(v, 'inv')
			end
			if type(v.a_noun) == 'function' then
				n = n or v:a_noun(hint, 1)
			else
				n = n or v:noun(hint, 1)
			end
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
			pr (ob:noun(hint .. ','..self.mrd.lang.gram_t.plural, 1), " (", dup[v], " ", mp:mesg('ENUM', dup[v], ob), ")")
		else
			pr (v)
			pr(mp:mesg('INFODSC', ob))
		end
	end
end

-- Default priority in content
function mp:defpri(w)
	if mp:animate(w) then
		return -1
	end
	return 0
end

mp.msg.Exam = {}
--- Display the object contents
function mp:content(w, exam)
	if w:type 'dlg' then
		return
	end
	local oo = {}
	local ooo = {}
	local expand = {}
	local inside
	if (w == std.me():where() or std.here() == w) and
		(mp.event == 'Look' or mp.event == 'Exam' or std.me():need_scene()) then
		inside = true
		local dsc, v
		-- pn()
		if mp:thedark(w) then
			dsc, v = std.call(w, 'dark_dsc')
			if dsc then p(dsc) end
			if not v then
				mp:message 'WHEN_DARK'
			end
		else
			if w:type'room' and not w:has'visited' and w.init_dsc ~= nil then
				dsc, v = std.call(w, 'init_dsc')
			else
				dsc, v = std.call(w, w:type'room' and 'dsc' or 'inside_dsc')
			end
			if dsc then p(dsc) end
			if not v then
				mp:message 'INSIDE_SCENE'
			end
		end
		p(std.scene_delim)
	end
	self:objects(w, oo, false)
	if w == std.here() then
		self:objects(self.persistent, oo, false)
	end
	std.sort(oo, function (a, b)
		a = std.tonum(a.pri) or mp:defpri(a)
		b = std.tonum(b.pri) or mp:defpri(b)
		if a == b then
			return nil
		end
		return a < b
	end)
	local something
	for _, v in ipairs(oo) do
		local r, rc, desc
		if not v:has'scenery' and not v:has'concealed' then
			if std.me():where() == v then
				r, rc = std.call(v, 'inside_dsc')
				if r then p(r); desc = true; end
			end
			if not rc and not v:has 'moved' then
				r, rc = std.call(v, 'init_dsc')
				if r then p(r); desc = true; end
			end
			if not rc then
				r, rc = std.call(v, 'dsc')
				if r then p(r); desc = true; end
			end
			if not rc and (v:has'openable') then
				if v.when_open ~= nil and v:has'open' then
					r, rc = std.call(v, 'when_open')
				elseif v.when_closed ~= nil and not v:has'open' then
					r, rc = std.call(v, 'when_closed')
				end
				if r then p(r); desc = true; end
			elseif not rc and (v:has'switchable') then
				if v.when_on ~= nil and v:has'on' then
					r, rc = std.call(v, 'when_on')
				elseif v.when_off ~= nil and not v:has'on' then
					r, rc = std.call(v, 'when_off')
				end
				if r then p(r); desc = true; end
			end
			something = something or desc
			if not rc then
				table.insert(expand, v)
				if not desc then
					table.insert(ooo, v)
				end
			end
		end
	end
--	if #ooo > 0 then
--		p(std.scene_delim)
--	end
	oo = ooo
	if #oo == 0 then
		if not inside and exam and mp.first == w and not something then
			mp:message ('Exam.NOTHING', w)
		end
	else
		mp:message('Exam.CONTENT', w, oo)
	end
-- expand?
	for _, o in ipairs(expand) do
		if (o:has'supporter' or o:has'transparent' or (o:has'container' and o:has'open')) and not o:closed() then
			self:content(o)
		end
	end
end

std.room:attr 'enterable,light'

function mp:strip(r)
	if std.strip_call and type(r) == 'string' then
		r = r:gsub("^[%^\n\r\t ]+", "") -- extra heading ^ and spaces
		r = r:gsub("[%^\n\r\t ]+$", "") -- extra trailing ^ and spaces
	end
	return r
end

function mp:step()
	local old_daemons = {}
	game.__daemons:for_each(function(o)
		table.insert(old_daemons, o)
	end)
	for _, o in ipairs(old_daemons) do
		if not o:disabled() then
			local r, v = mp:runorval(o, 'daemon')
			if r == true and v == true then break end
		end
	end
	local oo = mp:nouns()
	std.here():attr 'visited'
	for _, v in ipairs(oo) do
		if v.each_turn ~= nil then
			local r = mp:runorval(v, 'each_turn')
			if r == true then
				break
			end
		end
	end
	local s = std.game -- after reset game is recreated
	local r = mp:strip(std.pget())
	s:reaction(r or false)
	std.pclr()
	s:step()
	r = mp:strip(s:display(true))
	s:lastreact(s:reaction() or false)
	s:lastdisp(r)
	std.pr(r)
	std.abort_cmd = true
end

function mp:post_action()
	if (self.event and self.event:find("Meta", 1, true)) or self:comment() or self:noparser() then
		if std.abort_cmd then
			return
		end
		local s = std.game
		local r = mp:strip(std.pget())
		s:reaction(r or false)
		std.pclr()
		r = mp:strip(s:display(self:noparser()))
		s:lastdisp(r)
		s:lastreact(s:reaction() or false)
		std.pr(r)
		std.abort_cmd = true
		return
	end
	if mp.undo > 0 then
		local nr = #snapshots.data
		if nr > mp.undo  then
			table.remove(snapshots.data, 1)
			nr = nr - 1
		end
		mp.snapshot = nr + 1
	end
	if self.score and (self.score ~= (self.__old_score or 0)) then
		mp:message('SCORE', self.score - (self.__old_score or 0))
		self.__old_score = self.score
	end

	if game.player:need_scene() then
--		pn(iface:nb'')
		local l = game.player:look() -- objects [and scene]
		p(l, std.scene_delim)
		game.player:need_scene(false)
	end
	mp:step()
end
--- Check if mp.first and mp.second objects are in touch zone
-- Returns true if we have to terminate the sequence.
function mp:check_touch()
	if self.first and not self.first:access() and not self.first:type'room' then
		p (mp:mesg('ACCESS1') or "{#First} is not accessible.")
		if std.here() ~= std.me():where() then
			mp:message 'EXITBEFORE'
		end
		return true
	end
	if self.second and not self.second:access() and not self.first:type'room' then
		p (mp:mesg('ACCESS2') or "{#Second} is not accessible.")
		if std.here() ~= std.me():where() then
			mp:message 'EXITBEFORE'
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
			mp:message 'EXITBEFORE'
		end
		return
	end

	if self.second and not self.second:access() and not self.first:type'room' then
		p (self.msg.ACCESS2 or "{#Second} is not accessible.")
		if std.here() ~= std.me():where() then
			mp:message 'EXITBEFORE'
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
--luacheck: push ignore w wh
function mp:Exam(w)
	return false
end

function mp:after_Exam(w)
	local r, v = std.call(w, 'description')
	local something = false
	if r then
		p(r)
		something = true
	end
	if v then
		return false
	end
	if w:has 'container' and (w:has'transparent' or w:has'open') then
		self:content(w, not something)
	elseif w:has 'supporter' then
		self:content(w, not something)
	else
		if w:has'openable' then
			if w:has 'open' then
				local t = std.call(w, 'when_open')
				if t then
					p(t)
				else
					mp:message 'Exam.OPENED'
				end
			else
				local t = std.call(w, 'when_closed')
				if t then
					p(t)
				else
					mp:message 'Exam.CLOSED'
				end
			end
			return
		end
		if w:has'switchable' then
			local t
			if w:has'on' and w.when_on ~= nil then
				t = std.call(w, 'when_on')
			else
				t = std.call(w, 'when_off')
			end
			if t then
				p(t)
			else
				mp:message 'Exam.SWITCHSTATE'
			end
			return
		end
		if w == std.here() then
			std.me():need_scene(true)
		else
			if w == std.me() then
				mp:message 'Exam.SELF'
			else
				mp:message 'Exam.DEFAULT'
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
		mp:message 'Enter.ALREADY'
		return
	end

	if w:has'clothing' and not w:has'enterable' then
		mp:xaction ("Wear", w)
		return
	end

	if seen(w, std.me()) then
		mp:message 'Enter.INV'
		return
	end

	if not w:has 'enterable' then
		mp:message 'Enter.IMPOSSIBLE'
		return
	end

	if w:has 'container' and not w:has 'open' then
		mp:message 'Enter.CLOSED'
		return
	end

	if mp:check_inside(w) then
		return
	end

	if not mp:move(std.me(), w) then return true end
	return false
end

function mp:after_Enter(w)
	mp:message 'Enter.ENTERED'
end

mp.msg.Walk = {}

function mp:Walk(w)
	if mp:check_touch() then
		return
	end
	if w == std.me():where() then
		mp:message 'Walk.ALREADY'
		return
	end

	if seen(w, std.me()) then
		mp:message 'Walk.INV'
		return
	end

--	if std.me():where() ~= std.here() then
--		mp:message 'Enter.EXITBEFORE'
--		return
--	end
	return false
end

function mp:after_Walk(w)
	if not w then
		mp:message 'Walk.NOWHERE'
	else
		mp:message 'Walk.WALK'
	end
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
		if have(w) and w:has'worn' then
			mp:xaction ("Disrobe", w)
			return
		end
		if wh:inside(w) then
			mp:message 'Enter.EXITBEFORE'
			return
		end
		mp:message 'Exit.NOTHERE'
		return
	end
	if wh:has'container' and not wh:has'open' then
		mp:message 'Exit.CLOSED'
		return
	end

	if wh:type'room' and wh.out_to ~= nil then
		mp:xaction("Walk", _'@out_to')
		return
	end

	if wh:from() == wh or wh:type 'room' then
		mp:message 'Exit.NOWHERE'
		return
	end
--	if wh:type'room' then
--	local r = std.call(w, 'out_to')
--		mp:move(std.me(), wh:from())
--	else
		if not mp:move(std.me(), wh:where()) then return true end
--	end
	return false
end

function mp:after_Exit(w)
	if w and not w:type 'room' then
		mp:message 'Exit.EXITED'
	end
end

mp.msg.Inv = {}

function mp:detailed_Inv(wh, indent)
	local oo = {}
	self:objects(wh, oo, false)
	for _, o in ipairs(oo) do
		if not o:has'concealed' then
			for _ = 1, indent do pr(iface:nb' ') end
			local inv = std.call(o, 'inv') or o:noun(1)
			pr(inv)
			mp:message('INFODSC', o)
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
		mp:message 'Inv.NOTHING'
		return
	end
	local empty = true
	for _, v in ipairs(oo) do
		if not v:has'concealed' then empty = false break end
	end
	if empty then
		mp:message 'Inv.NOTHING'
		return
	end
	pr(mp:mesg 'Inv.INV')
	if mp.detailed_inv then
		pn(":")
		mp:detailed_Inv(std.me(), 1)
	else
		p()
		mp:multidsc(oo, true)
		p "."
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
		mp:message 'Open.NOTOPENABLE'
		return
	end
	if w:has'open' then
		mp:message 'Open.WHENOPEN'
		return
	end
	if w:has'locked' then
		mp:message 'Open.WHENLOCKED'
		return
	end
	w:attr'open'
	return false
end

function mp:after_Open(w)
	mp:message 'Open.OPEN'
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
		mp:message 'Close.NOTOPENABLE'
		return
	end
	if not w:has'open' then
		mp:message 'Close.WHENCLOSED'
		return
	end
	w:attr'~open'
	return false
end

function mp:after_Close(w)
	mp:message 'Close.CLOSE'
end

--- Show mp message using mp.msg constant
-- args uses only for functions
function mp:message(m, ...)
	p(mp:mesg(m, ...))
end

-- same as above, but do not call p
function mp:mesg(m, ...)
	local t = std.split(m, ".")
	m = mp.msg
	for _, n in ipairs(t) do
		m = m[n]
		if not m then
			std.err("Wrong message id: "..tostring(n), 2)
		end
	end
	if type(m) ~= 'function' then
		return m
	else
		std.callpush()
		local v = m(...)
		local r = std.pget()
		std.callpop()
		return r or v
	end
end
--- Check if the object is alive.
-- If yes, return standard message.
-- Returns true if we have to terminate the sequence.
-- @param w object to check
function mp:check_live(w)
	if self:animate(w) then
		mp:message('LIVE_ACTION', w)
		return true
	end
	return false
end

function mp:check_no_live(w)
	if not self:animate(w) then
		mp:message('NO_LIVE_ACTION', w)
		return true
	end
	return false
end

--- Check if the object is held by the player.
-- If not, attempt to take it.
-- Returns true if we have to terminate the sequence.
-- @param t object to check
function mp:check_held(t)
	if have(t) or std.me() == t then
--	if (std:me():lookup(t) and t:visible()) or std.me() == t then
		return false
	end
	mp:message('TAKE_BEFORE', t)
	mp:subaction('Take', t)
	if not have(t) then
--		mp:message('NOTINV', t)
		return true
	end
	return false
end

function mp:check_inside(w)
	if std.me():where() ~= std.here() and not w:inside(std.me():where()) then
		mp:message 'Enter.EXITBEFORE'
		return true
	end
	return false
end

--- Check if the object is worn by the player.
-- If yes, attempt to take it off.
-- Returns true if we have to terminate the sequence.
-- @param w object to check
function mp:check_worn(w)
	if w:has'worn' then
		mp:message('DISROBE_BEFORE', w)
		mp:subaction('Disrobe', w)
		if w:has'worn' then
--			mp:message 'Drop.WORN'
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
		mp:message 'Lock.IMPOSSIBLE'
		return
	end
	if w:has 'locked' then
		mp:message 'Lock.LOCKED'
		return
	end
	if w:has 'open' then
		mp:message('CLOSE_BEFORE', w)
		mp:subaction('Close', w)
		if w:has 'open' then
			mp:message 'Lock.OPEN'
			return
		end
	end
	if std.object(r) ~= t then
		mp:message 'Lock.WRONGKEY'
		return
	end
	w:attr'locked'
	return false
end

function mp:after_Lock(w, wh)
	mp:message 'Lock.LOCK'
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
		mp:message 'Unlock.IMPOSSIBLE'
		return
	end
	if not w:has 'locked' then
		mp:message 'Unlock.NOTLOCKED'
		return
	end
	if std.object(r) ~= t then
		mp:message 'Unlock.WRONGKEY'
		return
	end
	w:attr'~locked'
--	w:attr'open'
	return false
end

function mp:after_Unlock(w, wh)
	mp:message 'Unlock.UNLOCK'
end

--- Check if the object is inside an object.
-- @param w what
-- @param wh where
function mp:inside(w, wh)
	wh = std.object(wh)
	w = std.object(w)
	return mp:trace(w, function(v)
			 if v == wh then return true end
	end)
end
--- Check if the object is inside an object.
-- @see mp:inside
function inside(w, wh)
	return mp:inside(w, wh)
end
--- Check if the object is inside an object.
-- @see mp:inside
std.obj.inside = function(s, wh)
	return mp:inside(s, wh)
end

std.obj.move = function(s, wh)
	return mp:move(s, wh, true)
end

--- Move an object
-- @see mp:move
function move(w, wh)
	return mp:move(w, wh, true)
end
--- Move an object
-- @param w       what
-- @param wh      where
-- @param force   ignore capacity flag if true
function mp:move(w, wh, force)
	wh = wh or std.here()
	wh = std.object(wh)
	w = std.object(w)
	local r
	local ww = {}

	if not force then
		local n = self:runorval(wh, 'capacity')
		local capacity = n and tonumber(n)
		if capacity and #wh.obj >= capacity then
			mp:message('NOROOM', wh)
			return false
		end
		w:where(ww)

		for _, o in ipairs(ww) do
			if mp:runmethods('before', 'LetGo', o, w, wh) then
				return false
			end
		end

		if mp:runmethods('before', 'LetIn', wh, w) then
			return false
		end
	end

	if w:type'player' then
		r = w:walk(wh)
		if r then p(r) end
	else
		local wpl =  mp:inside(std.me(), w)
		place(w, wh)
		if wpl then
			r = std.me():walk(w)
			if r then p(r) end
		end
	end
	w:attr 'moved'

	if not force then
		for _, o in ipairs(ww) do
			if mp:runmethods('after', 'LetGo', o, w, wh) then
				return false
			end
		end

		if mp:runmethods('after', 'LetIn', wh, w) then
			return false
		end
	end

	return true
end

mp.msg.Take = {}

local function cont_taken(ob, taken)
	for _, o in ipairs(taken) do
		if ob:inside(o) then
			return true
		end
	end
end

--- Check if object is part of parent
-- @param w       what
function mp:partof(w)
	return w:where() and not w:where():type'room' and
		not w:where():has'container' and
		not w:where():has'supporter'
end

function mp:TakeAll(wh)
	local empty = true
	wh = wh or std.me():where()
	local oo = {}
	mp:objects(wh, oo)
	local taken = {}
	for _, o in ipairs(oo) do
		if o:hasnt 'static' and o:hasnt'scenery' and o:hasnt 'concealed'
			and not mp:animate(o)
			and not cont_taken(o, taken)
			and not mp:partof(o) then
			empty = false
			mp:message('TAKING_ALL', o)
			mp:subaction('Take', o)
			if not have(o) then
				break
			end
			table.insert(taken, o)
		end
	end
	if empty then
		mp:message 'NOTHING_OBJ'
	end
end

function mp:Take(w, wh)
	if w == everything then
		return mp:TakeAll(wh)
	end
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		mp:message 'Take.SELF'
		return
	end
	if have(w) then
		mp:message 'Take.HAVE'
		return
	end
	local n = mp:trace(std.me(), function(v)
		if v == w then return true end
	end)
	if n then
		mp:message 'Take.WHERE'
		return
	end
	if mp:animate(w) then
		mp:message 'Take.LIFE'
		return
	end
	if w:has'static' then
		mp:message 'Take.STATIC'
		return
	end
	if w:has'scenery' then
		mp:message 'Take.SCENERY'
		return
	end
	if mp:partof(w) then
		if w:has'worn' and mp:animate(w:where()) then
			mp:message 'Take.WORN'
		else
			mp:message 'Take.PARTOF'
		end
		return
	end
	if not mp:move(w, std.me()) then return true end
	return false
end

function mp:after_Take(w)
	mp:message 'Take.TAKE'
end

mp.msg.Remove = {}

function mp:Remove(w, wh)
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		mp:xaction("Exit", wh)
		return
	end
	if w:where() ~= wh and w:inroom() ~= wh and w ~= everything then
		mp:message 'Remove.WHERE'
		return
	end
	if wh == std.me() then
		mp:xaction('Disrobe', w, wh)
		return
	end
	mp:xaction('Take', w, wh)
end

function mp:after_Remove(w, wh)
	mp:message 'Remove.REMOVE'
end

mp.msg.Drop = {}
function mp:DropAll(wh)
	local empty = true
	local oo = {}
	mp:objects(std.me(), oo, false)
	for _, o in ipairs(oo) do
		if o:hasnt 'concealed' then
			empty = false
			mp:message('DROPPING_ALL', o)
			mp:subaction('Drop', o)
			if have(o) then
				break
			end
		end
	end
	if empty then
		mp:message 'NOTHING_OBJ'
	end
end

function mp:Drop(w)
	if w == everything then
		return mp:DropAll()
	end
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
		mp:message 'Drop.SELF'
		return
	end
	if not mp:move(w, std.me():where()) then return true end
	return false
end

function mp:after_Drop(w)
	mp:message 'Drop.DROP'
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
		mp:message 'Insert.ALREADY'
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
		mp:message 'Insert.WHERE'
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
		mp:message 'Insert.NOTCONTAINER'
		return
	end
	if not wh:has'open' then
		mp:message 'Insert.CLOSED'
		return
	end
	if not mp:move(w, wh) then return true end
	return false
end

function mp:after_Insert(w, wh)
	if mp:runmethods('after', 'Receive', wh, w) then
		return
	end
	mp:message 'Insert.INSERT'
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
		mp:xaction('Climb', wh)
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
		mp:message 'PutOn.WHERE'
		return
	end
	if mp:runmethods('before', 'Receive', wh, w) then
		return
	end
	if not wh:has'supporter' then
		mp:message 'PutOn.NOTSUPPORTER'
		return
	end
	if not mp:move(w, wh) then return true end
	return false
end

function mp:after_PutOn(w, wh)
	if mp:runmethods('after', 'Receive', wh, w) then
		return
	end
	mp:message 'PutOn.PUTON'
end

mp.msg.ThrowAt = {}

function mp:ThrowAt(w, wh)
	if mp:check_touch() then
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
	if mp:runmethods('before', 'ThrownAt', wh, w) then
		return
	end
	if mp:runmethods('life', 'ThrowAt', wh, w) then
		return
	end
	if not self:animate(wh) then
		if wh:has'container' then
			mp:xaction("Insert", w, wh)
			return
		end
		if wh:has'supporter' then
			mp:xaction("PutOn", w, wh)
			return
		end
		mp:message 'ThrowAt.NOTLIFE'
		return
	end
	mp:message 'ThrowAt.THROW'
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
		mp:message 'Wear.NOTCLOTHES'
		return
	end
	if w:has'worn' then
		mp:message 'Wear.WORN'
		return
	end
	w:attr'worn'
	return false
end

function mp:after_Wear(w)
	mp:message 'Wear.WEAR'
end

mp.msg.Disrobe = {}

function mp:Disrobe(w)
	if mp:check_touch() then
		return
	end
	if not have(w) or not w:has'worn' then
		mp:message 'Disrobe.NOTWORN'
		return
	end
	w:attr'~worn'
	return false
end

function mp:after_Disrobe(w)
	mp:message 'Disrobe.DISROBE'
end

mp.msg.SwitchOn = {}

function mp:SwitchOn(w)
	if mp:check_touch() then
		return
	end
	if not w:has'switchable' then
		mp:message 'SwitchOn.NONSWITCHABLE'
		return
	end
	if w:has'on' then
		mp:message 'SwitchOn.ALREADY'
		return
	end
	w:attr'on'
	return false
end

function mp:after_SwitchOn(w)
	mp:message 'SwitchOn.SWITCHON'
end

mp.msg.SwitchOff = {}

function mp:SwitchOff(w)
	if mp:check_touch() then
		return
	end
	if not w:has'switchable' then
		mp:message 'SwitchOff.NONSWITCHABLE'
		return
	end
	if not w:has'on' then
		mp:message 'SwitchOff.ALREADY'
		return
	end
	w:attr'~on'
	return false
end

function mp:after_SwitchOff(w)
	mp:message 'SwitchOff.SWITCHOFF'
end

mp.msg.Search = {}

function mp:Search(w)
	mp:xaction('Exam', w)
end

mp.msg.LookUnder = {}
function mp:LookUnder(w)
	mp:message 'LookUnder.NOTHING'
end

mp.msg.Eat = {}

function mp:Eat(w)
	if mp:check_touch() then
		return
	end
	if not w:has'edible' then
		mp:message 'Eat.NOTEDIBLE'
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
	mp:message 'Eat.EAT'
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

	if mp:check_live(w) then
		return
	end

	return false
end

function mp:after_Taste(w)
	mp:message 'Taste.TASTE'
end

mp.msg.Drink = {}

function mp:after_Drink(w)
	mp:message 'Drink.IMPOSSIBLE'
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
		mp:message 'Push.STATIC'
		return
	end
	if w:has 'scenery' then
		mp:message 'Push.SCENERY'
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_Push()
	mp:message 'Push.PUSH'
end

mp.msg.Pull = {}

function mp:Pull(w)
	if mp:check_touch() then
		return
	end
	if w:has 'static' then
		mp:message 'Pull.STATIC'
		return
	end
	if w:has 'scenery' then
		mp:message 'Pull.SCENERY'
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_Pull()
	mp:message 'Pull.PULL'
end

mp.msg.Turn = {}

function mp:Turn(w)
	if mp:check_touch() then
		return
	end
	if w:has 'static' then
		mp:message 'Turn.STATIC'
		return
	end
	if w:has 'scenery' then
		mp:message 'Turn.SCENERY'
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_Turn()
	mp:message 'Turn.TURN'
end

mp.msg.Wait = {}
function mp:after_Wait()
	mp:message 'Wait.WAIT'
end

mp.msg.Rub = {}

function mp:Rub(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Rub()
	mp:message 'Rub.RUB'
end

mp.msg.Sing = {}

function mp:after_Sing(w)
	mp:message 'Sing.SING'
end

mp.msg.Touch = {}

function mp:Touch(w)
	if mp:check_touch() then
		return
	end
	if w == std.me() then
		mp:message 'Touch.MYSELF'
		return
	end
	if self:animate(w) then
		mp:message 'Touch.LIVE'
		return
	end
	return false
end

function mp:after_Touch()
	mp:message 'Touch.TOUCH'
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
		mp:message 'Give.MYSELF'
		return
	end
	if mp:runmethods('life', 'Give', wh, w) then
		return
	end
	if mp:check_no_live(wh) then
		return
	end
	return false
end

function mp:after_Give()
	mp:message 'Give.GIVE'
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
	if mp:check_no_live(wh) then
		return
	end
	return false
end

function mp:after_Show()
	mp:message 'Show.SHOW'
end

mp.msg.Burn = {}

function mp:Burn(w, wh)
	if mp:check_touch() then
		return
	end
	if wh and mp:check_held(wh) then
		return
	end
	return false
end

function mp:after_Burn(w, wh)
	if wh then
		mp:message 'Burn.BURN2'
	else
		mp:message 'Burn.BURN'
	end
end

mp.msg.Wake = {}

function mp:after_Wake()
	mp:message 'Wake.WAKE'
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
	if mp:runmethods('life', 'WakeOther', w) then
		return
	end
	if not mp:animate(w) then
		mp:message 'WakeOther.NOTLIVE'
		return
	end
	return false
end

function mp:after_WakeOther()
	mp:message 'WakeOther.WAKE'
end

mp.msg.PushDir = {}
function mp:PushDir(w, wh)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_PushDir()
	mp:message 'PushDir.PUSH'
end

mp.msg.Kiss = {}
function mp:Kiss(w)
	if mp:check_touch() then
		return
	end
	if mp:runmethods('life', 'Kiss', w) then
		return
	end
	if not mp:animate(w) then
		mp:message 'Kiss.NOTLIVE'
		return
	end
	if w == std.me() then
		mp:message 'Kiss.MYSELF'
		return
	end
	return false
end

function mp:after_Kiss()
	mp:message 'Kiss.KISS'
end

mp.msg.Think = {}
function mp:after_Think()
	mp:message 'Think.THINK'
end

mp.msg.Smell = {}
function mp:Smell(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Smell(w)
	if w then
		mp:message 'Smell.SMELL2'
		return
	end
	mp:message 'Smell.SMELL'
end

mp.msg.Listen = {}
function mp:Listen(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Listen(w)
	if w then
		mp:message 'Listen.LISTEN2'
		return
	end
	mp:message 'Listen.LISTEN'
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
	end
	return false
end

function mp:after_Dig(w, wh)
	if wh then
		mp:message 'Dig.DIG3'
		return
	end
	if w then
		mp:message 'Dig.DIG2'
		return
	end
	mp:message 'Dig.DIG'
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
	end
	return false
end

function mp:after_Cut(w, wh)
	if wh then
		mp:message 'Cut.CUT2'
	else
		mp:message 'Cut.CUT'
	end
end

mp.msg.Tear = {}
function mp:Tear(w)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_Tear()
	mp:message 'Tear.TEAR'
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
	return false
end

function mp:after_Tie(w, wh)
	if wh then
		mp:message 'Tie.TIE2'
		return
	end
	mp:message 'Tie.TIE'
end

mp.msg.Blow = {}

function mp:Blow(w)
	if mp:check_touch() then
		return
	end
	if mp:check_live(w) then
		return
	end
	return false
end

function mp:after_Blow()
	mp:message 'Blow.BLOW'
end

mp.msg.Attack = {}

function mp:Attack(w)
	if mp:check_touch() then
		return
	end
	if mp:runmethods('life', 'Attack', w) then
		return
	end
	return false
end

function mp:after_Attack(w)
	if mp:animate(w) then
		mp:message 'Attack.LIFE'
		return
	end
	mp:message 'Attack.ATTACK'
end

mp.msg.Sleep = {}

function mp:after_Sleep()
	mp:message 'Sleep.SLEEP'
end

mp.msg.Swim = {}

function mp:after_Swim()
	mp:message 'Swim.SWIM'
end

mp.msg.Consult = {}

function mp:Consult(w, wh)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Consult()
	mp:message 'Consult.CONSULT'
end

mp.msg.Fill = {}
function mp:Fill(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Fill()
	mp:message 'Fill.FILL'
end

mp.msg.Jump = {}
function mp:after_Jump()
	mp:message 'Jump.JUMP'
end

mp.msg.JumpOver = {}
function mp:JumpOver(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_JumpOver()
	mp:message 'JumpOver.JUMPOVER'
end

mp.msg.WaveHands = {}
function mp:after_WaveHands()
	mp:message 'WaveHands.WAVE'
end

mp.msg.Wave = {}
function mp:Wave(w)
	if mp:check_touch() then
		return
	end
	if mp:check_held(w) then
		return
	end
	return false
end

function mp:after_Wave()
	mp:message 'Wave.WAVE'
end

function mp:Climb(w)
	mp:xaction('Enter', w)
end

mp.msg.GetOff = {}

function mp:GetOff(w)
	if not w and std.me():where() == std.here() then
		mp:message 'GetOff.NOWHERE'
		return
	end
	mp:xaction('Exit', w)
end

mp.msg.Buy = {}
function mp:Buy(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Buy()
	mp:message 'Buy.BUY'
end

mp.msg.Talk = {}
function mp:Talk(w)
	if mp:check_touch() then
		return
	end
	local r, v = mp:runorval(w, 'talk_to')
	if v then
		if r then
			walkin(r)
		end
		return
	end
	if w == std.me() then
		mp:message 'Talk.SELF'
		return
	end
	if mp:runmethods('life', 'Talk', w) then
		return
	end
	return false
end

function mp:after_Talk(w)
	if not mp:animate(w) then
		mp:message 'Talk.NOTLIVE'
		return
	end
	mp:message 'Talk.LIVE'
end

mp.msg.Tell = {}
function mp:Tell(w, t)
	if mp:check_touch() then
		return
	end
	if #self.vargs == 0 then
		mp:message 'Tell.EMPTY'
		return
	end
	if w == std.me() then
		mp:message 'Tell.SELF'
		return
	end
	if mp:runmethods('life', 'Tell', w, t) then
		return
	end
	return false
end

function mp:after_Tell(w)
	if not mp:animate(w) then
		mp:message 'Tell.NOTLIVE'
		return
	end
	mp:message 'Tell.LIVE'
end

mp.msg.Ask = {}
function mp:Ask(w, t)
	if mp:check_touch() then
		return
	end
	if #self.vargs == 0 then
		mp:message 'Ask.EMPTY'
		return
	end
	if w == std.me() then
		mp:message 'Ask.SELF'
		return
	end
	if mp:runmethods('life', 'Ask', w, t) then
		return
	end
	return false
end

function mp:after_Ask(w)
	if not mp:animate(w) then
		mp:message 'Ask.NOTLIVE'
		return
	end
	mp:message 'Ask.LIVE'
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
		mp:message 'Answer.EMPTY'
		return
	end
	if w == std.me() then
		mp:message 'Answer.SELF'
		return
	end
	if mp:runmethods('life', 'Answer', w, t) then
		return
	end
	return false
end

function mp:after_Answer(w)
	if not mp:animate(w) then
		mp:message 'Answer.NOTLIVE'
		return
	end
	mp:message 'Answer.LIVE'
end

mp.msg.Yes = {}

function mp:after_Yes()
	mp:message 'Yes.YES'
end

function mp:after_No()
	mp:message 'Yes.YES'
end

mp.msg.Use = {}

function mp:Use(w)
	if mp:check_touch() then
		return
	end
	return false
end

function mp:after_Use()
	mp:message 'Use.USE'
end

function mp:MetaHelp()
	pn(mp:mesg 'HELP')
end

function mp:MetaScore()
	mp:message'TITLE_TURNS'
	pn()
	mp:message'TITLE_SCORE'
end

function mp:MetaTranscript()
	if self.logfile then
		p("Log file: ", self.logfile)
	else
		self:MetaTranscriptOn()
	end
end

function mp:MetaTranscriptOff()
	self.logfile = false
	self.lognum = self.lognum + 1
	p("Logging is stopped.")
end

function mp:MetaTranscriptOn()
	while true do
		local logfile = string.format("%s/log%03d.txt", instead.gamepath(), self.lognum)
		local f = io.open(logfile, "rb")
		if not f then
			self.logfile = logfile
			if std.cctx() then
				p ("Logging is enabled: ", logfile)
			end
			return
		end
		f:close()
		self.lognum = self.lognum + 1
	end
end
function mp:MetaVersion()
	p(mp.version)
end
function mp:MetaVerbs()
	local verbs = {}
	for _, v in ipairs(mp:verbs()) do
		local vv = v.verb[1]
		if vv and not vv.hidden then
			local verb = vv.word .. (vv.morph or "")
			table.insert(verbs, verb)
		end
	end
	table.sort(verbs)
	for _, v in ipairs(verbs) do p(v) end
end

mp.msg.MetaRestart = {}

local old_pre_input

function mp:MetaRestart()
	mp:message 'MetaRestart.RESTART'
	if old_pre_input then return end
	old_pre_input = mp.pre_input
	std.rawset(mp, 'pre_input', function(_, str)
		std.rawset(mp, 'pre_input', old_pre_input)
		old_pre_input = false
		if mp:eq(str, mp.msg.YES) then
			instead.restart()
		end
		return false
	end)
end

function mp:MetaSave()
	instead.menu 'save'
end

function mp:MetaExpertOn()
	mp.autocompl = false
	mp.autohelp = false
	p [[Expert mode on.]]
end

function mp:MetaExpertOff()
	mp.autocompl = true
	mp.autohelp = true
	p [[Expert mode off.]]
end

function mp:MetaLoad()
	instead.menu 'load'
end
--luacheck: pop
local function attr_string(o)
	local a = ''
	for k, _ in pairs(o.__ro) do
		if type(k) == 'string' and k:find("__attr__", 1, true) == 1 then
			if a ~= '' then a = a .. ', ' end
			a = a .. k:sub(9)
		end
	end
	local b = ''
	for k, _ in pairs(o) do
		if type(k) == 'string' and k:find("__attr__", 1, true) == 1 then
			if b ~= '' then b = b .. ', ' end
			b = b .. k:sub(9)
		end
	end
	if b ~= '' then b = '!'..b..'' end
	a = a .. b
	if a ~= '' then a = ' [' .. a .. '] ' end
	return a
end
function mp:MetaDump()
	local oo = mp:nouns()
	for _, o in ipairs(oo) do
		if not std.is_system(o) and o ~= std.me() then
			local d = mp:distance(o)
			if d > 8 then d = 8 end
			for _ = 1, d do pr(fmt.nb' ') end
			local t = '<'..std.tostr(o)..'>'
			t = t .. (std.call(o, 'word') or std.call(o, 'raw_word') or '')
			if have(o) then t = fmt.em(t) end
			pn(t, attr_string(o))
		end
	end
end

function mp:MetaWord(w)
	if not w then return end
	w = w:gsub("_", "/")
	local g
	w, g = self.mrd:word(w)
	pn(w)
	for _, v in ipairs(g) do
		pn (_, ":")
		for k, vv in pairs(v) do
			pn(k, " = ", vv)
		end
	end
end
mp.msg.MetaUndo = {}
function mp:MetaUndo()
	local nr = #snapshots.data
	if nr > 1 then
		snapshots:restore(nr - 1)
		table.remove(snapshots.data, nr)
	else
		mp:message 'MetaUndo.EMPTY'
	end
end

local function getobj(w)
	if std.is_tag(w) then
		return std.here():lookup(w) or std.me():lookup(w)
	end
	return std.ref(w)
end

function mp:MetaNoun(_)
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

function mp:MetaAutoplay(w)
	mp:autoscript(w)
	if mp.autoplay then
		pn ([[Script file: ]], w)
	else
		pn ([[Can not open script file: ]], w)
	end
end

local __oini = std.obj.__ini

local function fn_aliases(wh)
	local new = {}
	for k, f in pairs(wh) do -- "before_Take,Drop..."
		if (type(f) == 'function' or type(f) == 'string') and
			type(k) == 'string' and k:find("[a-zA-Z]+,") then
			local ss, ee = k:find("^[a-z]+_")
			local pref = ''
			local str = k
			if ss then
				pref = k:sub(1, ee);
				if pref == 'before_' or pref == 'after_' or pref == 'post_' or pref == 'life_' then
					str = k:sub(ee + 1)
				else
					pref = ''
				end
			end
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

std.obj.for_plural = function(s, fn)
	fn = fn or function() end
	if not s:hint'plural' then
		fn(s)
		return false
	end
	for _, v in ipairs(mp.multi[s] or { s }) do
		fn(v)
	end
	return true
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

std.obj.isDaemon = function(s)
	return game.__daemons:lookup(s)
end

function DaemonStart(w)
	std.object(w):daemonStart()
end

function DaemonStop(w)
	std.object(w):daemonStop()
end

function isDaemon(w)
	return std.object(w):isDaemon()
end

instead.notitle = true

instead.get_title = function(_)
	if instead.notitle then
		return
	end
	local w = instead.theme_var('win.w')
	local title = std.titleof(std.here()) or ''
	local col = instead.theme_var('win.col.fg')
	local score = ''
	if mp.score then
		score = fmt.tab('70%', 'center')..fmt.nb(mp:mesg('TITLE_SCORE'))
	end
	local moves = fmt.tab('100%', 'right')..fmt.nb(mp:mesg('TITLE_TURNS'))
	return iface:left((title.. score .. moves).."\n".. iface:img(string.format("box:%dx1,%s", w, col)))
end

--luacheck: globals content
function content(w, ...)
	w = std.object(w)
	return mp:content(w, ...)
end
