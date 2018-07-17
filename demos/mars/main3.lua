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
end

function light_theme()
	T('scr.col.bg', '#c8c8a6')
	T('win.col.fg', '#000000')
	T('inv.col.fg', '#151515')
	sprite.scr():fill '#c8c8a6'
end

local FADE_LONG = 64

room {
	nam = 'main';
	noparser = false;
	title = "{$fmt y,40%}{$fmt c|Внимание}";
	dsc = [[{$fmt y,60%}{$fmt c|В этой игре вам придется вводить фразы с помощью клавиатуры.^
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
		Ты -- инженер Александр Морозов, один из четырех поселенцев.^^
Сегодня, после сборки последнего жилого модуля, ты впервые получил возможность изучить окрестности базы.^
		Надев скафандр и взяв необходимое оборудование, ты направляешься в шлюзовой модуль...]];
--{$fmt em|Для продолжения нажмите <ввод>}]];
	};
	next_to = 'шлюз';
	onexit = function()
		_'@decor'.bgcol = '#151515'
		timer:stop()
		D ()
		fading.set {"fadeblack", max = FADE_LONG}
	end;
}

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
	before_Exam = function(s, w)
		if w ~= pl or here().examined then
			return false
		end
		_'скафандр':before_Exam()
	end;
	out_to = 'люк';
	dsc = function(s)
		if s:once() then
			pn [[Итак, первые две недели на Марсе подошли к концу. Все это время экипаж трудился не покладая рук, собирая модули из запчастей, которые были доставлены грузовым автоматическим кораблем до прибытия миссии.^^
Марс оказался именно таким каким он и должен был быть -- безжизненным и недружелюбным, обдуваемыми ураганными ветрами из разреженного воздуха, наполненного проклятой марсианской пылью.^
И все-таки, желающих отправиться сюда было достаточно.^]]
		end
		p [[Ты стоишь в шлюзовом отсеке жилого модуля и готовишься выйти наружу, чтобы сделать небольшую вылазку и изучить окрестности базы.]];
	end;
}

door {
	-"люк,выход,дверь*";
	nam = 'люк';
	found_in = 'шлюз';
	before_Open = [[Люк открывается с помощью красного рычага.]];
	before_Close = [[Люк закрывается с помощью красного рычага.]];
	when_closed = [[Для открытия люка достаточно потянуть за красный рычаг.]];
	when_open = [[Входной люк -- открыт.]];
	door_to = 'марс1';
}:attr 'static'

obj {
	-"скафандр";
	nam = 'скафандр';
	before_Exam = function(s)
		if here()^'шлюз' then
			if not s:has'worn' then
				p [[Тебе лучше надеть скафандр.]]
				return
			end
			p [[Ты проверил герметичность скафандра.]]
			here().examined = true
			return
		end
		return false
	end;
	before_Disrobe = function(s)
		if here()^'шлюз' and _'люк':has'open' then
			p [[Ты определенно хочешь убить себя! Нельзя снимать скафандр при открытом люке!]];
			return
		end
		return false
	end;
}:attr 'clothing,worn';

obj {
	-"красный рычаг,рычаг";
	nam = 'рычаг';
	found_in = 'шлюз';
	description = [[Красный массивный рычаг находится рядом с выходным люком.]];
	['before_Pull,Push,SwitchOn,SwitchOff'] = function(s)
		if not here().examined then
			p [[Прежде чем выйти наружу, необходимо еще раз проверить скафандр.]];
			return
		end
		if not _'скафандр':has'worn' then
			p [[Выходить без скафандра наружу -- самоубийство!]]
			return
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
room {
	nam = 'марс1';
	title = 'У шлюза';
	onenter = function(s)
		light_theme()
	end;
}

function init()
	dark_theme()
	take 'скафандр'
end

function start(load)
	if not load then
		fading.set {"crossfade", max = FADE_LONG, now = true}
	end
end

Verb {
	"провер/ить",
	"{noun}/вн : Exam";
}

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop", "#FireAt", "#Salute", "#Talk" }
