--$Name:Другой Марс$
require "mp-ru"
require "fmt"
require "decor"
require "fading"
include "gfx"
game.dsc = [[]]

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

local FADE_LONG = 64

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
}

--cutscene.help = fmt.em "Для продолжения нажмите <ввод>";

declare 'mars_proc' (function(v)
	if v.x < -v.w then
		return
	end
	v.x = v.x - 1
end)

declare 'pan_left' (function(v)
	if v.fx >= v.w - theme.scr.w() then
		return
	end
	v.fx = v.fx + 1
end)

declare 'pan_right' (function(v)
	if v.fx <= 0 then
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
		timer:stop()
		D ()
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
На левый рукав выведены показатели некоторых приборов. Ты можешь посмотреть на них.
Функция подогрева поддерживает температуру тела в комфортном диапазоне. С помощью встроенной рации, ты
можешь общаться с базой.]];
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
		if here()^'шлюз' and _'люк':has'open' then
			p [[Ты определенно хочешь убить себя! Нельзя снимать скафандр при открытом люке. Такое чувство, что ты забыл инструктаж по безопасности.]];
			return
		end
		if not here()^'шлюз' then
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
	-"приборы,температур*";
	nam = 'приборы';
	found_in = 'скафандр';
	description = function(s)
		if here() ^ 'шлюз' then
			p [[Ты осматриваешь показания приборов. Все в порядке.]]
		else
			p [[Температура окружающей среды -- -25 градусов.]]
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
		p [[В шлем встроена рация, а также светодиодный фонарь.]]
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
	description = function() p [[Рация встроена в шлем. Ты можешь включить ее в любой момент.]] return false end;
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
	-"небо,облак*,небес*",
	found_in = { 'марс1', 'марс2', 'марс3', 'арка3', 'марс4', 'марс5' };
	before_Default = function(s, ev)
		if ev == 'Exam' then
			return false
		end
		p [[Небо слишком далеко.]];
	end;
	description = [[Небо покрыто дымкой облаков, сквозь которую пробивается Солнце.]];
}:attr'scenery';

obj {
	-"Солнце",
	found_in = { 'марс1', 'марс2', 'марс3', 'арка3', 'марс4', 'марс5' };
	before_Default = function(s, ev)
		if ev == 'Exam' then
			return false
		end
		p [[Солнце слишком далеко.]];
	end;
	description = [[Ты взглянул на Солнце. На Марсе оно выглядит совсем маленьким. Ты помнишь, что Марс расположен в 227,9 миллиона километрах от Солнца. Но это лишь цифры. Солнце
на этой планете выглядит слабым, далёким и умирающим.]];
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
			pn [[Марс... Ты бросаешь взгляд на молчаливый марсианский пейзаж и пронзительное чувство одиночества заставляет твое сердце сжаться. ]]
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
		light_theme2()
		fading.set {"crossfade", max = FADE_LONG, now = true}
		timer:set(70)
		D {'mars', 'img', 'gfx/pan.jpg',
		   fx = 4096 - theme.scr.w(),
		   y = theme.scr.h() - 388,
		   fy = 0,
		   z = 5,
		   background = true,
		   process = pan_right,
		}
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
		timer:stop()
		D()
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
воспользоваться визором. Для этого достаточно включить его, а потом посмотреть в направлении интересуемой стороны света.]]
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
		timer:set(70)
		D {'mars', 'img', 'gfx/lighthouse.jpg',
		   fx = 1222 - theme.scr.w(),
		   y = theme.scr.h() - 368,
		   fy = 0,
		   z = 5,
		   background = true,
		   process = pan_right,
		}
	end;
	text = {
		[[Сквозь окуляры визора ты наблюдаешь как пологие холмы сменяют другие холмы... Но... Что это?^^

Твоё сердце выпрыгивает из груди. Ты видишь то, что никак не может быть творением природы.
Снова и снова ты вглядываешься в очертания высокой башни или вышки и не веришь своим глазам.^^

Связаться с базой! Эта мысль сразу приходит тебе в голову, но потом ты понимаешь, что тебя не поймут. Ты бы и сам не поверил.
Ведь каждый квадратный метр Марса изучен вдоль и поперек. Каждый на Земле знает, что на Марсе нет и не было никакой жизни...^^
Ты понимаешь, что у тебя нет иного выбора. Ты должен пойти и убедиться в реальности происходящего.]];
	};
}

room {
	nam = 'марс5';
	title = 'Марс';
	dsc = function(s)
		if s:once() then
			p [[Ты шел настолько быстро, насколько мог. Примерно через пол часа ты преодолел
возвышенность и перед тобой открылся вид, который заставил тебя остановиться. Это не могло быть
правдой. Ты видел прекрасный, но нереальный мираж.^^]];
		end
		p [[На западе раскинулось море. Ты видишь, как оранжевое Солнце ярко отражается
в водной поверхности, покрытой рябью небольших волн. Высокая башня, которую ты заметил раньше, построена на скалистом выступе. Он находится на северо-западе.]]
	end;
}

cutscene {
	nam = 'марс6';
	title = false;
	onenter = function(s)
		light_theme3();
		fading.set {"crossfade", max = FADE_LONG, now = true}
		timer:set(70)
		D {'mars', 'img', 'gfx/coast.jpg',
		   fx = 0,
		   y = theme.scr.h() - 448,
		   fy = 0,
		   z = 5,
		   background = true,
		   process = pan_left,
		}
	end;
	text = {
		[[TODO]]
	};
}

function init()
	take 'скафандр'
	take 'шлем'
	dark_theme()
end

function start(load)
	if load then return end
	fading.set {"crossfade", max = FADE_LONG, now = true}
end

Verb {
	"провер/ить",
	"{noun}/вн : Exam";
}

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop", "#FireAt", "#Salute", "#Talk" }
