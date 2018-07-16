--$Name:Другой Марс$
require "mp-ru"
require "fmt"
require "decor"
require "fading"

game.dsc = [[]]

function dark_theme()
	T('scr.col.bg', 'black')
	T('win.col.fg', '#dddddd')
	T('inv.col.fg', '#dddddd')
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
cutscene {
	nam = 'intro';
	text = {
		[[{$fmt y, 30%}Год 2027 от Рождества Христова.^^
Экипаж миссии "Mars One" высаживается на Марс.^
Задача миссии -- собирать первую марсианскую базу и подготовиться к встрече второго экипажа.^^
		Ты -- инженер Александр Морозов, один из четырех поселенцев.^^
Сегодня, после сборки последнего жилого модуля, ты впервые получил возможность изучить окрестности базы.^
		Надев скафандр и взяв необходимое оборудование, ты направляешься в шлюзовой модуль...^]];
	};
}

function init()
	dark_theme()
end

function start(load)
	if not load then
		fading.set {"crossfade", max = FADE_LONG, now = true}
	end
end

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop", "#FireAt", "#Salute", "#Talk" }
