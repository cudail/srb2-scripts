
--[[
These are the server options available with the default value in square brackets
shownames [on]
showchats [on]
showrings [off]
flashnames [off]
flashrings [on]

These are the player options:
showownname [off]
showbotname [off]
namecolour {colour}

Repalce {colour} with one of red, blue, etc
namecolor is also accepted as a substitute
--]]


local name_colours = {
	pink = V_MAGENTAMAP,
	magenta = V_MAGENTAMAP,
	yellow = V_MAGENTAMAP,
	green = V_GREENMAP,
	blue = V_BLUEMAP,
	red = V_REDMAP,
	grey = V_GRAYMAP,
	gray = V_GRAYMAP,
	orange = V_ORANGEMAP,
	sky = V_SKYMAP,
	cyan = V_SKYMAP,
	purple = V_PURPLEMAP,
	aqua = V_AQUAMAP,
	teal = V_AQUAMAP,
	peridot = V_PERIDOTMAP,
	azure = V_AZUREMAP,
	brown = V_BROWNMAP,
	rosy = V_ROSYMAP,
	rose = V_ROSYMAP,
	black = V_INVERTMAP,
	inverted = V_INVERTMAP
}


local options = {
	shownames = true,
	showchats = true,
	showrings = false,
	flashnames = false,
	flashrings = true,
}


local sorted_players = {}


local split = function(string, delimiter)
	local list = {}
	for token in string.gmatch(string, "[^"..delimiter.."]+") do
		table.insert(list, token)
	end
	return list
end

local break_into_lines = function(view, message, flags)
	local max_width = 120
	local text_lines = {}
	local words = split(message, " ")
	for i, word in pairs(words) do
		local this_line = text_lines[#text_lines]
		if #(text_lines) == 0 then
			text_lines = {word}
		elseif view.stringWidth(this_line .. " " .. word, flags, thin)/2 > max_width then
			table.insert(text_lines, word)
		else
			text_lines[#text_lines] = $1 .. " " .. word
		end
	end
	return text_lines
end


hud.add( function(v, player, camera)
	local first_person = not camera.chase
	local cam = first_person and player.mo or camera
	local hudwidth = 320*FRACUNIT
	local hudheight = (320*v.height()/v.width())*FRACUNIT

	local fov = ANGLE_90 -- Can this be fetched live instead of assumed?

	-- the "distance" the HUD plane is projected from the player
	local hud_distance = FixedDiv(hudwidth / 2, tan(fov/2))

	for _, target_player in pairs(sorted_players) do
		if not target_player.valid or not target_player.mo then continue end
		local tmo = target_player.mo

		if not tmo.valid then continue end
		if not player.showownname and player == target_player then continue end
		if not player.showbotnames and target_player.bot == 1 then continue end

		if not P_CheckSight(player.mo, tmo) then continue end

		-- how far away is the other player?
		local distance = R_PointToDist(tmo.x, tmo.y)

		local distlimit = player.shownamedistance or 1500
		if distance > distlimit*FRACUNIT then continue end

		--Angle between camera vector and target
		local hangdiff = R_PointToAngle2(cam.x, cam.y, tmo.x, tmo.y)
		local hangle = hangdiff - cam.angle

		--check if object is outside of our field of view
		--converting to fixed just to normalise things
		--e.g. this will convert 365° to 5° for us
		local fhanlge = AngleFixed(hangle)
		local fhfov = AngleFixed(fov/2)
		local f360 = AngleFixed(ANGLE_MAX)
		if fhanlge < f360 - fhfov and fhanlge > fhfov then
			continue
		end

		--figure out vertical angle
		local h = FixedHypot(cam.x-tmo.x, cam.y-tmo.y)
		local vangdiff = R_PointToAngle2(0, 0, tmo.z-cam.z+tmo.height+20*FRACUNIT, h) - ANGLE_90
		local vcangle = first_person and player.aiming or cam.aiming or 0
		local vangle = vcangle + vangdiff

		--again just check if we're outside the FOV
		local fvangle = AngleFixed(vangle)
		local fvfov = FixedMul(AngleFixed(fov), FRACUNIT*v.height()/v.width())
		if fvangle < f360 - fvfov and fvangle > fvfov then
			continue
		end

		local hpos = hudwidth/2 - FixedMul(hud_distance, tan(hangle))
		local vpos = hudheight/2 + FixedMul(hud_distance, tan(vangle))

		local name = target_player.name
		local rings = tostring(target_player.rings)

		local namefont = "thin-fixed-center"
		local ringfont = "thin-fixed"
		local charwidth = 5
		local lineheight = 8
		if distance > 500*FRACUNIT then
			namefont = "small-thin-fixed-center"
			ringfont = "small-thin-fixed"
			charwidth = 4
			lineheight = 4
		end

		local flash = (leveltime/(TICRATE/6))%2 == 0
		local rflags = V_SNAPTOLEFT|V_SNAPTOTOP|V_YELLOWMAP
		if flash and options.flashrings and target_player.rings == 0 then
			rflags = V_SNAPTOLEFT|V_SNAPTOTOP|V_REDMAP
		end

		local nameflags = V_SNAPTOLEFT|V_SNAPTOTOP
		if flash and options.flashnames and target_player.rings == 0 then
			if target_player.namecolour ~= V_REDMAP then
				nameflags = $1 | V_REDMAP
			end
		elseif target_player.namecolour then
			nameflags = $1 | target_player.namecolour
		end

		if options.shownames then
			v.drawString(hpos, vpos, name, nameflags, namefont)
		end

		if options.showrings then
			local offset = options.shownames and (#name+2)*charwidth*FRACUNIT/2 or 0
			ringfont = $1 .. (options.shownames and "" or "-center")
			v.drawString(hpos+offset, vpos, rings, rflags, ringfont)
		end

		if not target_player.lastmessagetimer then continue end

		local chat_lifespan = 2*TICRATE
		chat_lifespan = $1 + #target_player.lastmessage * TICRATE / 18

		if options.showchats and target_player.lastmessage
		and leveltime < target_player.lastmessagetimer+chat_lifespan then
			local flags = V_SNAPTOLEFT|V_SNAPTOTOP
			local lines = break_into_lines(v, target_player.lastmessage, flags)
			for i, l in pairs(lines) do
				v.drawString(hpos, vpos+(lineheight*i*FRACUNIT), l, flags, namefont)
			end
		end
	end
end, "game")



addHook("PlayerMsg", function(player, typenum, target, message)
	if typenum ~= 0 then
		return false -- only for normal global messages
	end

	player.lastmessage = message
	player.lastmessagetimer = leveltime
	return false
end)


addHook("PostThinkFrame", function()
	sorted_players = {}
	for player in players.iterate() do
		if player and player.valid and player.mo and player.mo.valid then
			table.insert(sorted_players, player)
		end
	end
	-- This list will be different for every player in a network game
	-- Don't use it for anything other than HUD drawing
	table.sort(sorted_players, function(a, b)
		return R_PointToDist(a.mo.x, a.mo.y) > R_PointToDist(b.mo.x, b.mo.y)
	end)
end)


addHook("MapLoad", function()
	for player in players.iterate() do
		player.lastmessage = nil
		player.lastmessagetimer = nil
	end
end)


addHook("NetVars", function(network)
	options = network($)
end)


--------------------
-- player options --
--------------------
local player_option_toggle = function(option_name, arg, player)
	local current_bool = player[option_name]
	if arg == nil then
		player[option_name] = not $1
	elseif arg == "0" or arg == "off" or arg == "false" then
		player[option_name] = false
	elseif arg == "1" or arg == "on" or arg == "true" then
		player[option_name] = true
	else
		CONS_Printf(player, option_name.." should be called with either 'on', 'off', or no argument")
		return
	end
	CONS_Printf(player, option_name.." has been "..(player[option_name] and "enabled" or "disabled")..".")
end

local set_name_colour = function(player, arg)
	if arg == nil or arg == '' then
		CONS_Printf(player, "set_name_colour error: No colour specified.")
		return
	end

	local colourmap = name_colours[arg]

	if colourmap then
		player.namecolour = colourmap
		CONS_Printf(player, "set_name_colour: Nametag colour changed to "..arg)
	else
		CONS_Printf(player, "set_name_colour error: Unknown name colour '"..arg.."'")
	end
end


COM_AddCommand("namecolour", set_name_colour)
COM_AddCommand("namecolor", set_name_colour)

COM_AddCommand("showownname", function(player, arg)
	player_option_toggle("showownname", arg, player)
end)

COM_AddCommand("showbotnames", function(player, arg)
	player_option_toggle("showbotnames", arg, player)
end)

COM_AddCommand("shownamedistance", function(player, arg)
	if arg == nil then
		CONS_Printf(player, "shownamedistance: Please enter a distance (default: 1500)")
		return
	end

	local dist = tonumber(arg)

	if dist == null then
		CONS_Printf(player, "shownamedistance: Please enter a distance (default: 1500)")
		return
	end

	player.shownamedistance = dist
end)

--------------------
-- server options --
--------------------

local option_toggle = function(option_name, arg, player)
	local current_bool = options[option_name]
	if arg == nil then
		options[option_name] = not $1
	elseif arg == "0" or arg == "off" or arg == "false" then
		options[option_name] = false
	elseif arg == "1" or arg == "on" or arg == "true" then
		options[option_name] = true
	else
		CONS_Printf(player, option_name.." should be called with either 'on', 'off', or no argument")
		return
	end
	CONS_Printf(player, option_name.." has been "..(options[option_name] and "enabled" or "disabled")..".")
end

COM_AddCommand("shownames", function(player, arg)
	option_toggle("shownames", arg, player)
end, COM_ADMIN)

COM_AddCommand("showchats", function(player, arg)
	option_toggle("showchats", arg, player)
end, COM_ADMIN)

COM_AddCommand("showrings", function(player, arg)
	option_toggle("showrings", arg, player)
end, COM_ADMIN)

COM_AddCommand("flashrings", function(player, arg)
	option_toggle("flashrings", arg, player)
end, COM_ADMIN)

COM_AddCommand("flashnames", function(player, arg)
	option_toggle("flashnames", arg, player)
end, COM_ADMIN)
