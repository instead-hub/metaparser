function blur(p, r, g, b)
	local w, h = p:size()
	local cell = function(x, y)
		if x < 0 or x >= w or y < 0 or y >= h then
			return 0
		end
		local r, g, b, a = p:val(x, y)
		return a
	end
	for y = 0, h  do
		for x = 0, w do
			local c1, c2, c3, c4, c5, c6, c7, c8, c9 =
				cell(x - 1, y - 1),
				cell(x, y - 1),
				cell(x + 1, y - 1),
				cell(x - 1, y),
				cell(x, y),
				cell(x + 1, y),
				cell(x - 1, y + 1),
				cell(x, y + 1),
				cell(x + 1, y + 1)
			local c = (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9) / 9
			p:val(x, y, r, g, b, math.floor(c))
		end
	end
end

local function clamp( x, min, max )
	if x < min then return min end
	if x > max then return max end
	return x
end

local function KtoRGB(kelvin)
	local temp = kelvin / 100

	local red, green, blue

	if temp <= 66 then 
		red = 255
		green = temp
		green = 99.4708025861 * math.log(green) - 161.1195681661
		if temp <= 19 then
			blue = 0
		else
			blue = temp - 10
			blue = 138.5177312231 * math.log(blue) - 305.0447927307
		end
	else
		red = temp - 60
		red = 329.698727446 * math.pow(red, -0.1332047592)
		green = temp - 60
		green = 288.1221695283 * math.pow(green, -0.0755148492 )
		blue = 255
	end
	return clamp(red, 0, 255), clamp(green, 0, 255), clamp(blue,  0, 255)
end

local star_col = function()
	local r, g, b = KtoRGB(rnd(20000) + 2000)
	return r, g, b, 255
end

declare 'star_spr' (function(v)
	local p = pixels.new(5, 5)
	local x, y = 2, 2
	local r, g, b = star_col()
	p:val(x, y, r, g, b, 255)
	for i = 1, rnd(2) do
		local w = rnd(3)
		p:fill(x, y, w, w, r, g, b, 255)
		x = x + rnd(3) - 2
		y = x + rnd(3) - 2
	end
	blur(p, r, g, b)
	return p:sprite()
end)

declare 'small_star_spr' (function(v)
	local p = pixels.new(3, 3)
	local x, y = 1, 1
	local r, g, b = star_col()
	p:val(x, y, r, g, b,255)
	p:val(x + 1, y + 1, r, g, b,255)
	blur(p, r, g, b)
	return p:sprite()
end)

const 'STARS' (100)

function make_stars(proc)
	for i = 1, STARS do
		if i > STARS / 2 then
			D {"star"..tostring(i), 'img', small_star_spr, speed = rnd(2), process = proc, x = rnd(theme.scr.w()), y = rnd(theme.scr.h()), z = 10 }
		else
			D {"star"..tostring(i), 'img', star_spr, speed = rnd(2), process = proc, x = rnd(theme.scr.w()), y = rnd(theme.scr.h()), z = 10 }
		end
	end
end
