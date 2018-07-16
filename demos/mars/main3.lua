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
Задача миссии -- собрать первую марсианскую базу и подготовиться к встрече второго экипажа.^^
		Ты -- инженер Александр Морозов, один из четырех поселенцев.^^
Сегодня, после сборки последнего жилого модуля, ты впервые получил возможность изучить окрестности базы.^
		Надев скафандр и взяв необходимое оборудование, ты направляешься в шлюзовой модуль...^^
{$fmt em|Для продолжения нажмите <ввод>}]];
	};
	next_to = 'шлюз';
}

pl.description = function(s)
	if _'скафандр':has'worn' then
		p [[На тебе надет скафандр.]]
	else
		p [[Ты выглядишь как обычно.]]
	end
end

room {
	-"шлюз";
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
