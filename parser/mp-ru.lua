--luacheck: no self
local lang = require "morph/lang-ru"
require "parser/mp"
require "parser/mplib"
local mp = _'@metaparser'

std.mod_init(
	function()
	mp:init(lang)
end)
game.dsc = function()
	p ([[МЕТАПАРСЕР3 Версия: ]]..mp.version.."^")
	p [[http://instead-hub.github.io^^
Если вам необходима справка по игре, наберите "помощь".
^]]
end
-- local utf = mp.utf

_'@all'.word = -"всё/~од"

_'@darkness'.word = -"тьма,темнота,темень"
_'@darkness'.before_Any = "Полная, кромешная тьма."
_'@darkness':attr 'persist'

_'@n_to'.word = -"север";
_'@ne_to'.word = -"северо-восток";
_'@e_to'.word = -"восток";
_'@se_to'.word = -"юго-восток";
_'@s_to'.word = -"юг";
_'@sw_to'.word = -"юго-запад";
_'@w_to'.word = -"запад";
_'@nw_to'.word = -"северо-запад";
_'@u_to'.word = -"наверх,вверх,верх";
_'@d_to'.word = -"вниз,низ";
_'@out_to'.word = -"наружу,выход,назад";
_'@in_to'.word = -"внутрь,вход"

mp.shorten = {
	["с"] = "север";
	["в"] = "восток";
	["з"] = "запад";
	["ю"] = "юг";
	["св"] = "северо-восток";
	["юв"] = "юго-восток";
	["юз"] = "юго-запад";
	["сз"] = "северо-запад";
	["вн"] = "вниз";
	["вв"] = "вверх";
}

mp.shorten_expert = {
	["и"] = "инвентарь";
	["ж"] = "ждать";
	["о"] = "осмотреть";
	["о *"] = "осмотреть";
	["осм"] = "осмотреть";
	["осм *"] = "осмотреть";
	["вкл *"] = "включить";
	["выкл *"] = "выключить";
	["см"] = "смотреть";
	["см *"] = "смотреть";
}

mp.shorten_custom = {
	["в *"] = "идти в",
	["на *"] = "идти на",
	["во *"] = "идти во",
	["к *"] = "идти к",
	["ко *"] = "идти ко",
}

function mp:skip_filter(w)
	for _, v in ipairs(w) do
		if v == 'не' or v == 'кроме' or v == 'вместо' then
			return false
		end
	end
	return true
end

local function endswith(w, t)
	return not not w:find(t..'$')
end

function mp:verb_filter(w)
	if #w > 1 then
		return true
	end
	local utf = mp.utf
	local verb = w[1]
	local t = utf.chars(w[1])
	if endswith(verb, 'ся') or endswith(verb, 'сь') or endswith(verb, 'те') then
		local len = #verb
		len = len - utf.bb(verb, len)
		len = len - utf.bb(verb, len)
		verb = verb:sub(1, len)
	end
	if endswith(verb, 'и') or endswith(verb, 'ь') then
		return true
	end
	local t = utf.chars(verb)
	local a = { ['а'] = true, ['е'] = true, ['и'] = true,
		['о'] = true, ['у'] = true, ['ы'] = true,
		['ю'] = true, ['я'] = true };
	local len = #t
	if len >= 2 and a[t[len - 1]] and t[len] == 'й' then -- or a[t[len]] then
		return true
	end
	return false
end

_'@compass'.before_Default = function()
	p('"{#First}" это направление. {#Firstit/вн} нельзя ', mp.parsed[1], ".")
end

function mp.msg.SCORE(d)
	if d > 0 then
		pn ("{$fmt em|(Счёт увеличился на ", d, ")}")
	else
		pn ("{$fmt em|(Счёт уменьшился на ", d, ")}")
	end
end
mp.door.word = -"дверь";
mp.msg.TITLE_SCORE = function()
	if mp.maxscore then
		pr ("Счёт: ", mp.score, "/", mp.maxscore)
	else
		pr ("Счёт: ", mp.score)
	end
end
mp.msg.TITLE_TURNS = function()
	pr ("Ходы: ", game:time() - 1)
end
mp.msg.YES = "Да"
mp.msg.WHEN_DARK = "Кромешная тьма."
mp.msg.UNKNOWN_THEDARK = "Возможно, это потому что в темноте ничего не видно?"
mp.msg.COMPASS_NOWAY = "Этот путь недоступен."
mp.msg.COMPASS_EXAM_NO = "В этом направлении не видно ничего примечательного."
mp.msg.ENUM = "шт."
mp.msg.CUTSCENE_HELP = "Для продолжения нажмите <ввод> или введите {$fmt em|дальше}."
if instead.tiny then
	mp.msg.CUTSCENE_MORE = "^{$fmt em|(дальше)}"
end
mp.msg.DLG_HELP = "Для выбора фразы введите цифру."
mp.msg.NO_ALL = "Это действие нельзя применить на всё."
mp.msg.DROPPING_ALL = function(w)
	pn (iface:em("(бросить "..w:noun'вн'..")"))
end
mp.msg.TAKING_ALL = function(w)
	pn (iface:em("(взять "..w:noun'вн'..")"))
end
mp.msg.TAKE_BEFORE = function(w)
	pn (iface:em("(сначала взяв "..w:noun'вн'..")"))
end
mp.msg.DISROBE_BEFORE = function(w)
	pn (iface:em("(сначала сняв "..w:noun'вн'..")"))
end

mp.msg.CLOSE_BEFORE = function(w)
	pn (iface:em("(сначала закрыв "..w:noun'вн'..")"))
end

--"находиться"
mp.msg.SCENE = "{#Me} {#word/находиться,#me,нст} {#if_has/#here,supporter,на,в} {#here/пр,2}.";
mp.msg.INSIDE_SCENE = "{#Me} {#word/находиться,#me,нст} {#if_has/#where,supporter,на,в} {#where/пр,2}.";
mp.msg.TITLE_INSIDE = "{#if_has/#where,supporter,на,в} {#where/пр,2}";

mp.msg.COMPASS_EXAM = function(dir, ob)
	if dir == 'u_to' then
		p "Вверху"
	elseif dir == 'd_to' then
		p "Внизу"
	elseif dir == 'out_to' or dir == 'in_to' then
		p "В этом направлении"
	else
		p "На {#first/пр,2}"
	end
	if ob:hint'plural' then
		p "находятся"
	else
		p "находится"
	end
	p (ob:noun(),".")
end

mp.msg.enter = "<ввод>"
mp.msg.EMPTY = 'Простите?'
mp.msg.UNKNOWN_VERB = function(w)
	p ("Непонятный глагол ", iface:em(w), ".")
end
mp.msg.UNKNOWN_VERB_HINT = function(w)
	p ("Самое похожее слово: ", iface:em(w), ".")
end
mp.msg.INCOMPLETE = "Нужно дополнить предложение."
mp.msg.INCOMPLETE_NOUN = function(w)
	if w then
		p('К чему вы хотите применить команду "',w, '"?')
	else
		p"К чему вы хотите применить команду?"
	end
end

mp.msg.INCOMPLETE_SECOND_NOUN = function(w)
	p ('Уточните команду: "',w,'"?')
end

mp.msg.UNKNOWN_OBJ = function(w)
	if not w then
		p "Об этом предмете здесь ничего не известно."
	else
		p "Об этом предмете здесь ничего не известно "
		p ("(",w,").")
	end
end
mp.msg.NOTHING_OBJ = "Ничего подходящего нет."
mp.msg.UNKNOWN_WORD = function(w)
	if not w then
		p "Фраза не распознана."
	else
		p "Фраза не распознана "
		p ("(",w,"?).")
	end
end
mp.msg.HINT_WORDS = "Возможно"
mp.msg.AND = "и"
mp.msg.OR = "или"
mp.msg.MULTIPLE = "Тут есть"
mp.msg.LIVE_ACTION = function(w)
	p (w:It'дт'," это не понравится.")
end
mp.msg.NO_LIVE_ACTION = "Действие применимо только к одушевлённым объектам."

mp.msg.NOTINV = function(t)
	p (lang.cap(t:noun'вн') .. " сначала нужно взять.")
end
--"надет"
mp.msg.HAS_WORN = function(w)
	local hint = w:gram().hint
	return mp.mrd:word('надет/' .. hint)
end
--"открыт"
mp.msg.HAS_OPEN = function(w)
	local hint = w:gram().hint
	return mp.mrd:word('открыт/' .. hint)
end
--"включён"
mp.msg.HAS_ON = function(w)
	local hint = w:gram().hint
	return mp.mrd:word('включён/' .. hint)
end
--"светится"
mp.msg.HAS_LIGHT = function(w)
	local hint = w:gram().hint
	return mp.mrd:word('светится/' .. hint)
end

mp.msg.EXITBEFORE = "Возможно, {#me/дт} нужно сначала "..
	"{#if_has/#where,supporter,слезть {#so/{#where/рд}}.,покинуть {#where/вн}.}"

mp.default_Event = "Exam"
mp.default_Verb = "осмотреть"

--"доступен"
mp.msg.ACCESS1 = "{#First} отсюда не{#word/доступен,#first}."
mp.msg.ACCESS2 = "{#Second} отсюда не{#word/доступен,#second}."

mp.msg.Look.HEREIS = "Здесь находится"
mp.msg.Look.HEREARE = "Здесь находятся"
mp.msg.NOROOM = function(w)
	if w == std.me() then
		p ("У {#me/рд} слишком много вещей.")
	elseif w:has'supporter' then
		p ("На ", w:noun'пр,2', " больше нет места.")
	else
		p ("В ", w:noun'пр,2', " больше нет места.")
	end
end
--"включён"
--"выключен"
mp.msg.Exam.SWITCHSTATE = "{#First} сейчас {#if_has/#first,on,{#word/включён,#first},{#word/выключен,#first}}."

mp.msg.Exam.NOTHING = function(w)
	if w:has 'supporter' then
		mp:pnoun (w, "На {#first/пр,2}")
	else
		mp:pnoun (w, "В {#first/пр,2}")
	end
	p "ничего нет."
end

mp.msg.Exam.CONTENT = function(w, oo)
	local single = #oo == 1 and not oo[1]:hint 'plural'
	if std.me():where() == w or std.here() == w then
if false then
		if single then
			p "Здесь находится"
		else
			p "Здесь находятся"
		end
		mp:multidsc(oo)
else
		p "{#Me} {#word/видеть,#me,нст} здесь";
		mp:multidsc(oo, 'вн')
end
		p "."
		return
	end
	if w:has 'supporter' then
		mp:pnoun (w, "На {#first/пр,2}")
	else
		mp:pnoun (w, "В {#first/пр,2}")
	end
	if single then
		p "находится"
	else
		p "находятся"
	end
	mp:multidsc(oo)
	p "."
end

--"видеть"
mp.msg.Exam.DEFAULT = "{#Me} не {#word/видеть,#me,нст} {#vo/{#first/пр}} ничего необычного.";
mp.msg.Exam.SELF = "{#Me} не {#word/видеть,#me,нст} в себе ничего необычного.";

--"открыт"
mp.msg.Exam.OPENED = "{#First} {#word/открыт,нст,#first}."
--"закрыт"
mp.msg.Exam.CLOSED = "{#First} {#word/закрыт,нст,#first}."
--"находить"
mp.msg.LookUnder.NOTHING = "{#Me} не {#word/находить,нст,#me} под {#first/тв} ничего интересного."
--"могу"
--"закрыт"
--"держать"
--"залезать"
mp.msg.Enter.ALREADY = "{#Me} уже {#if_has/#first,supporter,на,в} {#first/пр,2}."
mp.msg.Enter.INV = "{#Me} не {#word/могу,#me,нст} зайти в то, что {#word/держать,#me,нст} в руках."
mp.msg.Enter.IMPOSSIBLE = "Но в/на {#first/вн} невозможно войти, встать, сесть или лечь."
mp.msg.Enter.CLOSED = "{#First} {#word/закрыт,#first}, и {#me} не {#word/мочь,#me,нст} зайти туда."
mp.msg.Enter.ENTERED = "{#Me} {#word/залезать,нст,#me} {#if_has/#first,supporter,на,в} {#first/вн}."
mp.msg.Enter.DOOR_NOWHERE = "{#First} никуда не ведёт."
--"закрыт"
mp.msg.Enter.DOOR_CLOSED = "{#First} {#word/закрыт,#first}."

mp.msg.Walk.ALREADY = mp.msg.Enter.ALREADY
mp.msg.Walk.WALK = "Но {#first} и так находится здесь."
mp.msg.Walk.NOWHERE = "Куда именно?"
mp.msg.Walk.INV = "Но {#first} у {#me/рд} с собой."

mp.msg.Enter.EXITBEFORE = "Сначала нужно {#if_has/#where,supporter,слезть {#so/{#where/рд}}.,покинуть {#where/вн}.}"

mp.msg.Exit.NOTHERE = "Но {#me} сейчас не {#if_has/#first,supporter,на,в} {#first/пр,2}."
mp.msg.Exit.NOWHERE = "Но {#me/дт} некуда выходить."
mp.msg.Exit.CLOSED = "Но {#first} {#word/закрыт,#first}."

--"покидать"
--"слезать"
mp.msg.Exit.EXITED = "{#Me} {#if_has/#first,supporter,{#word/слезать,#me,нст} {#so/{#first/рд}},"..
	"{#word/покидать,#me,нст} {#first/вн}}."

mp.msg.GetOff.NOWHERE = "Но {#me/дт} не с чего слезать."

mp.msg.Inv.NOTHING = "У {#me/рд} с собой ничего нет."
mp.msg.Inv.INV = "У {#me/рд} с собой"

--"открывать"
mp.msg.Open.OPEN = "{#Me} {#word/открывать,нст,#me} {#first/вн}."
mp.msg.Open.NOTOPENABLE = "{#First/вн} невозможно открыть."
--"открыт"
mp.msg.Open.WHENOPEN = "{#First/} уже {#word/открыт,#first}."
--"заперт"
mp.msg.Open.WHENLOCKED = "Похоже, что {#first/} {#word/заперт,#first}."

--"закрывать"
mp.msg.Close.CLOSE = "{#Me} {#word/закрывать,нст,#me} {#first/вн}."
mp.msg.Close.NOTOPENABLE = "{#First/вн} невозможно закрыть."
--"закрыт"
mp.msg.Close.WHENCLOSED = "{#First/} уже {#word/закрыт,#first}."

mp.msg.Lock.IMPOSSIBLE = "{#First/вн} невозможно запереть."
--"заперт"
mp.msg.Lock.LOCKED = "{#First} уже {#word/заперт,#first}."
--"закрыть"
mp.msg.Lock.OPEN = "Сначала необходимо закрыть {#first/вн}."
--"подходит"
mp.msg.Lock.WRONGKEY = "{#Second} не {#word/подходит,#second} к замку."
--"запирать"
mp.msg.Lock.LOCK = "{#Me} {#word/запирать,#me,нст} {#first/вн}."

mp.msg.Unlock.IMPOSSIBLE = "{#First/вн} невозможно отпереть."
--"заперт"
mp.msg.Unlock.NOTLOCKED = "{#First} не {#word/заперт,#first}."
--"подходит"
mp.msg.Unlock.WRONGKEY = "{#Second} не {#word/подходит,нст,#second} к замку."
--"отпирать"
mp.msg.Unlock.UNLOCK = "{#Me} {#word/отпирать,#me,нст} {#first/вн}."

mp.msg.Take.HAVE = "У {#me/вн} и так {#firstit} уже есть."
mp.msg.Take.TAKE = "{#Me} {#verb/take} {#first/вн}."
mp.msg.Take.SELF = "{#Me} есть у {#me/рд}."
--"находиться"
mp.msg.Take.WHERE = "Нельзя взять то, {#if_hint/#where,supporter,на,в} чём {#me} {#word/находиться,#me}."

mp.msg.Take.LIFE = "{#First/дт} это вряд ли понравится."
--"закреплён"
mp.msg.Take.STATIC = "{#First} жестко {#word/закреплён,#first}."
mp.msg.Take.SCENERY = "{#First/вн} невозможно взять."

--"надет"
mp.msg.Take.WORN = "{#First} {#word/надет,#first} на {#firstwhere/вн}."
mp.msg.Take.PARTOF = "{#First} {#if_hint/#first,plural,являются,является} частью {#firstwhere/рд}."

mp.msg.Remove.WHERE = "{#First} не {#word/находиться,#first,нст} {#if_has/#second,supporter,на,в} {#second/пр,2}."
--"поднят"
--"извлечён"
mp.msg.Remove.REMOVE = "{#First} {#if_has/#second,supporter,{#word/поднят с,#first},"..
	"{#word/извлечён из,#first}} {#second/рд}."

mp.msg.Drop.SELF = "У {#me/рд} не хватит ловкости."
mp.msg.Drop.WORN = "{#First/вн} сначала нужно снять."
--"помещать"
mp.msg.Insert.INSERT = "{#Me} {#word/помещать,нст,#me} {#first/вн} в {#second/вн}."
mp.msg.Insert.CLOSED = "{#Second} {#word/закрыт,#second}."
mp.msg.Insert.NOTCONTAINER = "{#Second} не {#if_hint/#second,plural,могут,может} что-либо содержать."
mp.msg.Insert.WHERE = "Нельзя поместить {#first/вн} внутрь себя."
mp.msg.Insert.ALREADY = "Но {#first} уже и так {#word/находиться,#first} там."
mp.msg.PutOn.NOTSUPPORTER = "Класть что-либо на {#second/вн} бессмысленно."
--"класть"
mp.msg.PutOn.PUTON = "{#Me} {#word/класть,нст,#me} {#first/вн} на {#second/вн}."
mp.msg.PutOn.WHERE = "Нельзя поместить {#first/вн} на себя."

--"брошен"
mp.msg.Drop.DROP = "{#First} {#word/брошен,#first}."

mp.msg.ThrowAt.NOTLIFE = "Бросать {#first/вн} в {#second/вн} бесполезно."
mp.msg.ThrowAt.THROW = "У {#me/рд} не хватает решимости бросить {#first/вн} в {#second/вн}."


mp.msg.Wear.NOTCLOTHES = "Надеть {#first/вн} невозможно."
mp.msg.Wear.WORN = "{#First} уже на {#me/дт}."
--"надевать"
mp.msg.Wear.WEAR = "{#Me} {#word/надевать,#me,нст} {#first/вн}."

mp.msg.Disrobe.NOTWORN = "{#First} не на {#me/дт}."
--"снимать"
mp.msg.Disrobe.DISROBE = "{#Me} {#word/снимать,#me,нст} {#first/вн}."

mp.msg.SwitchOn.NONSWITCHABLE = "{#First/вн} невозможно включить."
--"включён"
mp.msg.SwitchOn.ALREADY = "{#First} уже {#word/включён,#first}."
--"включать"
mp.msg.SwitchOn.SWITCHON = "{#Me} {#word/включать,#me,нст} {#first/вн}."

mp.msg.SwitchOff.NONSWITCHABLE = "{#First/вн} невозможно выключить."
--"выключён"
mp.msg.SwitchOff.ALREADY = "{#First} уже {#word/выключён,#first}."
--"выключать"
mp.msg.SwitchOff.SWITCHOFF = "{#Me} {#word/выключать,#me,нст} {#first/вн}."

--"годится"
mp.msg.Eat.NOTEDIBLE = "{#First} не {#word/годится,#first} в пищу."
mp.msg.Taste.TASTE = "Никакого необычного вкуса нет."

--"съедать"
mp.msg.Eat.EAT = "{#Me} {#word/съедать,нст,#me} {#first/вн}."
mp.msg.Drink.IMPOSSIBLE = "Выпить {#first/вн} невозможно."

mp.msg.Push.STATIC = "{#First/вн} трудно сдвинуть с места."
mp.msg.Push.SCENERY = "{#First/вн} двигать невозможно."
mp.msg.Push.PUSH = "Ничего не произошло."

mp.msg.Pull.STATIC = "{#First/вн} трудно сдвинуть с места."
mp.msg.Pull.SCENERY = "{#First/вн} двигать невозможно."
mp.msg.Pull.PULL = "Ничего не произошло."

mp.msg.Turn.STATIC = "{#First/вн} трудно сдвинуть с места."
mp.msg.Turn.SCENERY = "{#First/вн} двигать невозможно."
mp.msg.Turn.TURN = "Ничего не произошло."

mp.msg.Wait.WAIT = "Проходит немного времени."

mp.msg.Touch.LIVE = "Не стоит давать волю рукам."
mp.msg.Touch.TOUCH = "Никаких необычных ощущений нет."
mp.msg.Touch.MYSELF = "{#Me} на месте."

mp.msg.Rub.RUB = "Тереть {#first/вн} бессмысленно."
mp.msg.Sing.SING = "С таким слухом и голосом как у {#me/рд} этого лучше не делать."

mp.msg.Give.MYSELF = "{#First} и так у {#me/рд} есть."
mp.msg.Give.GIVE = "{#Second/вн} это не заинтересовало."
mp.msg.Show.SHOW = "{#Second/вн} это не впечатлило."

mp.msg.Burn.BURN = "Поджигать {#first/вн} бессмысленно."
mp.msg.Burn.BURN2 = "Поджигать {#first/вн} {#second/тв} бессмысленно."
--"поверь"
mp.msg.Wake.WAKE = "Это не сон, а явь."
mp.msg.WakeOther.WAKE = "Будить {#first/вн} не стоит."
mp.msg.WakeOther.NOTLIVE = "Бессмысленно будить {#first/вн}."

mp.msg.PushDir.PUSH = "Передвигать это нет смысла."

mp.msg.Kiss.NOTLIVE = "Странное желание."
mp.msg.Kiss.KISS = "{#Firstit/дт} это может не понравиться."
mp.msg.Kiss.MYSELF = "Ну уж нет."

mp.msg.Think.THINK = "Отличная идея!"
mp.msg.Smell.SMELL = "Никакого необычного запаха нет."
mp.msg.Smell.SMELL2 = "Пахнет как {#first}."

mp.msg.Listen.LISTEN = "Никаких необычных звуков нет."
--"прислушаться"
mp.msg.Listen.LISTEN2 = "{#Me} {#word/прислушаться,#me,прш} к {#first/дт}. Никаких необычных звуков нет."

--"выкопать"
mp.msg.Dig.DIG = "{#Me} ничего не {#word/выкопать,#me,прш}."
mp.msg.Dig.DIG2 = "Копать {#first/вн} бессмысленно."
mp.msg.Dig.DIG3 = "Копать {#first/вн} {#second/тв} бессмысленно."

mp.msg.Cut.CUT = "Резать {#first/вн} бессмысленно."
mp.msg.Cut.CUT2 = "Резать {#first/вн} {#second/тв} бессмысленно."

mp.msg.Tear.TEAR = "Рвать {#first/вн} бессмысленно."

mp.msg.Tie.TIE = "Привязывать {#first/вн} бессмысленно."
mp.msg.Tie.TIE2 = "Привязывать {#first/вн} к {#second/дт} бессмысленно."

mp.msg.Blow.BLOW = "Дуть на/в {#first/вн} бессмысленно."

mp.msg.Attack.LIFE = "Агрессия к {#first/дт} неоправданна."
mp.msg.Attack.ATTACK = "Сила есть -- ума не надо?"
--"хотеть"
mp.msg.Sleep.SLEEP = "{#Me} не {#word/хотеть,#me,нст} спать."
mp.msg.Swim.SWIM = "Для этого здесь недостаточно воды."
mp.msg.Fill.FILL = "Наполнять {#first/вн} бессмысленно."
--"подпрыгивать"
mp.msg.Jump.JUMP = "{#Me} глупо {#word/подпрыгивать,#me,нст}."
mp.msg.JumpOver.JUMPOVER = "Прыгать через {#first/вн} бессмысленно."

--"находить"
mp.msg.Consult.CONSULT = "{#Me} не {#word/находить,#me,нст} ничего подходящего."

--"помахать"
mp.msg.WaveHands.WAVE = "{#Me} глупо {#word/помахать,прш,#me} руками."
mp.msg.Wave.WAVE = "{#Me} глупо {#word/помахать,прш,#me} {#first/тв}."

mp.msg.Talk.SELF = "Беседы не получилось."
--"уметь"
mp.msg.Talk.NOTLIVE = "{#First} не {#word/уметь,#first,нст} разговаривать."
--"отреагировать"
mp.msg.Talk.LIVE = "{#First} никак не {#word/отреагировать,#first}."

mp.msg.Tell.SELF = "Беседы не получилось."

--"безмолвен"
mp.msg.Tell.NOTLIVE = "{#First} {#word/безмолвен,#first}."
--"отреагировать"
mp.msg.Tell.LIVE = "{#First} никак не {#word/отреагировать,#first}."
--"нашёл"
mp.msg.Tell.EMPTY = "{#Me} не {#word/нашёл,#me,прш} что сказать."

--"отвечать"
mp.msg.Ask.NOTLIVE = "Ответа не последовало."
--"ответить"
mp.msg.Ask.LIVE = "{#First} не {#word/ответить,прш,#first}."
--"придумать"
mp.msg.Ask.EMPTY = "{#Me} не {#word/придумать,#me,прш} что спросить."
mp.msg.Ask.SELF = "Хороший вопрос."

--"отвечать"
mp.msg.Answer.NOTLIVE = "Ответа не последовало."
--"ответить"
mp.msg.Answer.LIVE = "{#First} не {#word/ответить,прш,#first}."
--"придумать"
mp.msg.Answer.EMPTY = "{#Me} не {#word/придумать,#me,прш} что ответить."
mp.msg.Answer.SELF = "Хороший ответ."

mp.msg.Yes.YES = "Вопрос был риторическим."

mp.msg.Use.USE = "Как именно?"

--"продаваться"
mp.msg.Buy.BUY = "{#First} не {#word/продаваться,нст,#first}."

mp.keyboard_space = '<пробел>'
mp.keyboard_backspace = '<удалить>'

mp.msg.verbs.take = -"брать,#me,нст"

mp.msg.GAMEOVER_HELP = [[Чтобы начать заново, введите рестарт.]];

local function dict(t, hint)
	local g = std.split(hint, ",")
	for _, v in ipairs(g) do
		if t[v] then
			return t[v]
		end
	end
end

function mp:myself(_, hint)
	local ww = dict({
			["вн"] = { "себя" };
			["дт"] = { "себе" };
			["тв"] = {"собой" };
			["пр"] = { "себе" };
			["рд"] = { "себя" };
		 }, hint)
	return ww
end

function mp:it(w, hint)
	hint = hint or ''
	if w:hint'plural' then
		return mp.mrd:noun(-"они/"..hint)
	elseif w:hint'neuter' then
		return mp.mrd:noun(-"оно/"..hint)
	elseif w:hint'female' then
		return mp.mrd:noun(-"она/"..hint)
	end
	return mp.mrd:noun(-"он/"..hint)
end

function mp:synonyms(w, hint)
	local nt = {
		['его'] = 'него';
		['её'] = 'неё';
		['ее'] = 'нее';
		['ей'] = 'ней';
		['им'] = 'ним';
		['ими'] = 'ними';
		['их'] = 'них';
		['ему'] = 'нему';
	}
	local t = self:it(w, hint)
	return { t, nt[t] }
end

mp.keyboard = {
	'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й',
	'К','Л','М','Н','О','П','Р','О','С','Т','У','Ф',
	'Х','Ц','Ч','Ш','Щ','Ь','Ы','Ъ','Э','Ю','Я'
}

local function hints(w)
	local h = std.split(w, ",")
	local ret = {}
	for _, v in ipairs(h) do
		ret[v] = true
	end
	return ret
end

function mp:err_noun(noun)
	if noun == '*' then return "{$fmt em|<любое слово>}" end
	local hint = std.split(noun, "/")
	local rc = "{$fmt em|"
	if #hint == 2 then
		local h = hints(hint[2])
		local acc = 'кто/что'
		if h["им"] then
			acc = 'кто/что'
		elseif h["рд"] then
			acc = 'кого/чего'
		elseif h["дт"] then
			acc = 'кому/чему'
		elseif h["вн"] then
			acc = 'кого/что'
		elseif h["тв"] then
			acc = 'кем/чем'
		elseif h["пр"] or h["пр2"] then
			acc = 'ком/чём'
		end
		rc = rc ..  acc
	else
		rc = rc .. "кто/что"
	end
	rc = rc .. "}"
	return rc
end

function mp.shortcut.vo(hint)
	local w = std.split(mp.mrd.lang.norm(hint))
	local utf = mp.utf
	local vow = lang.is_vowel
	local char = utf.char
	local excl = {
		["льве"] = true,
		["львах"] = true,
		["льду"] = true,
		["льдах"] = true,
		["льне"] = true,
		["льнах"] = true,
		["лбу"] = true,
		["лбах"] = true,
		["лжи"] = true,
		["лжах"] = true,
		["мху"] = true,
		["мхах"] = true,
		["рву"] = true,
		["рвах"] = true,
		["ржи"] = true,
		["ржах"] = true,
		["рту"] = true,
		["ртах"] = true,
		["мне"] = true,
		["что"] = true,
	}
	w = w[#w]
	if mp.utf.len(w) > 2 and
		(vow(char(w, 1) == 'в' or vow(char(w, 1) == 'ф') and
		not vow(char(w, 2)))) or excl[w] then
		return "во ".. hint
	end
	return "в ".. hint
end

function mp.shortcut.so(hint)
	local so = {
		["с"] = true,
		["з"] = true,
		["ш"] = true,
		["ж"] = true,
		["л"] = true,
		["р"] = true,
		["м"] = true,
	}

	local w = std.split(mp.mrd.lang.norm(hint))
	local utf = mp.utf
	w = w[#w]
	if utf.len(w) > 2 and
		((so[utf.char(w, 1)] and
		not lang.is_vowel(utf.char(w, 2))) or utf.char(w, 1) == 'щ') then
		return "со ".. hint
	end
	if utf.len(w) > 2 and utf.char(w, 1) == 'л' and utf.char(w, 2) == 'ь' and
		not lang.is_vowel(utf.char(w, 2)) then
		return "со ".. hint
	end
	return "с ".. hint
end

function mp:before_Enter(w)
	if mp:compass_dir(w) then
		mp:xaction("Walk", w)
		return
	end
	return false
end

mp.msg.HELP = function()
	p [[{$fmt b|КАК ИГРАТЬ?}^^

Вводите ваши действия в виде простых предложений вида: глагол -- существительное. Например:^
> открыть дверь^
> отпереть дверь ключом^
> идти на север^
> взять кепку^
^
Чтобы снова увидеть описание обстановки, введите "осмотреть", "осм" или просто нажмите "ввод".^
^
Чтобы осмотреть предмет, введите "осмотреть книгу" или просто "книга".^
^
Попробуйте "осмотреть себя" и узнать, кто вы.^
^
Чтобы узнать какие предметы у вас с собой, наберите "инвентарь" или "инв".^
^
Для перемещений используйте стороны света, например: "идти на север" или "север" или просто "с". Кроме сторон света можно перемещаться вверх ("вверх" или "вв") и вниз ("вниз" или "вн"), "внутрь" и "наружу".]]
	if not instead.tiny then
		p [[^^Вы можете воспользоваться клавишей "TAB" для автодополнения ввода.]]
	else
		p [[^^Вы можете сокращать названия объектов.]]
		p [[^^Чтобы сохранять и загружать игру используйте "сохранить" и "загрузить".]]
		if instead.tiny then
			p [[Например, "сохранить 1".]]
		end
		p [[Начать заново: "заново".]]
		if instead.reinstead then
			p [[^^Также доступны команды: !restart, !quit, !info, !save, !load и !font <размер>.]]
		end
	end
end

function mp.token.compass1(_)
	return "{noun_obj}/@n_to,compass|{noun_obj}/@ne_to,compass|"..
		"{noun_obj}/@e_to,compass|{noun_obj}/@se_to,compass|"..
		"{noun_obj}/@s_to,compass|{noun_obj}/@sw_to,compass|"..
		"{noun_obj}/@w_to,compass|{noun_obj}/@nw_to,compass"
end

function mp.token.compass2(_)
	return "{noun_obj}/@u_to,compass|{noun_obj}/@d_to,compass|{noun_obj}/@in_to,compass|{noun_obj}/@out_to,compass"
end

function mp.shortcut.pref1()
	return '[по|подо|за|во|про]'
end

function mp.shortcut.pref2()
	return '[по|под|за|в|про]'
end

function mp.shortcut.pref3()
	return 'по|подъ|за|въ|про'
end

std.mod_init(function(_)
Verb { "#Walk",
	"идти,{#pref1}йти,{#pref1}йди,иди,бежать,{#pref2}бежать,бег/и,{#pref2}бег/и,влез/ть,"..
	"[|{#pref3}]ехать,едь,сесть,сядь,лечь,ляг,[в|]стать,[в|]стань[|те]",
	"на {compass1} : Walk",
	"на|в|во {noun}/вн,scene,enterable : Enter",
	"внутрь {noun}/рд,scene,enterable : Enter",
	"к {noun}/дт,scene : Walk",
	"{compass2}: Walk" }

Verb { "#Exit",
	"[вы|у]йти,выйд/и,уйд/и,вылез/ти,выхо/ди,обратно,назад,выбраться,выберись,выбираться",
	"из|с|со {noun}/рд,scene : Exit",
	"в|через|на {noun}/вн,scene,enterable : Enter",
	"?наружу : Exit" }

Verb { "#Exam",
	"[о| |по|рас]смотр/еть,[раз|по]гляд/еть",
	"?на {noun}/вн : Exam",
	" : Look",
	"инвентарь : Inv",
	"~ под {noun}/тв : LookUnder",
	"~ под {noun}/вн : LookUnder",
	"~ в|во|на {noun}/пр,2 : Search",
	"~ внутри {noun}/рд : Search",
	"~ в|во {noun}/вн : Search",
	"~ в|во {noun}/пр,2 ?о|?об|?обо|?про * : Consult",
	"~ ?о|?об|?обо|?про * в|во {noun}/пр,2 : Consult reverse",
}

Verb { "#Search",
	"[|по]искать,обыскать,[|по]ищ/и,обыщ/и,[|по]изуч/ать,[|по]исслед/овать",
	"{noun}/вн : Search",
	"в|во|на {noun}/пр,2 : Search",
	"под {noun}/тв : LookUnder",
	"~ в|во {noun}/пр,2 ?о|?об|?обо|?про * : Consult",
	"~ ?о|?об|?обо|?про * в|во {noun}/пр,2 : Consult reverse",
}

Verb { "#Open",
	"откр/ыть,распах/нуть,раскр/ыть,отвори/ть",
	"{noun}/вн : Open",
	"{noun}/вн {noun}/тв,held : Unlock",
	"~ {noun}/тв,held {noun}/вн : Unlock reverse",
}

Verb { "#Unlock",
	"отпереть,отопр/и",
	"{noun}/вн {noun}/тв,held : Unlock",
	"~ {noun}/тв,held {noun}/вн : Unlock reverse",
}

Verb { "#Close",
	"закры/ть,закро/й",
	"{noun}/вн : Close",
	"{noun}/вн {noun}/тв,held : Lock",
	"~ {noun}/вн на {noun}/вн,held : Lock",
	"~ {noun}/тв,held {noun}/вн : Lock reverse",
}

Verb { "#Lock",
	"запереть",
	"{noun}/вн {noun}/тв,held : Lock",
	"~ {noun}/вн на {noun}/вн,held : Lock",
	"~ {noun}/тв,held {noun}/вн : Lock reverse",
}

Verb { "#Inv",
	"инв/ентарь,с собой",
	"Inv" }

function mp.shortcut.pref4()
	return '[ |за|подо]'
end

function mp.shortcut.pref5()
	return '[ |за|под]'
end

Verb { "#Take",
	"взять,возьм/и,{#pref4}брать,{#pref5}бер/и,доста/ть,схват/ить,"..
	"украсть,украд/и,извле/чь,вын/уть,вытащ/ить",
	"{noun}/вн,scene : Take",
	"{noun}/вн,scene из|с|со|у {noun}/рд,inside,holder: Remove",
	"~ из|с|со|у {noun}/рд,inside,holder {noun}/вн,scene: Remove reverse",
}

Verb { "#Insert",
	"воткн/уть,втык/ать,вставить,влож/ить,"..
	"[|про|за]сун/уть,вставь/",
	"{noun}/вн,held в|во {noun}/вн,inside : Insert",
	"~ {noun}/вн,held внутрь {noun}/рд : Insert",
	"~ в|во {noun}/вн {noun}/вн : Insert reverse",
	"~ внутрь {noun}/рд {noun}/вн : Insert reverse",
}

Verb { "#Drop",
	"полож/ить,постав/ить,посади/ть,класть,клади/,помест/ить",
	"{noun}/вн,held : Drop",
	"{noun}/вн,held в|во {noun}/вн,inside : Insert",
	"~ {noun}/вн,held внутрь {noun}/рд : Insert",
	"{noun}/вн,held на {noun}/вн : PutOn",
	"~ в|во {noun}/вн {noun}/вн : Insert reverse",
	"~ внутрь {noun}/рд {noun}/вн : Insert reverse",
	"~ на {noun}/вн {noun}/вн : PutOn reverse",
}

Verb {
	"#ThrowAt",
	"брос/ить,выбро/сить,кину/ть,кинь/,кида/ть,швыр/нуть,метн/уть,метать",
	"{noun}/вн,held : Drop",
	"{noun}/вн,held в|во|на {noun}/вн : ThrowAt",
	"~ в|во|на {noun}/вн {noun}/вн : ThrowAt reverse",
	"~ {noun}/вн {noun}/дт : ThrowAt",
	"~ {noun}/дт {noun}/вн : ThrowAt reverse",

}

Verb {
	"#Wear",
	"наде/ть,оде/ть",
	"{noun}/вн,held : Wear",
}

Verb {
	"#Disrobe",
	"снять,сним/ать",
	"{noun}/вн,worn : Disrobe",
	"~ {noun}/вн с|со {noun}/рд : Remove",
	"~ с|со {noun}/рд {noun}/вн : Remove reverse"
}

Verb {
	"#SwitchOn",
	"включ/ить,вруб/ить,активи/ровать",
	"{noun}/вн : SwitchOn",
}

Verb {
	"#SwitchOff",
	"выключ/ить,выруб/ить,деактиви/ровать",
	"{noun}/вн : SwitchOff",
}

Verb {
	"#Eat",
	"есть,съе/сть,куша/ть,скуша/ть,сожр/ать,жри,жрать,ешь",
	"{noun}/вн,held : Eat",
}

Verb {
	"#Taste",
	"лизать,лизн/уть,попроб/овать,полиз/ать,сосать,пососа/ть",
	"{noun}/вн : Taste"
}

Verb {
	"#Drink",
	"пить,выпить,выпей,выпью,пью",
	"{noun}/вн,held : Drink",
}

function mp.shortcut.pref6()
	return 'с|по|пере|за'
end

Verb {
	"#Push",
	"толк/ать,пих/ать,нажим/ать,нажм/и,нажать,[{#pref6}]двин/уть,[|{#pref6}]двига/ть,"..
	"запих/нуть,затолк/ать,[|на]давить",
	"?на {noun}/вн : Push",
	"{noun}/вн на|в|во {noun}/вн : Transfer",
	"~ {noun}/вн к {noun}/дт : Transfer",
	"{noun}/вн {compass2} : Transfer",
	"~ на|в|во {noun}/вн {noun}/вн : Transfer reverse",
	"~ {compass2} {noun}/вн : Transfer reverse"
}

Verb {
	"#Pull",
	"[|вы|по]тян/уть,[|вы|по]тащ/ить,тягать,[|по]волоч/ь,[|по]волок/ти,дёрн/уть,дёрг/ать",
	"?за {noun}/вн : Pull",
	"{noun}/вн на|в|во {noun}/вн : Transfer",
	"~ {noun}/вн к {noun}/дт : Transfer",
	"{noun}/вн {compass2} : Transfer",
	"~ на|в|во {noun}/вн {noun}/вн : Transfer reverse",
	"~ {compass2} {noun}/вн : Transfer reverse"
}

Verb {
	"#Turn",
	"враща/ть,поверн/уть,[|за|по]верт/еть,[|за]крути/ть",
	"{noun}/вн : Turn"
}

Verb {
	"#Wait",
	"ждать,жди,подожд/ать,ожид/ать",
	"Wait"
}

function mp.shortcut.pref7()
	return 'за|по|про|пере|вы'
end

Verb {
	"#Rub",
	"[|{#pref7}]тереть,[|{#pref7}]три/,[{#pref7}]тира/ть,",
	"{noun}/вн : Rub"
}

Verb {
	"#Sing",
	"[|с]петь,спой/,пой",
	"Sing"
}

Verb {
	"#Touch",
	"[ |по]трога/ть,трон/уть,дотрон/уться,[ |при]косну/ться,касать/ся,[ |по|о]щупа/ть,[ |по]глад/ить",
	"{noun}/вн : Touch",
	"~ до {noun}/рд : Touch",
	"~ к {noun}/дт : Touch",
	"~ {noun}/рд : Touch",
}

Verb {
	"#Give",
	"дать,отда/ть,предло/жить,предла/гать,дам,даю,дадим",
	"{noun}/вн,held {noun}/дт,live : Give",
	"~ {noun}/дт,live {noun}/вн,held : Give reverse",
}

Verb {
	"#Show",
	"показ/ать,покаж/и",
	"{noun}/вн,held {noun}/дт,live : Show",
	"~ {noun}/дт,live {noun}/вн,held : Show reverse",
}

Verb {
	"#Burn",
	"[|под]жечь,жг/и,подожги/,поджиг/ай,зажг/и,зажиг/ай,зажечь",
	"{noun}/вн : Burn",
	"{noun}/вн {noun}/тв,held : Burn",
	"~ {noun}/тв,held {noun}/вн : Burn reverse",
}

Verb {
	"#Wake",
	"будить,разбуд/ить,просн/уться,бужу",
	"{noun}/вн,live : WakeOther",
	"Wake",
}

Verb {
	"#Kiss",
	"целовать,поцел/овать,чмок/нуть,обним/ать,обнять,целуй",
	"{noun}/вн,live : Kiss"
}

Verb {
	"#Think",
	"дума/ть,мысл/ить,подум/ать,рассужд/ать",
	"Think"
}

Verb {
	"#Smell",
	"нюха/ть,понюха/ть,занюх/ать,нюхн/уть,принюх/аться",
	"Smell",
	"{noun}/вн : Smell"
}

Verb {
	"#Listen",
	"слуша/ть,послуша/ть,прислушать/ся,слыш/ать,слух/",
	"Listen",
	"{noun}/вн : Listen",
	"~ к {noun}/дт : Listen",
}

Verb {
	"#Dig",
	"копа/ть,выкопа/ть,выры/ть,рыть,рой,вырой",
	"Dig",
	"{noun}/вн,scene : Dig",
	"{noun}/вн,scene {noun}/тв,held : Dig",
	"~ {noun}/тв,held {noun}/вн,scene : Dig reverse",
}

function mp.shortcut.pref8()
	return '[|раз|на|по|от|пере|вы]'
end

Verb {
	"#Cut",
	"{#pref8}рез/ать,{#pref8}реж/ь",
	"{noun}/вн : Cut",
	"{noun}/вн {noun}/тв,held: Cut",
	"~ {noun}/тв,held {noun}/вн: Cut reverse"
}

function mp.shortcut.pref9()
	return '[ |по|разо|со]'
end

Verb {
	"#Tear",
	"{#pref9}рвать,{#pref9}рви/,{#pref9}рву",
	"{noun}/вн : Tear",
}

Verb {
	"#Tie",
	"[при|с]вяз/ать,[при|с]вяж/и",
	"{noun}/вн : Tie",
	"{noun}/вн к {noun}/дт : Tie",
	"~ {noun}/вн с|со {noun}/тв : Tie",
	"~ к {noun}/дт {noun}/вн : Tie reverse",
	"~ с|со {noun}/тв {noun}/вн : Tie reverse",
}

Verb {
	"#Blow",
	"дуть,дуй/,дун/ь,задут/ь,задун/ь,задуй/",
	"в|во|на {noun}/вн : Blow",
	"~ {noun}/вн : Blow", -- задуть
}

Verb {
	"#Attack",
	"атак/овать,[|у|вы|раз|по|выши]бить,[|по|раз]бей/,удар/ить,"..
	"[|с|раз|по|вы|вз]лома/ть,разруш/ить,побь/,круш/ить,напасть,напад/ать,пнуть",
	"?на {noun}/вн : Attack"
}

Verb {
	"#Sleep",
	"спать,усн/уть,засн/уть,дрем/ать",
	"Sleep",
}

Verb {
	"#Swim",
	"плыть,плав/ать,ныря/ть,уплы/ть,поплы/ть,нырн/уть,[ |ис]купа/ться",
	"Swim",
}

Verb {
	"#Consult",
	"[|про|по]чита/ть,проч/есть",
	"в|во {noun}/пр,2 о|об|обо|про * : Consult",
	"~ о|об|обо|про * в|во {noun}/пр,2 : Consult reverse",
	"~ {noun}/вн : Exam",
}

Verb {
	"#Fill",
	"наполн/ить,нали/ть",
	"?в {noun}/вн : Fill",
	"~ внутрь {noun}/рд : Fill"
}

Verb {
	"#Jump",
	"[|по]прыг/ать,скак/ать,[|пере|под]прыг/нуть,переско/чить",
	"Jump",
	"через {noun}/вн,scene : JumpOver",
	"~ в {noun}/вн,scene : Enter",
	"~ на {noun}/вн,scene : Climb",
	"~ с|со {noun}/рд,scene : GetOff",
	"~ {compass2} : Walk",
	"~ +через {noun}/вн,scene : JumpOver",
}

Verb {
	"#Wave",
	"[|по]мах/ать,взмахн/уть,помаш/и",
	"WaveHands",
	"~ руками : WaveHands",
	"{noun}/тв,held : Wave"
}

Verb {
	"#Climb",
	"[|за|по|про|в]лез/ть,карабк/аться,взбир/ться,взобраться,взбери/сь",
	"на {noun}/вн,scene : Climb",
	"по {noun}/дт,scene : Climb",
	"~ внутрь {noun}/рд,scene : Enter",
	"~ в|во {noun}/вн,scene : Enter",
	"{compass2}: Walk",
}

Verb {
	"#GetOff",
	"слез/ть,спусти/ться,встать,встан/ь",
	"GetOff",
	"{compass2}: Walk",
	"с|со {noun}/рд,scene : GetOff",
}

Verb {
	"#Buy",
	"купи/ть,покупать",
	"{noun}/вн,scene : Buy"
}

Verb {
	"#Talk",
	"[|по]говор/ить,[|по]бесед/овать,разговарива/ть",
	"с|со {noun}/тв,live : Talk"

}

Verb {
	"#Tell",
	"сказать,сообщи/ть,сообщу,рассказать,расскаж/ите",
	"{noun}/дт,live о|об|обо|про * : Tell",
	"~ * {noun}/дт,live : Tell reverse",
	"~ {noun}/дт * : Tell"
}

Verb {
	"#Ask",
	"спросит/ь,расспросит/ь",
	"{noun}/вн,live о|об|обо|про * : Ask",
	"~ у {noun}/рд,live о|об|обо|про * : Ask",
	"~ о|об|обо|про * у {noun}/рд,live : Ask reverse",
}

Verb {
	"#AskFor",
	"попроси/ть,выпроси/ть,уговори/ть,проси/ть,попрош/у,выпрош/у",
	"у {noun}/рд,live * : AskFor",
	"* у {noun}/рд,live : AskFor reverse",
	"~ {noun}/вн,live * : AskTo",
}

Verb {
	"#Answer",
	"ответ/ить,отвеч/ать",
	"{noun}/дт,live * : Answer",
	"~ * {noun}/дт,live : Answer reverse",
}

Verb {
	"#Yes",
	"да",
	"Yes",
}

Verb {
	"#No",
	"нет",
	"No",
}

Verb {
    "~ использ/овать,воспольз/оваться",
    "{noun}/вн : Use",
    "{noun}/тв : Use",
}

if DEBUG then

function mp:MetaForm(w)
	if not w then return end
	local t, hint
	w = w:gsub("_", "/")
	if w:find "/" then
		hint = true
	end
	for _, f in ipairs { "им", "рд", "дт", "вн", "тв", "пр", "пр,2" } do
		local ww = w
		if hint then
			ww = ww .. ','.. f
		else
			ww = ww .. '/' .. f
		end
		t = self.mrd:word(ww)
		pn(t, " (", f, ")")
	end
end

	MetaVerb {
		"#MetaWord",
		"~_слово",
		"* : MetaWord"
	}
	MetaVerb {
		"#MetaNoun",
		"~_сущ/ествительное",
		"* : MetaNoun"
	}
	MetaVerb {
		"#MetaTrace",
		"~_трассировка",
		"да : MetaTraceOn",
		"нет : MetaTraceOff",
	}
	MetaVerb {
		"#MetaDump",
		"~_дамп",
		"MetaDump"
	}
	MetaVerb {
		"#МетаForm",
		"~_форм/ы",
		"* :MetaForm"
	}
end
mp.msg.MetaTranscript.ON = function(file)
	p ("Запись транскрипта началась: ", file)
end

mp.msg.MetaTranscript.OFF = function(file)
	p ("Транскрипт остановлен: ", file)
end

mp.msg.MetaTranscript.FILE = function(file)
	p ("Файл транскрипта: ", file)
end

MetaVerb {
	"#MetaTranscript",
	"~транскрипт",
	"да : MetaTranscriptOn",
	"нет : MetaTranscriptOff",
	"MetaTranscript",
}

MetaVerb {
	"#MetaExpert",
	"~парсер",
	"эксперт да : MetaExpertOn",
	"эксперт нет : MetaExpertOff",
	"глаголы : MetaVerbs",
	"версия : MetaVersion",
}

MetaVerb {
	"#MetaSave",
	"~сохрани/ть",
	"MetaSave"
}
MetaVerb {
	"#MetaLoad",
	"~загрузи/ть",
	"MetaLoad"
}

if DEBUG then
MetaVerb {
	"#MetaAutoplay",
	"~автоскрипт",
	"MetaAutoplay"
}
end

mp.msg.MetaRestart.RESTART = "Начать заново?";

MetaVerb {
	"#MetaRestart",
	"~заново,~рестарт",
	"MetaRestart"
}
MetaVerb {
	"#MetaHelp",
	"~помощь,помоги/те",
	"MetaHelp",
}
end, 1)

std.mod_start(function()
	if mp.undo > 0 then
		mp.msg.MetaUndo.EMPTY = "Отменять нечего."
		MetaVerb {
			"#MetaUndo",
			"~отмен/а",
			"MetaUndo",
		}
	end
	if mp.score then
		MetaVerb {
			"~ счёт",
			"MetaScore",
		}
	end
end)
-- Dialog
std.phr.default_Event = "Exam"

Verb ({"~ сказать", "{select} : Exam" }, std.dlg)
Verb ({'#Next', "дальше", "Next" }, mp.cutscene)
Verb ({'#Exam', "~ осмотреть", "Look" }, std.dlg)

mp.cutscene.default_Verb = "дальше"
mp.cutscene.help = fmt.em "<дальше>";

std.dlg.default_Verb = "осмотреть"
std.player.word = -"ты/мр,2л"
