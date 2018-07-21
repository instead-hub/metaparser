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
	sprite.scr():fill '#151515'
	_'@decor'.bgcol = '#151515'
end

function light_theme()
	T('scr.col.bg', '#eadaca')
	T('win.col.fg', '#000000')
	T('inv.col.fg', '#151515')
	_'@decor'.bgcol = '#eadaca'
	sprite.scr():fill '#eadaca'
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
	if v.x + v.w < 0 then
		return
	end
	v.x = v.x - 1
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

function game:Eat()
	if _'скафандр':has'worn' then
		p [[В скафандре это будет сложно сделать.]]
		return
	end
	return false
end

function game:Taste()
	if _'скафандр':has'worn' then
		p [[В скафандре это будет сложно сделать.]]
		return
	end
	return false
end

function game:Smell()
	if _'скафандр':has'worn' then
		p [[В скафандре ты чувствуешь только запах своего пота.]]
		return
	end
	return false
end

pl.description = function(s)
	if _'скафандр':has'worn' then
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

obj {
	-"рация,радио*";
	nam = 'рация';
	found_in = 'скафандр';
	description = function() p [[Рация встроена в скафандр.]] return false end;
	before_SwitchOn = function(s)
		if not base_talked1 then
			walkin 'dialog1'
			base_talked1 = true
			return
		end
		p [[Сейчас нет необходимости тратить энергию на радио.]]
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
			if not _'скафандр':has'worn' then
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
	found_in = { 'марс1', 'марс2' };
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
	found_in = { 'марс1', 'марс2' };
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
	ne_to = 'intro2';
	s_to = 'марс1';
	cant_go = [[Твоё внимание привлекают обломки скал на северо-востоке. Ты решаешь изменить свой маршрут.]];
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
			pn [[Ты шёл по изломанной поверхности в течении часа. Ничего не менялось в окружающем
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

cutscene {
	nam = 'intro2';
	text = {
		[[Ты шел еще пол часа.]];
--{$fmt em|Для продолжения нажмите <ввод>}]];
	};
}

function init()
	take 'скафандр'
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
