--$Name:Плащ Тьмы
require "mp-ru"
require "fmt"

game.dsc = [[^{$fmt b|ПЛАЩ ТЬМЫ}^^Тривиальная Информ-демонстрация.
^^Торопливо пробираясь сквозь дождливую и холодную ноябрьскую ночь,
Вы радостно заметили неподалеку ярко горящие огни Оперного театра.^
Конечно, очень странно, что рядом не заметно ни одной живой души...
но стоит ли ждать слишком много от простенькой демонстрационной игры?..^]]

global 'score' (0)

room {
	-"фойе";
	title = "Фойе Оперного Театра";
	nam = 'foyer';
	dsc = [[Вы стоите в центре просторного холла,
полного роскоши и декорированного красным и золотым.
Массивные люстры ярко сияют под потолком.
На север отсюда имеется выход на улицу,
две другие двери ведут в южном и западном направлении.]];
	s_to = 'bar';
	w_to = 'cloakroom';
	n_to = function() p "Вы только пришли сюда. К тому же, погода снаружи заметно ухудшается." end;
}

room {
	-"гардероб";
	nam = 'cloakroom';
	title = "Гардероб";
	dsc = [[Когда-то на стенах этой комнаты было множество крючков,
	    предназначенных для одежды, но сохранился только один.
	    Единственный выход отсюда -- восточная дверь.]];
	e_to = 'foyer';
	obj = { 'hook' };
}

obj {
	-"маленький бронзовый крючок,крючок|вешалка",
	nam = 'hook';
	description = function(s)
	    p "Всего лишь маленький бронзовый крючок для одежды, ";
	    if parent 'cloak' == s then
		    p "с которого свисает черный бархатный плащ.";
	    else
		    p "привинченный к стене.";
	    end
	end;
}: attr 'scenery,supporter'

room {
	-"буфет";
	nam = 'bar';
	title = "Буфет";
	dsc = [[Театральный буфет (намного более скромный,
	    чем можно было предположить после роскоши фойе,
	    расположенного к северу отсюда) совершенно пуст.
	    Но похоже, что в пыли на полу написано что-то важное.]];
	n_to = 'foyer';
	before_Walk = function(s, w)
		if mp.compass_dir(w) ~= 'n_to' and not w:has'light' then
			_'message'.number = _'message'.number + 2;
			p "Слоняться в кромешной тьме -- не самая лучшая идея.";
			return
		end
		return false
	end;
	before_Default = function(s, w)
		if mp.event == 'Exit' then
			return false
		end
		if not s:has 'light' then
			_'message'.number = _'message'.number + 1;
			p "В непроглядной темноте это очень трудно...";
			return
		end
		return false
	end;
	obj = { 'message' };
} :attr '~light'

obj {
	-"бархатный плащ,плащ";
	nam = 'cloak';
	scored = false;
	description = [[
	Хороший плащ (из черного бархата с атласной прокладкой),
	немного промокший от дождя. Его чернота настолько глубока,
	что возникает ощущение, словно он втягивает в себя весь свет
	из окружающего мира.]];

	['before_Drop,PutOn'] = function(s, w)
		if std.here() ^ 'cloakroom' then
			_'bar':attr'light'
			if mp.event == 'PutOn' and not s.scored then
				s.scored = true
				score = score + 1
			end
			return false
		else
			p "Не самое подходящее место для того, чтобы оставлять здесь свою одежду.";
		end
	end;
	after_Take = function(s)
		_'bar':attr '~light'
		return false
	end;
	after_PutOn = function(s, w)
		if not w ^ 'hook' then
			return false
		end
		p [[Ты повесил плащ на крючок.]]
	end
}: attr 'clothing'

obj {
	-"надпись|пыль";
	number = 0;
	nam = 'message';
	description = function(s)
		if s.number < 2 then
			p "Начертанная в пыли надпись сообщает Вам, что...";
			walk 'goodend'
		else
			p [[Полустертую надпись разобрать очень трудно.
			С трудом можно различить такие слова...]]
			walk 'badend'
		end
	end
}: attr 'scenery'

room {
	nam = 'badend';
	title = "Вы проиграли";
	dsc = false;
	noparser = true;
}

room {
	nam = 'goodend';
	title = "Вы выиграли";
	dsc = function() p ("Ваш счет: ", score) end;
	noparser = true;
}

Verb { "повес/ить",
	"{noun}/вн,held на {noun}/вн,supporter : PutOn",
	"~ на {noun}/вн,supporter {noun}/вн,held : PutOn reverse",
}

function init()
	pl.room = 'foyer'
	move('cloak', pl)
	_'cloak':attr 'worn'
end

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop" }
