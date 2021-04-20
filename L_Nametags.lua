
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


local chat_lifespan = 5*TICRATE

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
	if arg == nil then
		player.showownname = not player.showownname
	elseif arg == "on" or arg == "1" then
		player.showownname = true
	elseif arg == "off" or arg =="0" then
		player.showownname = false
	else
		CONS_Printf(player, "showownname should be called with either 'on', 'off', or no argument")
		return
	end
	CONS_Printf(player, "showownname has been "..(player.showownname and "enabled" or "disabled")..".")
end)



hud.add( function(v, player, camera)
	local first_person = not camera.chase
	local cam = first_person and player.mo or camera
	local hudwidth = 320*FRACUNIT
	local hudheight = (320*v.height()/v.width())*FRACUNIT

	local fov = ANGLE_90 -- Can this be fetched live instead of assumed?

	-- the "distance" the HUD plane is projected from the player
	local hud_distance = FixedDiv(hudwidth / 2, tan(fov/2))

	for target_player in players.iterate() do
		local tmo = target_player.mo

		if not tmo.valid then continue end
		if player == target_player and not player.showownname then continue end
		if not P_CheckSight(player.mo, tmo) then continue end

		-- how far away is the other player?
		local distance = R_PointToDist(tmo.x, tmo.y)
		if distance > 1500*FRACUNIT then continue end

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
		if distance > 500*FRACUNIT then
			namefont = "small-thin-fixed-center"
			ringfont = "small-thin-fixed"
			charwidth = 4
		end

		local rflags = V_SNAPTOLEFT|V_SNAPTOTOP|V_YELLOWMAP
		if target_player.rings == 0 then
			rflags = V_SNAPTOLEFT|V_SNAPTOTOP|V_REDMAP
		end

		local nameflags = V_SNAPTOLEFT|V_SNAPTOTOP
		if player.namecolour then
			nameflags = $1 | player.namecolour
		end

		v.drawString(hpos, vpos, name, nameflags, namefont)
		v.drawString(hpos+(#name+2)*charwidth*FRACUNIT/2, vpos, rings, rflags, ringfont)
		if player.lastmessage and leveltime < player.lastmessagetimer+chat_lifespan then
			v.drawString(hpos, vpos+8*FRACUNIT, player.lastmessage, V_SNAPTOLEFT|V_SNAPTOTOP, namefont)
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
