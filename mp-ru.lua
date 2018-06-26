local lang = require "morph/lang-ru"
loadmod "mp"
loadmod "mplib"
local mp = _'@metaparser'
mp.mrd.lang = lang

std.mod_init(
	function()
	mp:init()
end)
game.dsc = function()
	p ([[METAPARSER3 Версия: ]]..mp.version.."^")
	p [[http://instead-hub.github.io^^
Если вам необходима справка по игре, наберите "помощь".
^]]
end
local utf = mp.utf

_'@compass'.out_to_dir = 11

_'@compass'.word = function()
	local dir = -"север,с|северо-восток,св|восток,в|юго-восток,юв|юг,ю|юго-запад,юз|запад,з|северо-запад,сз"
	local up = -"наверх,вверх,верх|вниз,низ|наружу,выход,назад|внутрь,вход"
	local inp, pre = mp:compl_ctx()
	if pre == '' then
		return dir .. '|'.. up
	end
	if pre == 'на ' or inp:find("на[ ]*$") then
		return dir
	end
	return up
end
_'@darkness'.word = -"тьма,темнота,темень"
_'@darkness'.before_Any = "Полная, кромешная тьма."
_'@darkness':attr 'persist'

_'@compass'.dirs = { 'n_to', 'ne_to', 'e_to', 'se_to', 's_to', 'sw_to', 'w_to', 'nw_to', 'u_to', 'd_to','out_to','in_to' };
_'@compass'.before_Default = 'Попробуйте глагол "идти".'

mp.door.word = -"дверь";
mp.msg.WHEN_DARK = "Кромешная тьма."
mp.msg.UNKNOWN_THEDARK = "Возможно, это потому что в темноте ничего не видно?"
mp.msg.COMPASS_NOWAY = "Этот путь недоступен."
mp.msg.COMPASS_EXAM_NO = "В этом направлении не видно ничего примечательного."
mp.msg.ENUM = "шт."
mp.msg.CUTSCENE_HELP = "Для продолжения нажмите <ввод> или введите {$fmt em|дальше}."
mp.msg.TAKE_BEFORE = function(w)
	pn (iface:em("(сначала взяв "..w:noun'вн'..")"))
end
mp.msg.DISROBE_BEFORE = function(w)
	pn (iface:em("(сначала сняв "..w:noun'вн'..")"))
end

--"находиться"
mp.msg.SCENE = "{#Me} {#word/находиться,#me,нст} {#if_has/#here,supporter,на,в} {#here/пр,2}.";
mp.msg.INSIDE_SCENE = "{#Me} {#word/находиться,#me,нст} {#if_has/#where,supporter,на,в} {#where/пр,2}.";
mp.msg.TITLE_INSIDE = "({#if_has/#where,supporter,на,в} {#where/пр,2})";

mp.msg.COMPASS_EXAM = function(dir, ob)
	if dir == 'u_to' then
		p "Вверху"
	elseif dir == 'd_to' then
		p "Внизу"
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
mp.msg.UNKNOWN_VERB = "Непонятный глагол"
mp.msg.UNKNOWN_VERB_HINT = "Возможно, вы имели в виду"
mp.msg.INCOMPLETE = "Нужно дополнить предложение."
mp.msg.UNKNOWN_OBJ = "Такого предмета тут нет"
mp.msg.UNKNOWN_WORD = "Слово не распознано"
mp.msg.HINT_WORDS = "Возможно, вы имели в виду"
mp.msg.HINT_OR = "или"
mp.msg.HINT_AND = "и"
mp.msg.AND = "и"
mp.msg.MULTIPLE = "Тут есть"
mp.msg.LIVE_ACTION = "{#Firstit/дт} это не понравится."
mp.msg.NOTINV = function(t)
	p (lang.cap(t:noun'вн') .. " сначала нужно взять.")
end
--"надет"
mp.msg.WORN = function(w)
	local hint = w:gram().hint
	pr (" (",mp.mrd:word('надет/' .. hint), ")")
end
--"открыт"
mp.msg.OPEN = function(w)
	local hint = w:gram().hint
	pr (" (",mp.mrd:word('открыт/' .. hint), ")")
end
mp.msg.EXITBEFORE = "Возможно, {#me/дт} нужно сначала {#if_has/#where,supporter,слезть с,вылезти из} {#where/рд}."

mp.default_Event = "Exam"
mp.default_Verb = "осмотреть"

--"доступен"
mp.msg.ACCESS1 = "{#First} отсюда не{#word/доступен,#first}."
mp.msg.ACCESS2 = "{#Second} отсюда не{#word/доступен,#second}."

mp.msg.Look.HEREIS = "Здесь есть"
mp.msg.Look.HEREARE = "Здесь есть"
mp.msg.Look.SUPPORTER = function(o)
	p ("На ",o:noun'пр,2')
end
mp.msg.NOROOM = function(w)
	if w == std.me() then
		p ("У {#me/вн} слишком много вещей.")
	elseif w:has'supporter' then
		p ("На ", w:noun'пр,2', " больше нет места.")
	else
		p ("В ", w:noun'пр,2', " больше нет места.")
	end
end
--"включён"
--"выключен"
mp.msg.Exam.SWITCHSTATE = "{#First} сейчас {#if_has/#first,on,{#word/включён,#first},{#word/выключен,#first}}."
mp.msg.Exam.NOTHING = "ничего нет."
mp.msg.Exam.IS = "находится"
mp.msg.Exam.ARE = "находятся"
mp.msg.Exam.IN = "В {#first/пр,2}"
mp.msg.Exam.ON = "На {#first/пр,2}"
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

mp.msg.Enter.EXITBEFORE = "Сначала нужно {#if_has/#where,supporter,слезть с {#where/рд}.,покинуть {#where/вн}.}"

mp.msg.Exit.NOTHERE = "Но {#me} сейчас не {#if_has/#first,supporter,на,в} {#first/пр,2}."
mp.msg.Exit.NOWHERE = "Но {#me/дт} некуда выходить."
mp.msg.Exit.CLOSED = "Но {#first} {#word/закрыт,#first}."


--"покидать"
--"слезать"
mp.msg.Exit.EXITED = "{#Me} {#if_has/#first,supporter,{#word/слезать с,#me,нст} {#first/рд},{#word/покидать,#me,нст} {#first/вн}}."

mp.msg.Inv.NOTHING = "У {#me/рд} с собой ничего нет."
mp.msg.Inv.INV = "У {#me/рд} с собой"

--"открывать"
mp.msg.Open.OPEN = "{#Me} {#word/открывать,нст,#me} {#first/вн}."
mp.msg.Open.NOTOPENABLE = "{#First/вн} невозможно открыть."
--"открыт"
mp.msg.Open.WHENOPEN = "{#First/вн} уже {#word/открыт,#first}."
--"заперт"
mp.msg.Open.WHENLOCKED = "Похоже, что {#first/} {#word/заперт,#first}."

--"закрывать"
mp.msg.Close.CLOSE = "{#Me} {#word/закрывать,нст,#me} {#first/вн}."
mp.msg.Close.NOTOPENABLE = "{#First/вн} невозможно закрыть."
--"закрыт"
mp.msg.Close.WHENCLOSED = "{#First/вн} уже {#word/закрыт,#first}."

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
mp.msg.Take.WHERE = "Нельзя взять то, в/на чём {#me} {#word/находиться,#me}."

mp.msg.Take.LIFE = "{#First/дт} это вряд ли понравится."
--"закреплён"
mp.msg.Take.STATIC = "{#First} жестко {#word/закреплён,#first}."
mp.msg.Take.SCENERY = "{#First/вн} невозможно взять."
mp.msg.Take.PARTOF = "{#First} является частью {#firstwhere/рд}."

mp.msg.Remove.WHERE = "{#First} не находится {#if_has/#second,supporter,на,в} {#second/пр,2}."
mp.msg.Remove.REMOVE = "{#First} {#if_has/#second,supporter,поднят,извлечён из} {#second/рд}."

mp.msg.Drop.SELF = "У {#me/рд} не хватит ловкости."
mp.msg.Drop.WORN = "{#First/вн} сначала нужно снять."
--"помещать"
mp.msg.Insert.INSERT = "{#Me} {#word/помещать,нст,#me} {#first/вн} в {#second/вн}."
mp.msg.Insert.CLOSED = "{#Second} {#word/закрыт,#second}."
mp.msg.Insert.NOTCONTAINER = "{#Second} не {#if_hint/#second,plural,могут,может} что-либо содержать."
mp.msg.Insert.WHERE = "Нельзя поместить {#first/вн} внутрь себя."
mp.msg.Insert.ALREADY = "Но {#first} уже и так {#word/находиться,#first} там."
mp.msg.PutOn.NOTSUPPORTER = "Класть что-либо на {#second} бессмысленно."
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
--"съедать"
mp.msg.Eat.EAT = "{#Me} {#word/съедать,нст,#me} {#first/вн}."
mp.msg.Drink.IMPOSSIBLE = "Выпить {#first/вн} невозможно."

mp.msg.Push.STATIC = "{#First/вн} трудно сдвинуть с места."
mp.msg.Push.SCENERY = "{#First/вн} двигать невозможно."
mp.msg.Push.PUSH = "Ничего не произошло."

mp.msg.Pull.STATIC = "{#First/вн} трудно сдвинуть с места."
mp.msg.Pull.SCENERY = "{#First/вн} двигать невозможно."
mp.msg.Pull.PUSH = "Ничего не произошло."

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
--"продаваться"
mp.msg.Buy.BUY = "{#First} не {#word/продаваться,нст,#first}."
mp.hint.live = 'од'
mp.hint.nonlive = 'но'
mp.hint.neuter = 'ср'
mp.hint.male = 'мр'
mp.hint.female = 'жр'
mp.hint.plural = 'мн'
mp.hint.first = '1л'
mp.hint.second = '2л'
mp.hint.third = '3л'

mp.keyboard_space = '<пробел>'
mp.keyboard_backspace = '<удалить>'

mp.msg.verbs.take = -"брать,#me,нст"

local function dict(t, hint)
	local g = std.split(hint, ",")
	for _, v in ipairs(g) do
		if t[v] then
			return t[v]
		end
	end
end

function mp:myself(w, hint)
	local ww = dict({
			["вн"] = "себя";
			["дт"] = "себе";
			["тв"] = "собой";
			["пр"] = "себе";
			["рд"] = "себя";
		 }, hint)
	return { ww }
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
	local t = self:it(w, hint)
	local w = { t }
	if t == 'его' or t == 'её' or t == 'ее' or t == 'ей' or t == 'им' then t = 'н'..t; w[2] = t end
	return w
end

mp.keyboard = {
	'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й',
	'К','Л','М','Н','О','П','Р','О','С','Т','У','Ф',
	'Х','Ц','Ч','Ш','Щ','Ь','Ы','Ъ','Э','Ю','Я'
}

local function hints(w)
	local h = std.split(w, ",")
	local hints = {}
	for _, v in ipairs(h) do
		hints[v] = true
	end
	return hints
end

function mp:err_noun(noun)
	local hint = std.split(noun, "/")
	p "{$fmt em|существительное в"
	if #hint == 2 then
		local h = hints(hint[2])
		local acc = 'именительном'
		if h["им"] then
			acc = 'именительном'
		elseif h["рд"] then
			acc = 'родительном'
		elseif h["дт"] then
			acc = 'дательном'
		elseif h["вн"] then
			acc = 'винительном'
		elseif h["тв"] then
			acc = 'творительном'
		elseif h["пр"] or h["пр2"] then
			acc = 'предложном'
		end
		pr (acc, " падеже")
	else
		pr "именительном падеже"
	end
	pr "}"
end

function mp.shortcut.vo(hint)
	return "в ".. hint
--	local w = std.split(hint)
--	w = w[#w]
--	if mp.utf.len(w) > 2 and
--		(lang.is_vowel(utf.char(w, 1)) or
--		lang.is_vowel(utf.char(w, 2))) then
--		return "в ".. hint
--	end
--	return "во ".. hint
end

function mp.shortcut.so(hint)
	return "с ".. hint
--	local w = std.split(hint)
--	w = w[#w]
--	if mp.utf.len(w) > 2 and
--		(lang.is_vowel(utf.char(w, 1)) or
--		lang.is_vowel(utf.char(w, 2))) then
--		return "с ".. hint
--	end
--	return "со ".. hint
end

function mp:before_Enter(w)
	if w ^ '@compass' then
		mp:xaction("Walk", w)
		return
	end
	return false
end

function mp:MetaHelp()

	pn("{$fmt b|КАК ИГРАТЬ?}")

	pn([[Вводите ваши действия в виде простых предложений вида: глагол -- существительное. Например:^
> открыть дверь^
> отпереть дверь ключом^
> идти на север^
> взять кепку^
^
Чтобы осмотреть предмет, введите "осмотреть книгу" или просто "книга".^
^
Чтобы осмотреть всю сцену, наберите "осмотреть" или нажмите "ввод".^
^
Для того чтобы узнать, что вы носите с собой, наберите "инвентарь".^
^
Для перемещений используйте стороны света, например: "идти на север" или "север" или просто "с".
^^
Вы можете воспользоваться клавишой "TAB" для автодополнения ввода.
]])
end

Verb { "#Walk",
	"идти,иду,пойти,пойд/и,подой/ти,иди,войти,войд/и,зайти,зайд/и,бежать,бег/и,влез/ть,ехать,поехать,едь,поеду,сесть,сядь,сяду,лечь,ляг,вста/ть",
	"на|в|во {noun}/вн,scene,enterable : Enter",
	"к {noun}/дт,scene : Walk",
	"{noun_obj}/@compass : Walk" }

Verb { "#Exit",
	"выйти,выйд/и,уйти,уйд/и,вылез/ти,выхо/ди,обратно,назад,выбраться,выберись,выберусь,выбираться",
	"из|с|со {noun}/рд,scene : Exit",
	"?наружу : Exit" }

Verb { "#Exam",
       "осм/отреть,смотр/еть,рассмотр/еть,посмотр/еть,гляд/еть,разгляд/еть,погляд/еть",
       "?на {noun}/вн : Exam",
       "?всё : Look",
       "~ под {noun}/тв : LookUnder",
       "~ под {noun}/вн : LookUnder",
       "~ в|во|на {noun}/пр,2 : Search",
       "~ внутри {noun}/рд : Search",
       "~ в|во {noun}/пр,2 о|об|обо|про * : Consult",
       "~ о|об|обо|про * в|во {noun}/пр,2 : Consult reverse",
}

Verb { "#Search",
       "иск/ать,обыскать,ищ/и,обыщ/и,изуч/ать,исслед/овать",
       "{noun}/вн : Search",
       "в|во|на {noun}/пр,2 : Search",
       "под {noun}/тв : LookUnder",
       "~ в|во {noun}/пр,2 * : Consult",
       "~ * в|во {noun}/пр,2 : Consult reverse",
}

Verb { "#Open",
	"откр/ыть,распах/нуть,раскр/ыть,отпереть,отопр/и",
	"{noun}/вн : Open",
	"{noun}/вн {noun}/тв : Unlock",
	"~ {noun}/тв {noun}/вн : Unlock reverse",
}

Verb { "#Close",
	"закр/ыть,запереть",
	"{noun}/вн : Close",
	"{noun}/вн {noun}/тв : Lock",
	"~ {noun}/тв {noun}/вн : Lock reverse",
}

Verb { "#Inv",
       "инв/ентарь,с собой",
       "Inv" }

Verb { "#Take",
       "взять,возьм/и,брать,забрать,забер/и,бери/,доста/ть,схват/ить,укра/сть,извле/чь,вын/уть,вытащ/ить",
       "{noun}/вн,scene : Take",
       "{noun}/вн из|с|со|у {noun}/рд,inside: Remove",
       "~ из|с|со|у {noun}/рд,container {noun}/вн: Remove reverse",
}

Verb { "#Drop",
       "полож/ить,постав/ить,посади/ть,класть,клади/,вставь/,помест/ить,сун/уть,засун/уть,воткн/уть,втык/ать,встав/ить,влож/ить",
       "{noun}/вн,held : Drop",
       "{noun}/вн,held в|во {noun}/вн,inside : Insert",
       "~ {noun}/вн,held внутрь {noun}/рд : Insert",
       "{noun}/вн,held на {noun}/вн : PutOn",
       "~ в|во {noun}/вн {noun}/вн : Insert reverse",
       "~ внутрь {noun}/рд {noun}/вн : Insert reverse",
       "~ на {noun}/вн {noun}/вн : PutOn reverse",
}

Verb {
	"#Throw",
	"брос/ить,выбро/сить,кин/уть,кида/ть,швыр/нуть,метн/уть,метать",
	"{noun}/вн,held : Drop",
	"{noun}/вн,held в|во|на {noun}/вн : ThrowAt",
	"~ в|во|на {noun}/вн {noun}/вн : ThrowAt reverse",
	"~ {noun}/вн {noun}/дт : ThrowAt",
	"~ {noun}/дт {noun}/вн : ThrowAt reverse",

}

Verb {
	"#Wear",
	"наде/ть,оде/ть,облачи/ться",
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
	"#Drink",
	"пить,выпить,выпей,выпью,пью",
	"{noun}/вн,held : Drink",
}

Verb {
	"#Push",
	"толк/ать,пих/ать,нажим/ать,нажм/и,нажать,сдвин/уть,двига/ть,задви/нуть,запих/нуть,затолк/ать",
	"?на {noun}/вн : Push",
	"{noun}/вн на|в|во {noun}/вн : Transfer",
	"{noun}/вн {noun_obj}/@compass : Transfer",
	"~ на|в|во {noun}/вн {noun}/вн : Transfer reverse",
	"~ {noun_obj}/@compass {noun}/вн : Transfer reverse"
}

Verb {
	"#Pull",
	"тян/уть,тащ/ить,тягать,волоч/ь,волок/ти,дёрн/уть,дёрг/ать,потян/уть,потащ/ить,поволо/чь",
	"?за {noun}/вн : Pull",
	"{noun}/вн на|в|во {noun}/вн : Transfer",
	"{noun}/вн {noun_obj}/@compass : Transfer",
	"~ на|в|во {noun}/вн {noun}/вн : Transfer reverse",
	"~ {noun_obj}/@compass {noun}/вн : Transfer reverse"
}

Verb {
	"#Turn",
	"враща/ть,поверн/уть,верт/есть,поверт/еть",
	"{noun}/вн : Turn"
}

Verb {
	"#Wait",
	"ждать,жди,жду,подожд/ать,ожид/ать",
	"Wait"
}

Verb {
	"#Rub",
	"тереть,потр/и,потереть,тру,три",
	"{noun}/вн : Rub"
}

Verb {
	"#Sing",
	"петь,спеть,спою,спой/,пой",
	"Sing"
}

Verb {
	"#Touch",
	"трога/ть,потрог/ать,трон/уть,косну/ться,касать/ся,прикосн/уться,щупа/ть,пощупа/ть,глад/ить,поглад/ить",
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
	"жечь,жг/и,поджечь,подожги/,поджиг/ай,зажг/и,зажиг/ай,зажечь",
	"{noun}/вн : Burn",
	"{noun}/вн {noun}/тв,held : Burn",
	"~ {noun}/тв,held {noun}/вн reverse",
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

Verb {
	"#Cut",
	"рез/ать,реж/ь,разрез/ать,разреж/ь,рвать,порв/ать,рви/",
	"{noun}/вн : Cut",
	"{noun}/вн {noun}/тв,held: Cut",
	"~ {noun}/тв,held {noun}/вн: Cut reverse"
}

Verb {
	"#Tie",
	"привяз/ать,привяж/и,связ/ать,свяж/и",
	"{noun}/вн : Tie",
	"{noun}/вн к {noun}/дт : Tie",
	"~ {noun}/вн с|со {noun}/тв : Tie",
	"~ к {noun}/дт {noun}/вн : Tie reverse",
	"~ с|со {noun}/тв {noun}/вн : Tie reverse",
}

Verb {
	"#Blow",
	"дуть,дуй/,дун/ь,задут/ь,задун/ь,задую,задуй/",
	"в|во|на {noun}/вн : Blow",
	"~ {noun}/вн : Blow", -- задуть
}

Verb {
	"#Attack",
	"атак/овать,бить,бей/,удар/ить,лома/ть,слома/ть,уби/ть,разруш/ить,руш/ить,поби/ть,побей/,побь/,круш/ить,полома/ть,напасть,напад/ать",
	"?на {noun}/вн : Attack"
}

Verb {
	"#Sleep",
	"спать,усн/уть,засн/уть,дрем/ать",
	"Sleep",
}

Verb {
	"#Swim",
	"плыть,плав/ать,ныря/ть,уплы/ть,поплы/ть,нырн/уть",
	"Swim",
}

Verb {
	"#Consult",
	"чита/ть,прочита/ть,почита/й,проч/есть",
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
	"прыг/ать,скак/ать,перепрыг/нуть,переска/чить,попрыг/ать",
	"Jump",
	"через {noun}/вн,scene : JumpOver",
	"~ {noun}/вн,scene : JumpOver",
}

Verb {
	"#Wave",
	"мах/ать,помах/ать,помаш/и",
	"WaveHands",
	"~ руками : WaveHands",
	"{noun}/тв,held : Wave"
}

Verb {
	"#Climb",
	"лез/ть,залез/ть,полез/ть,влез/ть,карабк/аться,взбир/ться,взобраться,взбери/сь",
	"на {noun}/вн,scene : Climb",
	"по {noun}/дт,scene : Climb",
	"~ в|во {noun}/вн,scene : Enter",
}

Verb {
	"#GetOff",
	"слез/ть,спусти/ться",
	"Exit",
	"с|со {noun}/рд,scene : GetOff",
}

Verb {
	"#Buy",
	"купи/ть,покупать",
	"{noun}/вн,scene : Buy"
}

Verb {
	"#Talk",
	"говор/ить,поговор/ить,бесед/овать,побесед/овать,разговарива/ть",
	"с|со {noun}/тв,live : Talk"

}

Verb {
	"#Tell",
	"сказать,сообщ/ить,рассказать,расскаж/ите",
	"{noun}/дт,live о|об|обо|про * : Tell",
	"~ * {noun}/дт,live : Tell reverse",
	"~ {noun}/дт * : AskTo",
}

Verb {
	"#Ask",
	"спросит/ь,расспросит/ь",
	"?у {noun}/вн,live о|об|обо|про * : Ask",
	"~ о|об|обо|про * ?у {noun}/вн,live : Ask reverse",
}

Verb {
	"#AskFor",
	"попроси/ть,выпроси/ть,уговори/ть,проси/ть,попрош/у,выпрош/у",
	"у {noun}/вн,live * : AskFor",
	"~ * у {noun}/вн,live : AskFor reverse",
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

if DEBUG then
	Verb {
		"#MetaWord",
		"~_слово",
		"* : MetaWord"
	}
	Verb {
		"#MetaNoun",
		"~_сущ/ествительное",
		"* : MetaNoun"
	}
	Verb {
		"#MetaTrace",
		"~_трассировка",
		"да : MetaTraceOn",
		"нет : MetaTraceOff",
	}
end
Verb {
	"#MetaTranscript",
	"~транскрипт",
	"да : TranscriptOn",
	"нет : TranscriptOff",
	"Transcript",
}

Verb {
	"#MetaSave",
	"~сохрани/ть",
	"MetaSave"
}
Verb {
	"#MetaLoad",
	"~загрузи/ть",
	"MetaLoad"
}
Verb {
	"#MetaHelp",
	"~помощь,помоги/те",
	"MetaHelp",
}
-- Dialog
std.phr.default_Event = "Exam"

Verb ({"~ сказать", "{select} : Exam" }, std.dlg)
Verb ({'#Next', "дальше", "Next" }, mp.cutscene)
mp.cutscene.default_Verb = "дальше"
parser = mp

cutscene = mp.cutscene
function content(...)
	return mp:content(...)
end
std.player.word = -"ты/мр,2л"
