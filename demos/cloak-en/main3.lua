--$Name:Cloak of Darkness
require "parser/mp-en"
require "fmt"

game.dsc = [[^{$fmt b|Cloak of Darkness}^^Cloak of Darkness -- a simple demonstration of Interactive Fiction.
^^Hurrying through the rainswept November night, you're glad to see the
bright lights of the Opera House. It's surprising that there aren't more
people about but, hey, what do you expect in a cheap demo game...?^]]

global 'score' (0)

room {
	"foyer";
	title = "Foyer of the Opera House";
	nam = 'foyer';
	dsc = [[You are standing in a spacious hall, splendidly decorated in red
and gold, with glittering chandeliers overhead. The entrance from
the street is to the north, and there are doorways south and west.]];
	s_to = 'bar';
	w_to = 'cloakroom';
	n_to = function()
		p "You've only just arrived, and besides, the weather outside seems to be getting worse."
	end;
}

room {
	"cloakroom";
	nam = 'cloakroom';
	title = "Cloakroom";
	dsc = [[The walls of this small room were clearly once lined with hooks,
though now only one remains. The exit is a door to the east.]];
	e_to = 'foyer';
	obj = { 'hook' };
}

obj {
	"small brass hook,hook|peg",
	nam = 'hook';
	description = function(s)
	    p "It's just a small brass hook, "
	    if parent 'cloak' == s then
		    p "with a cloak hanging on it."
	    else
		    p "screwed to the wall."
	    end
	end;
}: attr 'scenery,supporter'

room {
	"bar";
	nam = 'bar';
	title = "Foyer bar";
	dsc = [[The bar, much rougher than you'd have guessed after the opulence
of the foyer to the north, is completely empty. There seems to
be some sort of message scrawled in the sawdust on the floor.]];
	n_to = 'foyer';
	before_Walk = function(s, w)
		if mp:compass_dir(w) ~= 'n_to' and not w:has'light' then
			_'message'.number = _'message'.number + 2;
			p "Blundering around in the dark isn't a good idea!"
			return
		end
		return false
	end;
	before_Default = function(s, ev, w)
		if ev == 'Exit' then
			return false
		end
		if not s:has 'light' then
			_'message'.number = _'message'.number + 1;
			p "In the dark? You could easily disturb something!"
			return
		end
		return false
	end;
	obj = { 'message' };
} :attr '~light'

obj {
	"velvet cloak,cloak";
	nam = 'cloak';
	scored = false;
	description = [[A handsome cloak, of velvet trimmed with satin, and slightly
spattered with raindrops. Its blackness is so deep that it
almost seems to suck light from the room.]],
	['before_Drop,PutOn'] = function(s, w)
		if std.here() ^ 'cloakroom' then
			_'bar':attr'light'
			if mp.event == 'PutOn' and not s.scored then
				s.scored = true
				score = score + 1
			end
			return false
		else
			p "This isn't the best place to leave a smart cloak lying around."
		end
	end;
	after_Take = function(s)
		_'bar':attr '~light'
		return false
	end;
}: attr 'clothing'

obj {
	"message,floor,sawdust";
	number = 0;
	nam = 'message';
	description = function(s)
		if s.number < 2 then
			p "The message, neatly marked in the sawdust, reads..."
			walk 'goodend'
		else
			p "The message has been carelessly trampled, making it difficult to read. You can just distinguish the words..."
			walk 'badend'
		end
	end
}: attr 'scenery'

room {
	nam = 'badend';
	title = "You lost";
	dsc = false;
	noparser = true;
}

room {
	nam = 'goodend';
	title = "You win";
	dsc = function() p ("Score: ", score) end;
	noparser = true;
}

Verb { "hang",
	"{noun}/held on {noun}/supporter : PutOn",
}

function init()
	pl.room = 'foyer'
	move('cloak', pl)
	_'cloak':attr 'worn'
end

game.hint_verbs = { "#Exam", "#Walk", "#Take", "#Drop" }
