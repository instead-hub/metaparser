--$Name:Хейди$
require "mp-ru"
require "fmt"

game.dsc = [[^Пример простой игры на Inform.
^Авторы: Роджер Фирт (Roger Firth) и Соня Кессерих (Sonja Kesserich).
^Перевод Юрия Салтыкова a.k.a. G.A. Garinson^
^Перевод на МЕТАПАРСЕР 3 выполнил Петр Косых.
^
]]

room {
	nam = "before_cottage";
	title = "Перед домом";
	dsc = "Ты стоишь около избушки, на восток от которой раскинулся лес.";
	e_to = 'forest';
	in_to = function() p "Такой славный денек... Он слишком хорош, чтобы прятаться внутри."; end;
	cant_go = "Единственный путь ведет на восток.";
	obj = { 'cottage' };
}

obj {
	-- домик и дом - мужской род, поэтому разделены ,
	-- избушка -- жр - разделено | как другое слово
	-- со * -- пример простых шаблонов как в inform, они не
	-- будут участвовать в автодополнении, и будут относиться
	-- к избушке
	-"домик,дом|избушка,избу*,терем*,коттедж*,хат*,строени*";
	nam = "cottage";
	description = "Домик мал и неказист, но ты очень счастлива, живя здесь.";
	before_Enter = [[Такой славный денек...
                    Он слишком хорош, чтобы прятаться внутри.]];
}:attr 'scenery'

room {
	-"чаща|лес";
	nam = "forest";
	title = "В лесной чаще";
	dsc = [[На западе, сквозь густую листву, можно разглядеть небольшое строение.^
            Тропинка ведет на северо-восток.]];
	w_to = 'before_cottage';
	ne_to = 'clearing';
	obj = { 'bird' };
}

obj {
	-"птенчик,птенец|птица,птичка|детёныш";
	nam = "bird";
	description = "Слишком мал, чтобы летать, птенец беспомощно попискивает.";
	before_Listen = "Жалобный писк испуганной птички разрывает тебе сердце.^Надо помочь!";
}: attr '~animate'

room {
	-"полянка,поляна";
	nam = "clearing";
	title = "Полянка";
        dsc = [[Посреди полянки стоит высокий платан.
             Тропинка вьется меж деревьев, уводя на юго-запад.]];
        sw_to = 'forest';
        u_to = 'top_of_tree';
	obj = { 'nest', 'tree' };
}

obj {
	-"гнездо|мох|прутики,прутья";
	nam = "nest";
	description = function(s)
		p "Гнездо сплетено из прутиков и аккуратно устлано мхом.";
		mp:content(s)
	end;
}: attr 'container,open'

obj {
	-"платан|дерево|ствол";
	nam = 'tree';
	description = [[Величавое дерево стоит посреди поляны.
        Кажется, по его стволу будет несложно влезть наверх.]];
	before_Climb = function(s)
		move(me(), 'top_of_tree');
	end
} : attr 'scenery'

room {
	-"верхушка";
	nam = 'top_of_tree';
	title = "На верхушке дерева";
	dsc = "На этой высоте цепляться за ствол уже не так удобно.";
        d_to = 'clearing';
        after_Drop = function(s, w)
		move(w, 'clearing')
                return false
	end;
	obj = { 'branch' };
}

obj {
	-"сук|ветка";
	nam = 'branch';
	description = "Сук достаточно ровный и крепкий, чтобы на нем надежно держалось что-то не очень большое.";
	each_turn = function(s)
		if _'bird':inside'nest' and _'nest':inside'branch' then
			walk 'happyend'
		end
	end
}:attr 'supporter,static'

room {
	nam = 'happyend';
	title = "Конец";
	dsc = [[Поздравляем! Вы прошли игру.]];
	noparser = true;
}

function init()
	pl.word = -"ты/жр,2л"
	pl.room = 'before_cottage'
	pl.description = "Здесь нет зеркала."
end

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop" }
