-- TODOs:
-- Flash ringcount when zero
-- Don't draw own name
-- Don't draw bot name
-- Draw life count
-- Options:
--   Toggle names
--   Toggle ring count
--   Toggle life count

hud.add( function(v, player, camera)
	local first_person = not camera.chase
	local cam = first_person and player.mo or camera
	local hudwidth = 320*FRACUNIT
	local hudheight = (320*v.height()/v.width())*FRACUNIT

	local fov = ANGLE_90 -- Can this be fetched live instead of assumed?

	-- the "distance" the HUD plane is projected from the player
	local distance = FixedDiv(hudwidth / 2, tan(fov/2))

	for target_player in players.iterate() do
		local tmo = target_player.mo
		if tmo.valid then

			if not P_CheckSight(player.mo, tmo) then continue end

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

			local hpos = hudwidth/2 - FixedMul(distance, tan(hangle))
			local vpos = hudheight/2 + FixedMul(distance, tan(vangle))

			local name = target_player.name
			local rings = tostring(target_player.rings)

			local namefont = "thin-fixed-center"
			local ringfont = "thin-fixed"
			local charwidth = 5
			if R_PointToDist(tmo.x, tmo.y) > 1000*FRACUNIT then
				namefont = "small-thin-fixed-center"
				ringfont = "small-thin-fixed"
				charwidth = 4
			end

			v.drawString(hpos, vpos, name, V_SNAPTOLEFT|V_SNAPTOTOP, namefont)
			v.drawString(hpos+(#name+2)*charwidth*FRACUNIT/2, vpos, rings, V_SNAPTOLEFT|V_SNAPTOTOP|V_YELLOWMAP, ringfont)
		end
	end
end, "game")
