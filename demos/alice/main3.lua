--$Name:СКВОЗЬ ЗЕРКАЛО$

require "mp-ru"
require "fmt"

game.dsc = [[^Маленькая интерактивная Информ-обучалка^
	 (написанная Гаретом Ризом и переведенная Денисом Гаевым)^
Перенесена на МЕТАПАРСЕР3 Петром Косых
^^Хотя за окном стоит холодный зимний день,
за зеркалом над каминной полкой почему-то еще продолжается лето!^
Так хочется оказаться там!^
Ну неужели не существует никакого способа попасть ЗА зеркало?]];

const 'HELD_STATE' (0)     -- (у Алисы в руках)
const 'QUEEN_STATE' (1)    -- (играет с Черной Королевой)
const 'WOOL_STATE' (2)     -- (играет с клубком шерсти)
const 'CHAIR_STATE' (3)    -- (на пути к стулу)

function init()
	pl.room = 'Drawing_Room'
	pl.word = -"ты/жр,2л"
	DaemonStart 'white_kitten'
	DaemonStart 'black_kitten'
end

function mp:Untangle()
	p "Что, распутать ЭТО?!"
end

--"настоящий"
function mp:Reflect(w, wh)
	if not wh ^ 'mirror' then
		p "Сюрреализму этой идеи позавидовал бы и сам Льюис Кэрролл!";
		return
	end

	if w ^ 'hearth' or w ^ 'mirror' or
		(not pl:where() ^ 'mantelpiece' and not pl:where() ^ 'armchair') then
		p "Но Алисе вряд ли удастся поднести это к зеркалу!";
		return
	end

	p "Отражение ";
	if w == pl then  p "Алисы"
	else w:noun 'рд' end
	p " в зеркале выглядит ";
	if pl:where() ^ 'mantelpiece' then p "слишком уж расплывчатым и размытым." return end
	p "точь-в-точь как {#word/настоящий,#first}"
	if w == pl then p "Алиса"
	else p (w:noun()) end;
	p " -- только левая и правая сторона поменялись местами!";
end

room {
	-"гостиная|снег|снежинки";
	nam = 'Drawing_Room';
	title = "Гостиная";
        dsc = [[Там, за оконной рамой, беззвучно парят снежинки и властвует холод.
Алиса так рада, что она внутри, в тепле и уюте!
Гостиная отражается в большом зеркале, висящем на стене
над каминной полкой. И гостиная, и ее отражение в зеркале одинаково уютные --
с жарко пылающим камином, мягким ковриком перед ним,
и глубоким удобным креслом, в котором можно свернуться
клубочком и немного подремать.]];
	['before_Exit,Walk'] = function(s, w)
		if not pl:where() ^ 'mantelpiece' then
			return false
		end
		if mp:compass_dir(w) == 'd_to' or
			mp:compass_dir(w) == 'out_to' or
			w == s then
			p "Таким путем вряд ли удастся спуститься с каминной полки!";
			return
		end
		return false
	end;
	['before_Examine,Search,Enter,ThrowAt,ThrownAt,Reflect,Touch'] = function(s, w, wh)
		return false
	end;
	before_Default = function(s, ev, w, wh)
		if not pl:where() ^ 'mantelpiece' then
			return false
		end
		if w and not inside(w, 'mantelpiece') then
			p "Отсюда трудно дотянуться до "
			p (w:noun'рд', ".")
			return
		end
		if wh and not inside(wh, 'mantelpiece') then
			p "Отсюда трудно дотянуться до "
			p (w:noun'рд', ".")
			return
		end
		return false
        end;
}

obj {
	-"Чёрная Королева,королева/жр|ферзь";
	nam = 'red_queen';
	dsc = function(s)
		if _'white_kitten'.state == QUEEN_STATE or
		_'black_kitten'.state == QUEEN_STATE then
			return
		end
		return false
	end;
        description = "Маленькая (но какая своенравная!) шахматная фигурка.";
        after_Take = function()
		if _'white_kitten'.state == QUEEN_STATE then
			_'white_kitten'.state = CHAIR_STATE
		end
		if _'black_kitten'.state == QUEEN_STATE then
			_'black_kitten'.state = CHAIR_STATE
		end
		return false
	end;
        ['after_PutOn,Transfer,Insert'] = function(s, w)
		if w ^ 'chess_board' then
			p [[В гордом одиночестве на шахматной доске, Черная Королева --
                 самодержавная повелительница 32 белых и 32 черных клеток.]]
			return
		end
		return false
        end;
}: attr '~animate'

obj {
	-"шахматная доска,доска";
	nam = 'chess_board';
	found_in = 'Drawing_Room';
        init_dsc = "На полу лежит раскрытая шахматная доска.";
        description =  [[На полу лежала раскрытая шахматная доска с недоигранной партией. Но ни одной фигурки на ней уже не осталось -- котята играют с ними в менее интеллектуальные игры.]];
} :attr 'supporter';

obj {
	-"камин,огонь|пламя|решетка";
	nam = 'hearth';
	found_in = 'Drawing_Room';
	description = "За бронзовой каминной решеткой весело потрескивает огонь.";
} :attr'scenery' :dict {
	["огонь/вн"] = "огонь" -- огнь :)
}

obj {
	-"каминный коврик|коврик,ковер";
	nam = 'rug';
	founded = false;
	found_in = 'Drawing_Room';
	description = function()
		p [[Красивый каминный коврик из какой-то далекой страны -- может быть, Индии или Аравии.]];
		return false;
	end;
	before_Take = "Но коврик слишком большой и тяжелый!";
	['before_Push,Pull'] = "Но место каминного коврика -- рядом с камином!";
	before_LookUnder = function(s)
		if pl:where() ^ 'mantelpiece' or pl:where() ^ 'armchair' then
			p "Отсюда вряд ли возможно дотянуться до коврика!";
			return
		end
		if pl:where() == s then
			p [[Алиса попыталась приподнять угол коврика, но потерпела неудачу.
Причиной оказалось то, что она стояла прямо на нем.
Мм-да, мир полон неожиданностей.]];
			return
		end
		if not s.founded then
			s.founded = true
			move('red_queen', pl)
			p [[Алиса приподняла угол коврика -- и, заглянув под него,
обнаружила там Черную Королеву из шахматного набора!]];
			return
		end
		return false
	end
}: attr 'concealed,static,supporter,enterable'

obj {
	-"кресло|стул";
	nam = 'armchair';
	found_in = 'Drawing_Room';
	moved = false;
        description = function(s)
		p [[Большое глубокое кресло. Отличное место для котенка
или маленькой девочки, где можно устроиться поудобнее и подремать.
Сейчас оно стоит рядом с ]];
		if s.moved then
			p "камином."
		else
			p "окном."
		end
		return false
	end;
	['before_Push,Pull'] = function(s, w)
		if not (pl:where() ^ 'Drawing_Room') then
			p ("Для начала необходимо покинуть ", pl:where():noun 'вн', ".")
			return
		end
		if have 'white_kitten' or have 'black_kitten' then
			p "Только не с котенком в руках!";
			return
		end
		local k
		if _'white_kitten'.state == CHAIR_STATE then
			k = 'white_kitten'
		elseif _'black_kitten'.state == CHAIR_STATE then
			k = 'black_kitten'
		end
		if k then
			p [[Начав двигать кресло, Алиса обнаружила, что ]]
			p (_(k):noun(1))
			p [[ находится прямо на его пути. Хорошо, что она заметила это
                  вовремя -- а то могла бы просто раздавить бедное создание!]];
			return
		end
		if s.moved then
			s.moved = false
			p "Алиса отодвинула кресло дальше от камина.";
			return
		end
		s.moved = true
		p "Алиса придвинула кресло ближе к камину.";
	end;
        before_Transfer = "[Если так уж хочется сдвинуть кресло с места, попробуйте тянуть или толкать его.]";
	['before_Climb,Enter'] = function(s)
		move(pl, s)
		p "Алиса забралась с ногами в мягкое удобное кресло.";
	end;
        before_Take = "Но кресло слишком тяжелое для маленькой девочки!";
} : attr 'static,concealed,supporter,enterable'

obj {
	-"каминная полка,полка";
	nam = 'mantelpiece';
	found_in = "Drawing_Room";
        description = function()
    		p [[Она довольно высоко (гораздо выше, чем Алиса может достать),
но зато выглядит достаточно прочной и широкой,
чтобы на ней можно было стоять без риска.]];
		return false;
	end;
	['before_Enter,Climb'] = function(s)
		if pl:where() == s then
			p "Но Алиса уже на ней!";
			return
		end;
		if not pl:where() ^ 'armchair' then
			p "Каминная полка слишком высоко, чтобы до нее достать.";
			return
		end
		if not _'armchair'.moved then
			p "Отсюда невозможно дотянуться до каминной полки!";
			return
		end
		if #inv() > 0 then
			p "Для этого руки должны быть свободны!";
			return
		end
		move(pl, 'mantelpiece')
		p "Алиса ловко вскарабкалась на каминную полку.";
	end;
	['before_Receive,LetGo'] = function(s)
		if pl:where() ~= s and
		(not pl:where() ^ 'armchair' or not _'armchair'.moved) then
			p "Полка слишком высоко, за пределами досягаемости."
			return
		end
		return false
	end
}:attr 'concealed,supporter,enterable,static'

obj {
	-"зеркало,стекло";
	nam = 'mirror';
	found_in = "Drawing_Room";
        description = function(s)
		if pl:where() ^ 'mantelpiece' then
			p [[Невероятно -- но стеклянная поверхность зеркала
                 тает на глазах, подобно призрачному серебристому пару!]];
			return
		end
		if pl:where() ^ 'armchair' then
			p [[В зеркале отражается хорошо знакомая гостиная -- в ней
                 все такое же, как и по эту сторону, только наоборот.
                 Но почему-то Алиса уверена в том, что за краем зеркала,
                 куда никак невозможно заглянуть, лежит мир Зазеркалья --
                 и он совершенно не похож на привычный...]];
			return
		end
		p [[Отсюда в зеркале можно разглядеть только потолок гостиной.
             Впрочем, он ничем не отличается от потолка по эту сторону зеркала.]];
        end;
	before_Any = function(s, ev)
		if mp.event ~= 'Exam' and mp.event ~= 'Reflect' and mp.event ~= 'Search'
		and mp.event ~= 'ThrownAt' and not pl:where() ^ 'mantelpiece' then
			p "Отсюда невозможно даже дотянуться до зеркала!";
			return
		end
		return false
	end;
	['before_Touch,Pull,Push'] = "Рука проходит сквозь серебристый туман, не встречая сопротивления!";
	before_ThrownAt = "И заработать семь лет несчастий и бед?!";
	before_Enter = function(s)
		-- Добро пожаловать в Зазеркалье!
		-- ! (а игра, увы, кончается ;)
		p [[Рука Алисы без труда прошла через серебряный туман...
             за ней последовало остальное тело...
             и вот она уже по ту сторону зеркала!!!]];
                walk 'theend'
        end;
} : attr 'static,concealed,enterable'

obj {
	-"клубок шерсти,клубок|шерсть";
	nam = 'worsted';
	found_in = 'Drawing_Room';
	sputan = false;
        dsc = function(s)
		if _'white_kitten'.state ~= WOOL_STATE and
			_'black_kitten'.state ~= WOOL_STATE then
				p "На полу лежит клубок шерсти.";
		end
	end;
        description = function(s)
		if s.sputan then
			p [[Сейчас он спутан так, что почти не размотаешь.
                 Сколько времени Алиса потратила на то, чтобы намотать шерсть
                 аккуратным клубком -- и вот, теперь на него страшно взглянуть!]];
		else
			p "Клубок очень хорошей голубой шерсти, готовый к вязанию.";
		end
        end;
	before_Untangle = function(s)
		if s.sputan then
			s.sputan = false
			p [[Это оказалось не быстрым и не простым делом...
             зато теперь клубок совсем как новый -- тугой и аккуратный!]]
		else
			p "Но шерсть не спутана!";
		end
	end;
        after_Take = function(s)
		if _'white_kitten'.state == WOOL_STATE then
			_'white_kitten'.state = CHAIR_STATE;
		end
		if _'black_kitten'.state == WOOL_STATE then
			_'black_kitten'.state = CHAIR_STATE;
		end
		return false
        end
}
obj {
	-"окно|рама";
	nam = 'window';
	found_in = 'Drawing_Room';
        description = [[За окном неторопливо кружатся снежинки,
         заставляющие Алису радоваться, что она внутри дома, в тепле и уюте.]];
        before_Open = function(s)
		p "И подхватить простуду?! Лучше оставить окно закрытым.";
	end;
        before_Search = function(s) mp:xaction("Exam", s) end;
}: attr 'scenery'

Kitten = Class {
	ini = function(s)
		s.other_kitten = _(s.other_kitten)
	end;
	dsc = function(s)
		if s.state == QUEEN_STATE then
			p("^", s:Noun(1), " играет с Черной Королевой.")
		elseif s.state == WOOL_STATE then
			p("^", s:Noun(1), " играет с клубком шерсти.")
		elseif s.state == CHAIR_STATE then
			if s.seen then
				return
			end
			if s.other_kitten.state == CHAIR_STATE then
				s.other_kitten.seen = true
				p "^Пара котят резвятся друг с другом на коврике рядом с креслом.";
				return
			end
			p(s:Noun(1), " резвится на коврике рядом с креслом.")
			return
		else
			return
		end
	end;
        description = function(s)
		p [[Какой красивый котенок! Из пары именно он -- Алисин любимчик,
             и намного симпатичней ей, чем непослушный и непоседливый ]]
		p (s.other_kitten:noun(), ".")
	end;
	['life_Ask,Answer,Tell,Talk'] = function(s)
		p(s:Noun(1), [[, шевеля усами, смотрит на Алису
            	с таким умным видом, что она почти готова поверить,
            	будто он понимает каждое ее слово.]]);
	end;
	life_Kiss = function(s)
		p ("Алиса чмокнула ", s:noun('вн',1), [[ в носик,
             и тот взглянул на нее сконфуженно, но довольно.]]);
	end;
	life_Attack = "Разве можно напасть на такое крохотное и беззащитное создание!";
	Show = function(s, w)
		p (s:Noun(1),", протянув лапку, опасливо дотронулся до ", w:noun'рд', ".")
	end;
	['life_Give,ThrowAt'] = function(s, w)
		if not w ^ 'red_queen' and not w ^ 'worsted' then
			if mp.event == 'ThrowAt' then
				move(w, 'Drawing_Room')
				p ("Алиса бросила ", w:noun 'вн', " на пол, и ", s:noun(1))
			else
				p (s:Noun(1))
			end
			p (" рассматривает ", w:noun'вн', " с озадаченным видом.")
			return
		end
		p ("Алиса бросила ", w:noun'вн', " на пол. Немедленно ")
		pr (s:noun(1))
		if have(s) then
			p ", выскользнув из ее рук,"
		end
		move (w, 'Drawing_Room')
		move (s, 'Drawing_Room')
		pr (" бросился за ", w:noun'тв')
		if w ^ 'worsted' then
			_'worsted'.sputan = true
			s.state = WOOL_STATE
			pr ", мгновенно превратив его в дикую путаницу";
		else
			s.state = QUEEN_STATE
		end
		p "."
	end;
	before_Take = function(s)
		if have(s.other_kitten) then
			p "Двух котят сразу Алисе ни за что не удержать!";
			return
		end
		s.state = HELD_STATE;
		move(s, pl)
		p ("Алиса взяла на руки ", s:noun'вн', ". Ну что за прелестное создание!")
	end;
	['before_Touch,Rub'] = function(s)
		p (s:Noun(1), " в ответ потерся головой об Алисину руку и что-то тихонько промурлыкал.")
	end;
	after_Drop = function(s)
		s.state = CHAIR_STATE;
		move(s, 'Drawing_Room')
		p (s:Noun(1), ", выскользнув из рук Алисы, убежал прочь.")
	end;
	['after_Transfer,PutOn,Insert'] = function(s)
		s.state = CHAIR_STATE;
		pr (s:Noun(1), ", спрыгнув с ", parent(s):noun'рд')
		move(s, 'Drawing_Room')
		p", ловко приземлился на полу и убежал прочь.";
	end;
	daemon = function(s)
		s.seen = false
		s.this_kittens_turn = not s.this_kittens_turn;
		if not s.this_kittens_turn or rnd(3) == 2 then return end
--		pn()
		p (s:Noun(1))
		if s.state == HELD_STATE then
			local n = rnd(5)
			if n == 1 then
				p " жалобно мяукнул.";
			elseif n == 2 then
				p " тихо мурлыкнул.";
			elseif n == 3 then
				p " удовлетворенно промурлыкал что-то.";
			elseif n == 4 then
				p " потерся ушками о руку Алисы.";
			elseif n == 5 then
				move(s, 'Drawing_Room')
				s.state = CHAIR_STATE;
				p " спрыгнул на пол, ловко выскользнув из Алисиных рук.";
			end
			return
		elseif s.state == QUEEN_STATE then
			local n = rnd(5)
			if n == 1 then
				p " ткнул Черную Королеву лапкой.";
			elseif n == 2 then
				p " оставив на время игру, сидит с подчеркнуто невинным видом.";
			elseif n == 3 then
				p " катает бедную Королеву туда-сюда по полу.";
			elseif n == 4 then
				p " кончил умываться и осматривается по сторонам.";
			elseif n == 5 then
				p [[ взял Черную Королеву, укусил, и начал яростно трясти,
                     чтобы убедиться, что с ней покончено.]];
			end
			return
		elseif s.state == WOOL_STATE then
			_'worsted'.sputan = true
			local n = rnd(5)
			if n == 1 then
				p " ткнул клубок шерсти лапкой.";
			elseif n == 2 then
				p " покатил клубок по полу, преследуя его по пятам.";
			elseif n == 3 then
				p " сцепился с клубком в жестокой схватке.";
			elseif n == 4 then
				p [[ прыгнул на клубок сверху,
                      и окончательно запутался в мешанине шерстяных нитей.]];
			elseif n == 5 then
				p " прервав игру, чешет себя за ушами.";
			end
			return
		elseif s.state == CHAIR_STATE then
			if s.other_kitten.state == CHAIR_STATE and rnd(2) == 1 then
				local n = rnd(5);
				if n == 1 then
					p " преследует ";
				elseif n == 2 then
					p " прыгнул на "
				elseif n == 3 then
					p " умывает лапкой ";
				elseif n == 4 then
					p " обежал вокруг ";
				elseif n == 5 then
					p " ткнул ";
				end
				pr (s.other_kitten:noun'вн')
				if n == 2 then
					p " и они вместе покатились по полу.";
				elseif n == 4 then
					p " и бросился за ним.";
				elseif n == 5 then
					p " лапкой.";
				else
					p "."
				end
				return
			end
			local n = rnd(5)
			if n == 1 then
				p " гоняет по полу комок пыли."
			elseif n == 2 then
				p " катается по полу."
			elseif n == 3 then
				p " сидит и тщательно вылизывает свой хвост."
			elseif n == 4 then
				p " трется головой о ножки кресла."
			elseif n == 5 then
				p " гоняется за своим хвостом."
			end
		end
	end
}: attr 'animate'

Kitten  {
	state = CHAIR_STATE;
	-"белый котенок,котенок";
	nam = 'white_kitten';
	seen = false;
	found_in = 'Drawing_Room';
        this_kittens_turn = false;
        other_kitten = 'black_kitten';
}

Kitten  {
	state = CHAIR_STATE;
	-"черный котенок,котенок";
	seen = false;
	nam = 'black_kitten';
	found_in = 'Drawing_Room';
        this_kittens_turn = true;
        other_kitten = 'white_kitten';
}

VerbExtend {"#Exam",
	    "{noun}/вн,scene в {noun}/пр,2,scene : Reflect",
	    "~ на {noun}/вн,scene в {noun}/пр,2,scene : Reflect",
	    "~ в {noun}/пр,2,scene на {noun}/вн : Reflect reverse"
}

Verb {
	"#Untangle",
	"размот/ать,распут/ать",
	"{noun}/вн :  Untangle",
}

Verb {
	"#Touch2",
	"ласк/ать,чеса/ть,почес/ать,почеш/и,чеши/",
	"{noun}/вн : Touch"
}

room {
	nam = 'theend';
	title = 'Конец';
	dsc = false;
	noparser = true;
}

game.hint_verbs = { "#Exam", "#Walk", "#Push", "#Take", "#Drop", "#Search", "#Give", "#Touch" }
