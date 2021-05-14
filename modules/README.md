# Custom metaparser modules

## hooks

Service module for writing modules. Hook facilities.

## react

react_ and postreact_ event module for reactions near the object.

```
include 'react'
obj {
	nam = 'npc';
	react_Take = "Player in this room is taking something. Reject!";
}:listen();
```

## orders

Experimental module to make orders to NPC.

```
include 'orders'
obj {
	nam = 'npc';
	before_Order = function(s, ev, w, wh)
		p(ev, ' ', w, ' ', wh)
	end
};

> npc take apple
```
