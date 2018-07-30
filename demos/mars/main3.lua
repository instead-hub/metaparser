--$Name:Другой Марс$
require "mp-ru"
require "fmt"
require "decor"
require "fading"
include "gfx"
game.dsc = [[]]

local FADE_LONG = 64

function dark_theme()
	T('scr.col.bg', '#151515')
	T('win.col.fg', '#dddddd')
	T('inv.col.fg', '#dddddd')
	T('inv.col.link', '#dddddd')
	sprite.scr():fill '#151515'
	_'@decor'.bgcol = '#151515'
end

local mars_col = '#eadaca'
local mars_col2 = '#f4efc9'
local mars_col3 = '#e9b664'

function light_theme()
	T('scr.col.bg', mars_col) -- '#eadaca')
	T('win.col.fg', '#000000')
	T('inv.col.fg', '#151515')
	T('inv.col.link', '#151515')
	_'@decor'.bgcol = mars_col -- '#eadaca'
	sprite.scr():fill(mars_col) -- '#eadaca'
end

function light_theme2()
	T('scr.col.bg', mars_col2)
	T('win.col.fg', '#000000')
	T('inv.col.fg', '#000000')
	T('inv.col.link', '#000000')
	_'@decor'.bgcol = mars_col2
	sprite.scr():fill(mars_col2)
end

function light_theme3()
	T('scr.col.bg', mars_col3)
	T('win.col.fg', '#000000')
	T('inv.col.fg', '#000000')
	T('inv.col.link', '#000000')
	_'@decor'.bgcol = mars_col3
	sprite.scr():fill(mars_col3)
end

global 'anim_fn' (false)

declare 'anim_stars' (function()
	_'@decor'.bgcol = 'black'
	timer:set(50)
	D {'mars', 'img', 'gfx/mars3.jpg',
		x = theme.scr.w(),
		y = theme.scr.h(),
		z = 5,
		process = mars_proc
	}
	D'mars'.x = D'mars'.x - D'mars'.w / 3
	D'mars'.y = D'mars'.y - D'mars'.h / 4
	make_stars(stars_left)
end)

declare 'anim_pan' (function()
	light_theme2()
	timer:set(70)
	D {'mars', 'img', 'gfx/pan.jpg',
	   fx = 4096 - theme.scr.w(),
	   y = theme.scr.h() - 388,
	   fy = 0,
	   z = 5,
	   background = true,
	   process = pan_right,
	}
end)

declare 'anim_lighthouse' (function()
	timer:set(70)
	D {'mars', 'img', 'gfx/lighthouse.jpg',
	   fx = 1222 - theme.scr.w(),
	   y = theme.scr.h() - 368,
	   fy = 0,
	   z = 5,
	   background = true,
	   process = pan_right,
	}
end)

declare 'anim_coast' (function()
	light_theme3();
	timer:set(70)
	D {'mars', 'img', 'gfx/coast.jpg',
	   fx = 0,
	   y = theme.scr.h() - 448,
	   fy = 0,
	   z = 5,
	   background = true,
	   process = pan_left,
	}
end)

function anim(name)
	anim_fn = name
	if not name then D(); timer:stop(); return; end
	_G['anim_'..name]()
end


room {
	nam = 'main';
	noparser = false;
	title = "{$fmt y,40%}{$fmt c|Внимание}";
	dsc = [[{$fmt y,60%}{$fmt c|В этой игре вам придётся вводить фразы с помощью клавиатуры.^
Если вы согласны, наберите "да" и нажмите <ввод>.}]];
	before_Default = function(s)
		mp:clear()
		me():need_scene(true)
	end;
	before_No = function(s)
		s.noparser = true
		p [[До свидания!]]
	end;
	before_Yes = function(s)
		fading.set {"fadeblack", max = FADE_LONG }
		game:reaction(false)
		walk 'intro'
	end;
	hint_verbs_only = { "#Yes", "#No" };
}

cutscene.help = fmt.em "<дальше>";

declare 'mars_proc' (function(v)
	if v.x < -v.w then
		return
	end
	v.x = v.x - 1
end)

declare 'pan_left' (function(v)
	if v.fx >= v.w - theme.scr.w() then
		timer:stop()
		return
	end
	v.fx = v.fx + 1
end)

declare 'pan_right' (function(v)
	if v.fx <= 0 then
		timer:stop()
		return
	end
	v.fx = v.fx - 1
end)

declare 'mars_proc3' (function(v)
	if v.x <= -v.w + theme.scr.w() then
		return
	end
	v.x = v.x - 2
end)

declare 'stars_left' (function(v)
	v.x = v.x - 1
	if v.x < 0 then
		v.x = theme.scr.w() + rnd(64)
		v.y = rnd(theme.scr.h())
	end
end)
cutscene {
	nam = 'intro';
	onenter = function()
		anim'stars'
	end;
	text = {
		[[{$fmt y, 20%}Год 2027 от Рождества Христова.^^
Экипаж миссии "Mars One" высаживается на Марс.^
Задача миссии -- собрать первую марсианскую базу и подготовиться к встрече второго экипажа.^^
		Ты -- инженер Александр Морозов, один из четырёх поселенцев.^^
Сегодня, после сборки последнего жилого модуля, ты впервые получил возможность изучить окрестности базы.^^
		Надев скафандр и взяв необходимое оборудование, ты направляешься в шлюзовой модуль...]];
--{$fmt em|Для продолжения нажмите <ввод>}]];
	};
	next_to = 'шлюз';
	onexit = function()
		anim(false)
		fading.set {"fadeblack", max = FADE_LONG}
	end;
}

local function insuit()
	if _'шлем':has'worn' and not _'шлем':has'open' then
		return true
	end
end

function game:Eat()
	if insuit() then
		p [[В скафандре это будет сложно сделать.]]
		return
	end
	return false
end

function game:Taste()
	if insuit() then
		p [[В скафандре это будет сложно сделать.]]
		return
	end
	return false
end

function game:Smell()
	if insuit() then
		p [[В скафандре ты чувствуешь только запах своего пота.]]
		return
	end
	return false
end

pl.description = function(s)
	if insuit() then
		p [[На тебе надет скафандр.]]
	else
		p [[Ты выглядишь как обычно.]]
	end
end

room {
	-"шлюз,модул*,отсек*";
	nam = 'шлюз';
	examined = false;
	onenter = function(s)
		dark_theme()
	end;
	before_Exam = function(s, w)
		if w ~= pl or here().examined then
			return false
		end
		_'скафандр':before_Exam()
	end;
	out_to = 'люк';
	in_to = function(s)
		p [[Ты собрался изучить окрестности базы, а не возвращаться на базу.]]
	end;
	dsc = function(s)
		if s:once() then
			pn [[Итак, первые две недели на Марсе подошли к концу. Все это время экипаж трудился не покладая рук, собирая модули из запчастей, которые были доставлены грузовым автоматическим кораблем до прибытия миссии.^^
Марс оказался именно таким каким он и должен был быть -- безжизненным и недружелюбным, обдуваемыми ураганными ветрами из разреженного воздуха, наполненного проклятой марсианской пылью.
И все-таки, желающих отправиться сюда было достаточно.^]]
		end
		p [[Ты стоишь в шлюзовом отсеке жилого модуля и готовишься выйти наружу, чтобы сделать небольшую вылазку и изучить окрестности базы.]];
	end;
}

door {
	-"люк,дверь*,проём*";
	nam = 'люк';
	found_in = { 'шлюз', 'марс1' };
	before_Open = [[Люк открывается с помощью красного рычага.]];
	before_Close = [[Люк закрывается с помощью красного рычага.]];
	when_closed = function(s)
		if here() ^ 'шлюз' then
			p [[Для открытия люка достаточно потянуть за красный рычаг.]];
		else
		end
	end;
	when_open = [[Входной люк -- открыт.]];
	description = function(s)
		if not s:has'open' then
			return false
		end
		if here() ^ 'шлюз' then
			p [[Сквозь проём люка ты видишь безжизненный марсианский пейзаж.]];
		else
			p [[Сквозь проём люка ты видишь шлюзовой отсек.]]
		end
	end;
	door_to = function()
		if here() ^ 'шлюз' then
			return 'марс1';
		else
			return 'шлюз'
		end
	end
}:attr 'static'

obj {
	-"скафандр";
	nam = 'скафандр';
	description = [[Скафандр позволяет выжить там где жизни нет.
На левый рукав выведены показатели некоторых приборов. Ты можешь посмотреть на них.]];
	before_Exam = function(s)
		if here()^'шлюз' then
			if not s:has'worn' then
				p [[Тебе лучше надеть скафандр.]]
				return
			end
			pn (s.description)
			pn ()
			p [[Ты проверил герметичность скафандра. Все в порядке!]]
			here().examined = true
			return
		end
		return false
	end;
	before_Disrobe = function(s)
		if not insuit() then
			return false
		end
		if here()^'шлюз' and _'люк':has'open' then
			p [[Ты определенно хочешь убить себя! Нельзя снимать скафандр при открытом люке. Такое чувство, что ты забыл инструктаж по безопасности.]];
			return
		end
		if not here()^'шлюз' then
			if seen 'девушка' then
				if _'девушка'.try then
					p [["Не верь им." Кому это -- им? Приборам? Ты настолько сбит с толку,
что сам того не понимая решаешься на безрассудный поступок и снимаешь шлем.^^]]
					p [[Ты вдыхаешь разреженный воздух полной грудью и... Ничего не происходит.
Непонятно как, но ты дышишь! Слабый прохладный ветерок обдувает тебя. Это никак не похоже на отрицательные
марсианские температуры...]]
					_'шлем':attr'~worn'
					return
				else
					p [[А что если... Ты еще раз краем глаза смотришь на приборы. Нет, это безумие. Внезапно, тебе становится страшно.]]
				end
				return
			end
			p [[На Марсе невозможно выжить без скафандра!]]
			return
		end
		return false
	end;
	after_Disrobe = function(s)
		_'шлем':attr'~worn'
		return false
	end;
	after_Wear = function(s)
		if have'шлем' then
			_'шлем':attr'worn'
		end
		return false
	end;
}:attr 'clothing,worn';

cutscene {
	nam = 'dialog1';
	text = {
		[[-- База, база, я Алекс!]],
		[[-- Слышу тебя, Алекс. Cобрался на прогулку?]],
		[[-- Да, хочу пройтись к северным холмам.  Оттуда должен быть прекрасный вид.]],
		[[-- Не знаю, что ты там ожидаешь увидеть такого, Алекс.]],
		[[-- По правде говоря, не могу больше находиться в этих проклятых канистрах...]],
		[[-- Ладно, погуляй. И будь осторожен, не задерживайся там. Удачи...]]
	}
}
obj {
	-"компас";
	nam = 'компас';
	found_in = 'скафандр';
	description = [[Компас позволяет ориентироваться на местности. Как и многие другие приборы, компас встроен в скафандр.
Кроме того, положение базы фиксируется по пеленгу.]];
}

obj {
	-"визор";
	nam = 'визор';
	found_in = 'скафандр';
	description = [[Визор -- оптический прибор, позволяет рассматривать объекты, которые удалены на большое расстояние.
К сожалению, прибор практически бесполезен из-за наличия в атмосфере марса пыли, которая затрудняет наблюдения.]];
	before_SwitchOn = function(s)
		if not here() ^ 'марс4' then
			p [[Тебе сейчас не нужен визор.]]
			return
		end
		return false
	end;
	['before_Search,Exam'] = function(s)
		if s:has'on' then
			p [[Для того, чтобы пользоваться визором, достаточно просто смотреть в ту сторону света, которая тебя интересует.]]
		else
			return false
		end
	end;
	each_turn = function(s)
		if player_moved() and s:has'on' then
			p [[Для экономия заряда батарей ты выключаешь визор.]]
			s:attr'~on'
		end
	end;
}:attr'switchable';

obj {
	-"приборы,показател*|левый рукав/но|рукав";
	nam = 'приборы';
	found_in = 'скафандр';
	description = function(s)
		p [[Функция подогрева поддерживает температуру тела в комфортном диапазоне.^]]
		local o = 100
		if _'марс2':has'visited' then o = o - 7 end
		if _'марс3':has'visited' then o = o - 10 end
		if _'арка2':has'visited' then o = o - 9 end
		if _'марс5':has'visited' then o = o - 13 end
		if _'берег':has'visited' then o = o - 11 end
		p ([[Запасы кислорода: ]], o, "%.^^");
		if here() ^ 'шлюз' then
			p [[Температура окружающей среды -- 12 градусов.]]
			p ([[Скорость ветра -- ]], 0, [[ м/c.]])
		else
			p [[Температура окружающей среды -- -25 градусов.]]
			p ([[Скорость ветра -- ]], 5 + rnd(3), [[ м/c.]])
		end
	end;
}
pl.before_LetGo = function(s, w, ww)
	if w ^ 'шлем' or w ^ 'скафандр' then
		p (w:Noun(), " тебе жизненно необходим.")
		return
	end
	return false
end
obj {
	-"шлем", --шлем/шлём
	nam = "шлем";
	before_Disrobe = function(s)
		if _'скафандр':before_Disrobe() == false then
			return false
		end
	end;
	description = function(s)
		p [[В шлем встроена рация, а также светодиодный фонарь и визор.]]
	end;
}:attr'clothing,worn,concealed';

obj {
	-"фонарь,фонар*,свет";
	nam = 'фонарь';
	found_in = 'шлем';
	after_SwitchOn = function(s)
		if not pl:where():has'light' then
			me():need_scene(true)
		end
		pl:attr'light'
		return false;
	end;
	after_SwitchOff = function(s)
		pl:attr'~light'
		return false;
	end;
	each_turn = function(s)
		if pl:where():has'light' and s:has'on' and player_moved() then
			p [[С целью экономии батарей, ты выключаешь фонарь.]]
			s:after_SwitchOff()
			s:attr'~on'
		end
	end;
}:attr'switchable'

obj {
	-"рация,радио*";
	nam = 'рация';
	found_in = 'скафандр';
	description = function() p [[Рация встроена в твой скафандр. Ты можешь включить её в любой момент.]] return false end;
	before_SwitchOn = function(s)
		if not base_talked1 then
			walkin 'dialog1'
			base_talked1 = true
			return
		end
		p [[Сейчас нет необходимости связываться с базой.]]
	end;
}:attr 'switchable';

obj {
	-"красный рычаг,рычаг/но";
	nam = 'рычаг';
	found_in = { 'шлюз',  'марс1' };
	description = [[Красный массивный рычаг находится рядом с выходным люком.]];
	['before_Pull,Push,SwitchOn,SwitchOff'] = function(s)
		if here() ^ 'шлюз' then
			if not here().examined then
				p [[Прежде чем выйти наружу, необходимо еще раз осмотреть скафандр.]];
				return
			end
			if not insuit() then
				p [[Выходить без скафандра наружу -- самоубийство!]]
				return
			end
		end
		if _'люк':hasnt'open' then
			p [[Ты дергаешь за рычаг и люк с шипением открывается.]]
			_'люк':attr'open'
		else
			p [[Ты дергаешь за рычаг и люк с шипением закрывается.]]
			_'люк':attr'~open'
		end
	end;
}:attr 'scenery'

global 'base_talked1' (false)

obj {
	-"небо,облак*,небес*,горизонт*",
	found_in = { 'марс1', 'марс2', 'марс3', 'арка3', 'марс4', 'марс5', 'берег', 'у маяка' };
	before_Default = function(s, ev)
		if ev == 'Exam' then
			return false
		end
		p [[Небо слишком далеко.]];
	end;
	description = function(s)
		if _'марс4':has'visited' then
			if _'берег':has'visited' or _'у маяка':has'visited' then
				p [[Закатное небо окрашено в тёплые цвета. Солнце клонится к горизонту.]]
			else
				p [[Небо выглядит необычно чистым. Солнце кажется ярче и теплее.]]
			end
		else
			p [[Небо покрыто дымкой облаков, сквозь которую пробивается Солнце.]];
		end
	end
}:attr'scenery';

obj {
	-"Солнце",
	found_in = { 'марс1', 'марс2', 'марс3', 'арка3', 'марс4', 'марс5', 'берег', 'у маяка' };
	before_Default = function(s, ev)
		if ev == 'Exam' then
			return false
		end
		p [[Солнце слишком далеко.]];
	end;
	description = function(s)
		if _'марс4':has'visited' then
			if _'берег':has'visited' or _'у маяка':has'visited' then
				p [[Солнце уже клонится к горизонту. Но не смотря на это, оно кажется необычно ярким.]]
			else
				p [[Солнце ярко светит в прозрачном небе.]]
			end
		else
			p [[Ты взглянул на Солнце. На Марсе оно выглядит совсем маленьким. Ты помнишь, что Марс расположен в 227,9 миллиона километрах от Солнца. Но это лишь цифры. Солнце
на этой планете выглядит слабым, далёким и умирающим.]];
		end
	end;
}:attr'scenery';

room {
	nam = 'марс1';
	title = 'Марсианская база';
	in_to = 'люк';
	n_to = 'марс2';
	cant_go = 'Ты собрался идти к северным холмам. Для этого надо идти все время на север.';
	before_Walk = function(s, w)
		if base_talked1 or w ^ '@in_to' then
			return false
		end
		p "Прежде чем уходить за пределы базы, тебе следует доложить об этом остальным. Для активации связи тебе нужно включить рацию в скафандре."
	end;
	compass_look = function(s, dir)
		if dir == 'n_to' then
			p "На севере ты видишь широкие горы."
			return
		end
		return false
	end;
	onenter = function(s, f)
		if f ^ 'шлюз' then
			_'люк':attr'~open'
			p [[Ты выходишь из модуля и закрываешь за собой люк.]]
			light_theme()
		end
	end;
	dsc = function(s)
		if s:once() then
			pn [[Марс... Ты бросаешь взгляд на молчаливый марсианский пейзаж и пронзительное чувство одиночества заставляет твоё сердце сжаться. ]]
			pn()
		end
		p [[Первое марсианское поселение представляет собой жалкое зрелище. Ты и другие члены экипажа собрали четыре небольших модуля,
которые и станут убежищем миссии на ближайший марсианский год. Рядом с модулями расположены баки с водой и кислородом. Ты находишься рядом
с шлюзовым люком.]]
		p "^^На севере возвышаются широкие горы."
	end;
}

obj {
	-"горы,холмы,гор*/но",
	["before_Enter,Walk,Climb"] = [[Горы находятся на севере. Для того, чтобы добраться
к ним нужно идти на север.]];
	found_in = 'марс1';
	description = [[Марсианский пейзаж ты видел тысячи раз на снимках и записях. Широкие горы, причудливые изгибы каньонов и
километры безжизненного грунта, покрытого вездесущей пылью. Тебе кажется, что на севере пейзаж немного разнообразнее. Поэтому ты решил идти на север. Ты понимаешь, что
выбор направления не играет особой роли. Но жизнь в замкнутом пространстве тебе невыносима.]];
}:attr 'scenery'

obj {
	-"модули,модуль*",
	nam = 'модули';
	found_in = 'марс1';
	description = [[Модули связаны между собой.]];
	before_Enter = [[Для того, чтобы попасть внутрь, нужно воспользоваться люком.]];
}:attr'scenery'

obj {
	-"баки,бак*",
	nam = 'баки';
	found_in = 'марс1';
	description = [[Баки вмещают в себя 3000 литров воды и 120 килограмм кислорода. Ты отчётливо понимаешь, как хрупка человеческая жизнь.]];
}:attr'scenery'

room {
	nam = 'марс2';
	title = 'Марс';
	ne_to = 'марс3';
	s_to = function()
		p [[Возвращаться на базу пока не входит в твои планы.]]
	end;
	cant_go = [[Твоё внимание привлекают обломки скал на северо-востоке. Ты решаешь изменить свой маршрут.]];
	onenter = function(s)
		fading.set {"crossfade", max = FADE_LONG, now = true}
		anim 'pan'
	end;
	compass_look = function(s, dir)
		if dir == 'n_to' then
			p "На севере ты видишь широкие горы."
			return
		end
		if dir == 'ne_to' then
			p "Кажется, в этом направлении местность выглядит не так однообразно."
			return
		end
		if dir == 's_to' then
			p [[Ты видишь вдалеке крошечные модули базы.]]
			return
		end
		return false
	end;
	dsc = function(s)
		if s:once() then
			pn [[Ты шёл по изломанной поверхности в течении получаса. Ничего не менялось в окружающем
тебя пространстве. Всё те же горы на севере, небо, затянутое дымкой облаков и одинокое безжизненное Солнце.]]
			pn ()
		end
		pn [[Вглядываясь в безликий пейзаж на севере, ты, кажется, замечаешь некоторое
разнообразие его форм на северо-востоке. Там пологие холмистые склоны чередуются скальными породами. Обломки скал нарушают
привычную картину марсианского ландшафта. Они кажутся тебе необычными.]]
	end;
}
obj {
	-"база,модул*";
	found_in = 'марс2';
	before_Default = "Но база очень далеко отсюда.";
	before_Exam = [[База плохо различима за рассеянной в атмосфере бурой пылью.]];
}:attr'scenery';

obj {
	-"скалы,обломк*,пород*";
	found_in = 'марс2';
	before_Default = "Добраться туда можно, если идти на северо-восток.";
	before_Exam = [[Тебе всё-равно куда идти, но эти скалы привлекли твоё внимание. Ты решаешь идти на северо-восток.]];
	['before_Enter,Walk,Climb'] = function(s)
		walkin 'intro2'
	end;
}:attr'scenery';

room {
	nam = 'марс3';
	in_to = 'арка2';
	title = 'Скалы';
	cant_go = [[Ты обнаружил нечто странное и тебе хочется осмотреть это, прежде чем идти дальше.]];
	dsc = function(s)
		if s:once() then
			pn [[Ещё через полчаса ты добрался до каменных глыб.]];
			pn ()
		end
		p [[Огромные обломки камней разбросаны по скалистой поверхности. Твоё внимание привлекают
две странные скалы, которые причудливым образом соприкасаются друг с другом, образуя подобие арки.]];
	end;
}

obj {
	-"обломки,камн*",
	found_in = 'марс3';
	['before_Take,Push,Pull'] = 'Они слишком массивные.';
	description = [[Ты обратил внимание на странный цвет обломков -- он близок к чёрному, что сильно
отличается от остального марсианского пейзажа.]];
}:attr 'scenery'

obj {
	-"арка,пещера,скал*",
	nam = 'арка';
	found_in = 'марс3';
	description = [[Две массивные скалы находятся рядом друг с другом. Правая -- в высоту около 7 метров. Левая -- 10 метров и стоит под наклоном. Скалы соприкасаются, образуя глубокую арку.]];
	['before_Enter,Walk'] = function(s)
		walkin 'арка2';
	end;
}:attr 'scenery,enterable'

room {
	-"арка,пещера",
	nam = 'арка2';
	title = "В арке";
	out_to = 'марс3';
	u_to = function(s)
		if pl:has'light' or _'арка3':has'visited' then
			return 'арка3';
		end
		return false
	end;
	dsc = function(s)
		p [[Яркий свет фонаря отражается от чёрных стен. Ты видишь, что каменистая поверхность под ногами уходит под заметным наклоном вверх.]]
	end;
	dark_dsc = function(s)
		if s:once() then
			p [[Едва ты зашёл внутрь арки тебя окутала темнота.]];
		else
			p [[Внутри арки темно. Только прозрачная поверхность твоего шлема отсвечивает тусклые огоньки приборов скафандра.]];
		end
	end;
	onenter = function(s)
		anim(false)
		dark_theme()
	end;
	onexit = function(s)
		light_theme2()
	end;
}:attr'~light'

room {
	-"арка,пещера",
	nam = 'арка3';
	title = "Выход";
	d_to = 'арка2';
	out_to = 'марс4';
	exit = function(s, t)
		if t ^ 'марс4' then
			p [[Не без труда ты протискиваешься в отверстие и оглядываешься.]]
		end
	end;
	dsc = function(s)
		if s:once() then
			pn [[Ты осторожно поднимаешься по покатой поверхности. Совсем скоро ты видишь впереди свет.]];
			pn()
		end
		p [[Покатый каменистый пол, скрываясь в темноте, ведет вниз. Сквозь широкое отверстие в арку проникает солнечный свет.]]
	end;
}

obj {
	-"отверстие|дыра,дырка";
	found_in = 'арка3';
	description = [[Большое продолговатое отверстие диаметром около полутора метров. Достаточное для того, чтобы выбраться наружу.]];
	before_Enter = function(s)
		walk 'марс4'
	end;
}:attr 'scenery,enterable'

obj {
	-"пол|поверхность";
	found_in = {'арка2', 'арка3'};
	before_Climb = function(s)
		if here() ^ 'арка2' then
			mp:xaction("Walk", _'@u_to')
		else
			mp:xaction("Walk", _'@d_to')
		end
	end;
	description = function(s)
		if here() ^ 'арка2' then
			p [[Вероятно, ты мог бы попробовать лезть наверх.]];
		else
			p [[Ты можешь спуститься вниз.]]
		end
	end;
}:attr 'scenery'

obj {
	-"стены,стен*,скал*";
	description = function(s)
		if s:once() then
			p [[Ты осматриваешь стены, пытаясь определить породу необычного камня. В свете фонаря ты замечаешь, что стены испещрены
глубокими трещинами.]]
			enable 'трещины'
			return
		end
		p [[Ты видишь на каменной поверхности странные трещины.]];
	end;
	found_in = 'арка2';
}:attr 'scenery';

obj {
	-"трещины,трещин*";
	nam = "трещины";
	found_in = 'арка2';
	before_Touch = [[Ты потрогал одну из трещин.]];
	['before_Push,Pull'] = [[Ты попытался надавить на одну из трещин.]];
	description = [[Трещины довольно глубокие, но не длинные -- не больше 10 сантиметров каждая.]];
}:attr 'scenery':disable();

room {
	nam = 'марс4';
	title = 'Марс';
	in_to = 'выход арки';
	compass_look = function(s, dir)
		if _'визор':hasnt 'on' then
			p [[Так как горизонт сейчас чист, ты можешь воспользоваться визором.]]
			return
		end
		if dir == 'nw_to' then
			if _'смотреть визор':has 'visited' then
				p [[Башня по прежнему находится там.]]
				return
			end
			walk 'смотреть визор';
			return
		end
		if dir == 's_to' or dir == 'se_to' or dir == 'sw_to' then
			p "В этом направлении обзор загораживает арка."
			return
		end
		return false
	end;
	nw_to = function(s)
		if not _'смотреть визор':has 'visited' then
			return false
		end
		return 'марс5';
	end;
	cant_go = function(s, w)
		if _'смотреть визор':has'visited' then
			p [[Ты обнаружил башню на северо-западе. Ты думаешь, что успеешь добраться до неё до заката.]]
			return
		end
		p [[Твоя прогулка уже затянулась. Солнце клонится к закату и пора подумать о возвращении на базу.
Так как горизонт сейчас чист, ты решаешь
воспользоваться визором.]]
	end;
	dsc = function(s)
		p [[Ты стоишь у обратной стороны арки. Любопытно, но ты замечаешь, что количество пыли в атмосфере
уменьшилось и горизонт на севере заметно отодвинулся.]];
	end;
}

obj {
	-"арка,дыр*,пещер*,отверст*|скалы",
	nam = 'выход арки';
	found_in = 'марс4';
	description = [[Две массивные скалы из чёрного камня опираются друг на друга, образуя арку.
Это природное образование удивляет тебя.]];
	['before_Enter,Climb'] = function(s)
		walk 'арка3';
	end;
}:attr'scenery,enterable';

cutscene {
	nam = 'смотреть визор';
	title = false;
	onenter = function(s)
		fading.set {"crossfade", max = FADE_LONG, now = true}
		anim 'lighthouse'
	end;
	text = {
		[[Сквозь окуляры визора ты наблюдаешь как пологие холмы сменяют другие холмы... Но... Что это?^^

Твоё сердце выпрыгивает из груди. Ты видишь то, что никак не может быть творением природы.
Снова и снова ты вглядываешься в очертания высокой башни и не веришь своим глазам.^^

Связаться с базой! Эта мысль сразу приходит тебе в голову, но потом ты понимаешь, что тебя не поймут. Ты бы и сам не поверил.
Ведь каждый квадратный метр Марса изучен вдоль и поперёк. Каждый на Земле знает, что на Марсе нет и не было никакой жизни...^^
Ты понимаешь, что у тебя нет иного выбора. Ты должен пойти и убедиться в реальности или нереальности происходящего.]];
	};
}

room {
	nam = 'марс5';
	title = 'Марс';
	before_Swim = [[До воды нужно сначала дойти.]];
	w_to = 'берег';
	nw_to = 'у маяка';
	cant_go = function(s, to)
		if to == 's_to' or to == 'se_to' or to == 'sw_to' then
			p [[Ты думаешь, что мог бы сейчас повернуть назад, вернуться на базу и забыть всё.
Выбросить из головы то, чего быть никак не может. Возможно, это было бы спасением для тебя.^^
Но ты понимаешь, что зашёл слишком далеко. Забыть такое ты не в состоянии. Никогда.]]
		else
			return false
		end
	end;
	dsc = function(s)
		if s:once() then
			p [[Ты шёл настолько быстро, насколько мог. Примерно через пол часа ты преодолел
возвышенность и перед тобой открылся вид, который заставил тебя остановиться. Это не могло быть
правдой. Ты видел прекрасный, но нереальный мираж.^^]];
		end
		p [[На западе раскинулось море. Ты видишь, как оранжевое солнце ярко отражается
в водной поверхности, покрытой рябью небольших волн. Высокая башня, которую ты заметил раньше, построена на скалистом выступе на северо-западе.]]
	end;
}
obj {
	-"море,водн*,поверхн*|вода|волны";
	nam = 'море';
	before_Default = function(s, ev)
		if here() ^ 'у маяка' or here() ^ 'берег' then
			return false
		end
		if ev == 'Exam' then
			return false
		end
		p [[Но море слишком далеко.]]
	end;
	['before_Walk,Enter'] = function(s)
		if here() ^ 'у маяка' or here() ^ 'берег' then
			if mp.event == 'Enter' then
				p [[Остатки здравого смысла удерживают тебя от этого поступка.]]
				return
			end
			return false
		end
		move(pl, 'берег')
	end;
	found_in = { 'марс5', 'берег', 'у маяка' };
	description = function(s)
		if here() ^ 'у маяка' or here() ^ 'берег' then
			p [[Некоторое время ты наблюдаешь, как волны накатываются на берег.]]
			return
		end
		p [[Это мираж. По другому быть просто не может. Воды на Марсе в таких количествах нет.]];
	end
}:attr 'scenery'
obj {
	-"маяк,утёс*,скал*|башня";
	found_in = 'берег';
	['before_Walk,Enter'] = function(s)
		move(pl, 'у маяка')
	end;
	before_Default = function(s, ev)
		if ev == 'Exam' then return false end
		p [[Маяк слишком далеко.]]
	end;
	description = [[Маяк достигает в высоту 100 метров. Его белая башня установлена на небольшом утёсе, омываемым морем с
севера, запада и юга.]];
}:attr 'scenery'

obj {
	-"башня,скал*,выступ*|маяк";
	['before_Walk,Enter'] = function(s)
		move(pl, 'у маяка')
	end;
	before_Default = function(s, ev)
		if ev == 'Exam' then
			return false
		end
		p [[Но башня слишком далеко.]]
	end;
	found_in = 'марс5';
	description = [[Башня напоминает тебе маяк. Возможно, это и есть маяк? Но море -- это мираж. Ты убеждён
в этом. Может быть и маяк -- тоже мираж?]];
}:attr 'scenery'

room {
	-"берег";
	nam = 'у маяка';
	['nw_to,sw_to,w_to'] = function(s)
		p [[На западе находится открытое море.]]
	end;
	n_to = function(s)
		p [[Берег на севере скалистый, изрезанный ущельями. Ты сомневаешься, что сможешь спуститься к морю.]]
	end;
	compass_look = function(s, t)
		if t == 'w_to' or t == 'n_to'  then
			s[t](s, t)
			return
		end
		if t == 's_to' then
			p [[Берег на юге пологий и песчаный.]]
			return
		end
		return false
	end;
	onenter = function(s)
		_'берег':onenter()
	end;
	in_to = 'дверь маяка';
	s_to = 'берег';
	before_Swim = [[Остатки благоразумия удерживают тебя от этой сумасшедшей мысли.]];
	dsc = function(s)
		if s:once() and _'берег':hasnt'visited' then
			p [[Чем ближе ты приближаешься к воде, тем настойчивее подсознание твердит тебе, что
море не может быть просто миражом. И вот, ты стоишь в скафандре, на берегу марсианского моря и смотришь как
волны разбиваются о небольшой утёс, на котором установлен маяк. Вопреки здравому смыслу, вопреки всему чему
тебя учили и что ты знаешь.^^]];
		end
		p [[Ты находишься у моря. Волны с шумом разбиваются о скалистый выступ, на котором стоит маяк. Ты видишь,
как волны марсианского моря омывают песчаный берег с южной стороны утёса.]]
	end;
}:attr 'supporter'

obj {
	-"маяк|башня";
	found_in = 'у маяка';
	description = [[Высота маяка достигает 100 метров. Белый цвет башни сильно контрастирует с марсианским пейзажем.
У основания маяка ты видишь дверь.]];
	before_Enter = [[Чтобы попасть в маяк, нужно воспользоваться дверью.]];
}:attr 'scenery'

door {
	-"дверь";
	nam = 'дверь маяка';
	found_in = 'у маяка';
	before_Attack = [[Ты разбежался и ударил плечом в дверь. Дверь выдержала.]];
	before_Knock = [[Ты постучался. Никто не вышел.]];
}:attr 'scenery,locked,openable'

obj {
	-"утёс,скал*,выступ*";
	found_in = 'у маяка';
	['before_Walk,Enter'] = function(s)
		p [[Ты и так находишься на утёсе возле маяка.]]
	end;
	description = [[Утёс окружён морем с запада, севера и юга.]];
}:attr 'scenery'

cutscene {
	nam = 'мысли';
	text = {
		[[Что всё это значит? Это место не может быть Марсом.
Но ты видишь, слышишь, чувствуешь... Как это вместить?]],
		[[Параллельные миры, как их описывали фантасты? Но это объяснение ничего не значит.
Какой из миров реален? Как они могут сосуществовать?]];
		[[Ты -- первый человек, который вышел за пределы марсианской базы. И увидел то,
чего не может быть. Может быть, этот факт и есть ключ к пониманию того, что с тобой происходит?]];
		[[В самом деле, почему человек настолько самонадеян, чтобы считать, что законы вселенной должны
подчиняться его рассудку? С какой стати?]];
		[[Ты видишь этот мир первым и он конструируется таким, какой он есть? Но тогда два мира
не могут сосуществовать. Что произодёт, если ты вернёшься на базу и расскажешь обо всём? Или...]];
		[[Или ты уже никогда не сможешь вернуться?]];
		[[Какое бы объяснение ты не придумал, главный вопрос "что делать?" -- остаётся без ответа...]];
	};
	exit = function(s)
		p [[Внезапно, твой ход мыслей прерывается и только спустя секунду ты понимаешь, что причина этого
-- в хрупкой фигурке справа. Ты вздрагиваешь и резко поворачиваешься. Перед тобой стоит молодая девушка.
В голове бъется единственная мысль. {$fmt em|На ней нет скафандра!}]]
		place('девушка', 'берег')
	end;
}

cutscene {
	nam = 'закат';
	text = {
		[[-- Кто ты?^
-- Я -- Дея. Я помогаю своему отцу... -- она берёт камушек и тоже бросает его в воду.]];
		[[-- Теперь моя очередь. Расскажи, на Земле тебя никто не ждёт?^...]];
		[[... Вы разговаривали до заката.]];
	};
	exit = function(s)
		anim(false)
		dark_theme()
	end;
}

obj {
	-"девушка,женщ*,марсианк*|марсианин";
	nam = 'девушка';
	step = 0;
	list = 0;
	try = false;
	listen = false;
	dsc = [[Рядом с тобой стоит девушка.]];
	description = function(s)
		if insuit() then
			p [[Ты видишь длинные волосы, юное лицо... Скафандр. На ней нет скафандра. Ты мельком смотришь на приборы.
Минусовая температура, ветер. Сердце выпрыгивает из груди. Что за... Наваждение...]];
		else
			p [[Теперь ты можешь рассмотреть её лучше.]]
		end
	end;
	before_Ask = function(s)
		mp:xaction("Talk", s)
	end;
	before_Talk = function(s)
		if _'шлем':has'worn' then
			p [[Я пытаюсь что-то сказать, но девушка грустно качает головой из стороны в сторону.]];
		else
			if visited 'разговор с девушкой' then
				p [[-- Сначала брось камушек в воду, потом задавай вопрос. -- улыбается девушка.]]
			else
				walk 'разговор с девушкой'
			end
		end
	end;
	before_Listen = function(s)
		if not s.listen then
			p [[Ты видишь, что девушка что-то говорит тебе. Но ты слышишь только стук крови в висках.
Ты пытаешься взять свои чувства под контроль. Выкручиваешь чувствительность микрофонов на максимум.^^]]
		end
		if not insuit() then
			p [[Девушка молчит.]]
			return
		end
		s.list = s.list + 1
		if s.list > 4 then s.list = 1 end
		if s.list == 1 then
			p [[-- Сними это. Я не вижу твои глаза.]]
		elseif s.list == 2 then
			p [[-- Не бойся, здесь можно дышать.]]
		elseif s.list == 3 then
			p [[-- Сними это, пожалуйста, я не слышу тебя.]]
		else
			p [[-- Не верь им. Ничего не бойся.]]
			s.try = true
		end
		p [[^^{$fmt em|Она хочет, чтобы я снял шлем!}]]
		s.listen = true
	end;
	each_turn = function(s)
		if not insuit() then
			return
		end
		s.step = s.step + 1
		if s.step > 1 then
			p [[Девушка показывает на скафандр и что-то говорит тебе.]]
		end
	end;
}
dlg {
	nam = 'разговор с девушкой';
	title = false;
	phr = {
		[[-- Ты с марсианской базы? -- непосредственность девушки ставит тебя в тупик.]];
		{
			'Да.',
			'-- Я никогда не видела землян. Меня зовут Дея, а тебя как?',
			next = '#имя';
		};
		{
			'Нет.',
			'-- Странно, ты похож на землянина. Ты выглядишь одиноким. Меня зовут Дея, а тебя как?',
			next = '#имя';
		};
	}
}: with {
	{
		'#имя';
		{
			'Александр.',
			[[-- Хорошо, давай посидим здесь, пока не пришёл отец. Ты должен с ним поговорить.]],
			{
				'Отец? Кто твой отец?',
				[[-- Он смотритель маяка. Не беспокойся, всё будет хорошо.]],
			};
			{
				'Почему мы не умираем? Как мы дышим?',
				[[-- Давай дождёмся моего отца. А пока просто посидим и покидаем камушки в море.
Тебе ведь хочется просто покидать камни в воду, Александр?]];
				next = '#камни';
			}
		}
	};
	{
		'#камни';
		{
			'Да',
			[[-- Бедный, тебе так одиноко... -- с этими словами девушка подошла и провела
ладонью по твоему лбу. Её рука была прохладной. -- Я никогда не думала, что... -- она не окончила фразу.]];
			next = '#земля';
		};
		{
			'Нет',
			[[-- Не беспокойся, всё будет хорошо! -- с этими словами девушка подошла и провела
ладонью по твоему лбу. Её рука была прохладной. -- Бедный, тебя никто не ждёт...^Её глаза наполнились грустью.]];
			next = '#земля';
		}
	};
	{
		'#земля';
		onempty = function()
			push '#ждать';
		end;
		{
			'Что это за место?';
			[[-- Это Марс. Разве ты не знаешь? -- её тонкие губы тронула улыбка.]]
		};
		{
			"Это место не может существовать!";
			[[-- Почему? -- Брови девушки приподнялись в удивлении.]];
			{
				"Марс -- мёртвая планета. Здесь нет жизни!";
				[[-- Так верят все земляне?]];
				{
					"Не верят -- знают! -- ты почти кричишь эти слова.";
					[[-- Хорошо, но я ведь здесь, разговариваю с тобой? -- девушка выглядит грустной.]];
				}
			};
		}
	};
	{
		'#ждать';
		{
			'Хорошо, давай подождём твоего отца.';
			function() p [[-- А пока давай бросать камушки в воду и ты расскажешь мне о Земле? Хорошо? -- С этими словами она садится рядом с тобой на песок.]]; walkback() end;
		}
	}
}
room {
	nam = 'берег';
	title = "На берегу";
	onexit = function(s, w)
		if w ^ 'разговор с девушкой' or w ^ 'закат' then
			return
		end
		if visited 'разговор с девушкой' then
			p [[-- Не уходи! -- девушка выглядит расстроенной.]];
			return false
		end
		if seen 'девушка' and insuit() then
			p [[Бежать! Но ноги не слушаются. Ты смотришь на стройную фигурку, не можешь отвести от неё свой взгляд.]]
			return false
		end
	end;
	after_Enter = function(s, w)
		if w ^ 'песок' then
			p [[Ты садишься на песок прямо в скафандре. Некоторое время ты просто смотришь на солнечную дорожку
на морской поверхности.]]
			if not visited'мысли' then
				p [[Ты понимаешь, что должен сосредоточится и подумать. Думать. Ты должен {$fmt em|думать!}]]
			end
		else
			return false
		end
	end;
	after_Exit = function(s, w)
		if w ^ 'песок' then
			p [[Ты поднимаешься с песка, машинально отряхивая песчинки с скафандра.]]
		else
			return false
		end
	end;
	before_Think = function(s)
		if pl:where() ^ 'песок' then
			if visited 'мысли' then
				p [[Реальность превосходит все твои представления.]]
				return
			end
			walk 'мысли'
		else
			p [[Тебе сложно сосредоточиться. Может быть, сесть на песок?]]
		end
	end;
	before_Swim = [[Остатки благоразумия удерживают тебя от этой сумасшедшей мысли.]];
	onenter = function(s)
		if s:once'theme' then
			fading.set {"crossfade", max = FADE_LONG, now = true}
			anim 'coast'
		end
	end;
	n_to = 'у маяка';
	dsc = function(s)
		if s:once() and _'у маяка':hasnt'visited' then
			p [[Чем ближе ты приближаешься к воде, тем настойчивее подсознание твердит тебе, что
море не может быть просто миражом. И вот, ты стоишь в скафандре, на берегу марсианского моря и смотришь как
небольшие волны накатываются на берег. Вопреки зравому смыслу, вопреки всему чему тебя учили и что ты знаешь.^^
Теперь ты понимаешь, что высокая башня, которую ты заметил -- не что иное, как маяк.^^]];
		end
		p [[Ты находишься на берегу моря. Берег здесь песчаный, но песок усеян небольшими камнями.
Маяк находится севернее.]]
	end;
}:attr 'supporter'

obj {
        nam = 'песок';
	-"песок,берег,пляж";
	found_in = 'берег';
	before_Take = function(s)
		if pl:where() == s then
			p [[Ты погружаешь пальцы в песок.]]
		else
			p [[Ты нагибаешься и берешь горсть песка. Потом разжимаешь руку и смотришь как песок струится сквозь
пальцы в перчатках.]]
		end
	end;
	description = function(s)
		if pl:where() == s then
			p [[Песок под твоими руками. Песок с марсианского пляжа. Невозможно.]];
		else
			p [[Глядя на песок у тебя появляется спонтанное желание сесть. Да,
просто сесть на песок. Пожалуй, это всё, что ты сейчас можешь сделать.]];
		end
	end
}:attr 'scenery,enterable,supporter':dict {
	["песок/пр,2"] = "песке";
}

obj {
	nam = 'камень';
	before_ThrowAt = function(s, w)
		if w ^ 'море' then
			p [[Ты бросаешь камень в море.]]
			if visited 'разговор с девушкой' then
				walk 'закат'
			end
		elseif w ^ 'песок' then
			p [[Ты бросаешь камень в песок.]]
		else
			return false
		end
		remove(s)
	end;
	after_Drop = function(s)
		remove(s)
		return false
	end;
	after_Take = [[Ты берёшь один из камней в руку.]];
}

obj {
	-"камень,камушек|камни,камушки";
	nam = 'камни';
	found_in = 'песок';
	description = [[Небольшие кусочки скалистых пород. Множество их разбросаны по всему берегу.]];
	before_Take = function(s)
		if have 'камень' then
			p [[У тебя уже есть один.]]
		else
			take 'камень'
			mp.first_it = _'камень'
			p [[Ты берёшь один из камней в руку.]];
		end
	end;
}:attr 'scenery'

function init()
	take 'скафандр'
	take 'шлем'
	dark_theme()
end

function autodetect_theme()
	local f = io.open(instead.savepath().."/config.ini")
	if f then
		f:close()
		return
	end
	if PLATFORM == "ANDROID" or PLATFORM == "IOS" or PLATFORM == "S60" then
		local f = io.open(instead.savepath().."/config.ini", "w")
		f:write("theme = mobile")
		f:close()
		instead.restart()
	end
end
function start(load)
	autodetect_theme()
	if theme.name() == '.mobile' then
		mp.autohelp = true
	else
		mp.autohelp = false
	end
	if anim_fn then
		anim(anim_fn)
	end
	if load then
		return
	end
	fading.set {"crossfade", max = FADE_LONG, now = true}
end

Verb {
	"#Check",
	"провер/ить",
	"{noun}/вн : Exam";
}
VerbHint ( '#Yes', function() return here() ^ 'main' end )
VerbHint ( '#No', function() return here() ^ 'main' end )

Verb {
	"#ExamCompass",
	"смотр/еть",
	"на {compass1}/вн : Exam"
}

VerbHint ('#ExamCompass', function()
	return _'визор':has'on'
end)

function mp:Knock(w)
	p [[Ты постучал в]]
	p (w:noun'вн', ".")
	p "Ничего не произошло."
end

Verb {
	"~ [ |по]стуча/ть,удар/ить",
	"в {noun}/вн,scene : Knock",
}

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#SwitchOn", "#SwitchOff", "#Pull" }
