--credits in credits.txt

rawset(_G,"RailAI", true)
rawset(_G,"RAI_cyclingBots", CV_RegisterVar{
	name = "botcycling",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})

local makeRailAI = function(bot)
	local randomTurn = P_RandomRange(-50,50)
	bot.rail_ai = {}
	--Core
	bot.rail_ai.thinktime = 0
	bot.rail_ai.mode = nil
	bot.rail_ai.mode2 = nil
	bot.rail_ai.pausetime = 0
	bot.rail_ai.forcejumptime = 0
	bot.rail_ai.forcejumpcooldown = 0
	bot.rail_ai.lasthit = 0
	--Samus
	bot.sm = randomTurn
	bot.rail_ai.sammorphtime = 0
	bot.rail_ai.samchargetime = 0
	bot.rail_ai.samcharging = false
	bot.rail_ai.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
	bot.rail_ai.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
end

local doModeConditions = function(player)
	if player.rail_ai.thinktime > 0 then
		player.rail_ai.thinktime = $ - 1
	end
	if not player.mo.target return end
	
	if player.rail_ai.pausetime > 0 then
		player.rail_ai.pausetime = $ - 1
	end
	if player.currentweapon == 0  --grenade blacklist
		player.currentweapon = P_RandomRange(1,6)
	elseif player.currentweapon == 4 --grenade blacklist
		player.currentweapon = P_RandomRange(1,6)
	end
	if player.mo.target.type == MT_PLAYER 
		player.rail_ai.mode = "attack"
		return true
	elseif player.mo.target.type ~= MT_PLAYER and player.mo.target.flags & ~MF_SPRING 
		player.rail_ai.mode = "conserve"
		return true
	elseif player.mo.target.flags & MF_SPRING 
		player.rail_ai.mode = "onspring"
		return true
	end
end

local ButtonsThink = function(p,cmd) -- Checked
	if p.rail_ai.pausetime > 0 then
		return
	end
	if p.railbot == true and p.mo and p.mo.valid and p.valid then
		-- bot goes pew pew
		if p.rail_ai.mode == "attack" then
			cmd.forwardmove = 50 

			if leveltime % 25*TICRATE --and p.target.player.valid == true then
				cmd.sidemove = p.sm
				cmd.buttons = $|BT_JUMP
			end
			if leveltime % 15*TICRATE == 0 then
				cmd.buttons = $|BT_ATTACK
			elseif leveltime % 2*TICRATE == 0 and p.currentweapon == WEP_AUTO --spray and pray baby
				cmd.buttons = $|BT_ATTACK
			end
			-- Check if the bot is Samus
			if p.mo.skin == "basesamus" or p.mo.skin == "samus" then
				
			end
			
			if p.blocked == true then
				cmd.sidemove = p.sm
			end
			-- samus logic 
			FL_SamusCommands(p,cmd)
		elseif p.rail_ai.mode == "conserve" --bot get ring and suff

			cmd.forwardmove = 50 

		elseif p.rail_ai.mode == "onspring" --when bot get ring!

			cmd.forwardmove = 50
			if p.panim == PA_RUN and p.panim ~= PA_ROLL and leveltime % 8*TICRATE == 0 then
				cmd.buttons = $|BT_SPIN
			end

		end

		if p.rail_ai.mode2 == "forcejump" then
		    if p.rail_ai.forcejumpcooldown <= 0 then
			    if p.rail_ai.forcejumptime < 17 then
				    cmd.buttons = $|BT_JUMP
			        p.rail_ai.forcejumptime = $ + 1
			    elseif p.rail_ai.forcejumptime >= 17
				    p.rail_ai.forcejumptime = 0
			        p.rail_ai.mode2 = nil
				    p.rail_ai.forcejumpcooldown = 17
				end
			elseif p.rail_ai.forcejumpcooldown > 0
			    p.rail_ai.forcejumpcooldown = $ - 1
				p.rail_ai.mode2 = nil
			end
		elseif p.rail_ai.mode2 == "forcespin"
			cmd.buttons = $|BT_SPIN
			p.rail_ai.mode2 = nil
		--Special mode specifically for Samus to make her shoot monitors open
		elseif p.rail_ai.mode == "samattackmonitor"
			 if leveltime % 5*TICRATE == 0 then
				cmd.buttons = $|BT_FIRENORMAL
				p.rail_ai.mode = nil
				p.mo.target = nil
			 end
		end
		if p.mo and p.mo.valid and p.valid and p.mo.target then
			if abs(p.mo.momx) > 30*FRACUNIT or abs(p.mo.momy) > 30*FRACUNIT then
				if p.mo.target.type == MT_RING and p.mo.target.type == MT_FLINGRING and not p.mo.skin == "basesamus" or not p.mo.skin == "samus" then
					p.rail_ai.mode2 = "forcespin"
				end
			end
		end
	end
end

local AimThink = function(p,cmd)
	if p and p.valid and not p.spectator
		and p.mo and p.mo.valid and p.railbot == true
		--print(p.mo.z/FRACUNIT)
		if p == server then -- Server?
			return -- Don't process anything else
		end
		if not p.mo.target then-- No target?
			p.mo.target = FL_LookForEnemy(p) -- Search for one
		elseif p.mo.target and not P_CheckSight(p.mo, p.mo.target) or p.mo.target.health == 0 -- Lost sight of your target?
			p.mo.target = nil -- No more target for you.
		elseif p.mo.target.player and p.ctfteam == p.mo.target.player.ctfteam and gametyperules & GTR_TEAMS
			return
		elseif p.mo.target.health == 0
			p.mo.target = nil
			return
		elseif p.blocked == true
			if p.mo.z > p.mo.target.z and p.rail_ai.thinktime == 0
				if p.mo.target.flags & MF_MONITOR
					if p.charability2 == CA2_NONE then
						p.rail_ai.mode2 = "forcespin"
					elseif p.charability2 ~= CA2_NONE then
						p.rail_ai.mode2 = "forcejump"
					end
				end
				p.rail_ai.thinktime = 35*TICRATE	
			else
				p.mo.target = nil
			end
			return
		/*
		elseif player.mo.eflags & MFE_SPRUNG
			p.mo.target = nil
			return
			
		*/
		elseif p.mo.target.player and p.rings == 0
			p.mo.target = nil
			return
		elseif (p.mo.target.flags & MF_SPRING) and (p.panim == PA_SPRING)
			
			p.mo.target = nil
			return
		elseif (p.mo.target.z > p.mo.ceilingz)
			p.mo.target = nil
			return
		end

		if not p.mo.target then -- Still no target?
			return -- Don't process anything else
		end

		
		
		-- From here, assume the player has a target
		local dist, zdiff
		local angle, aimangle
		
		-- Calculate your target's distance
		--dist = P_AproxDistance(P_AproxDistance(
		--p.mo.target.x - p.mo.x,
		--p.mo.target.y - p.mo.y),
		--p.mo.target.z - p.mo.z)
		
		dist = R_PointToDist2(p.mo.x, p.mo.y, p.mo.target.x, p.mo.target.y)
		zdiff = (p.mo.target.z - p.mo.z)
		
		-- Point at your target
		--angle = R_PointToAngle2(p.mo.target.x, p.mo.target.y, p.mo.x, p.mo.y) -- For inverse angle
		
		-- Aim at your target
		--aimangle = FixedAngle(InvAngle(FixedDiv(zdiff, dist))) -- Calculate your cotangent
		angle = R_PointToAngle2(p.mo.x, p.mo.y, p.mo.target.x, p.mo.target.y)
		aimangle = R_PointToAngle2(0, 0, dist, zdiff)
		if p.mo.target.player then
			cmd.angleturn = angle / P_RandomRange(60000,65536) -- jittery aim
			cmd.aiming = aimangle / P_RandomRange(60000,65536)
		else
			cmd.angleturn = angle / 65536 -- jittery aim
			cmd.aiming = aimangle / 65536
		end-- jittery aim
		--Force jump if target needs jumping to reach
		if p.mo.target.z > p.mo.z + p.mo.height then
		    p.rail_ai.mode2 = "forcejump"
		end
	end
end



addHook("BotTiccmd", function(player,cmd) --Iterate
	if not player.railbot
		return false
	end

	if (not player.rail_ai)
		makeRailAI(player)
	else -- else if the bot already has the .rail_ai
		if not player.mo then return true end
		AimThink(player,cmd)
		ButtonsThink(player,cmd)
		player.botleader = nil
		player.spectator = 0
			-- Stop here until you get real
		--P_SetObjectMomZ(player.mo, FRACUNIT/-(gravity), true) -- NEEDED FOR GRAVITY
		doModeConditions(player) -- conditions for modes
	end
	return true
end)

addHook("MobjDamage", function(target, inflictor) 
	local iplayer,tplayer = inflictor.player,target.player
	if iplayer and tplayer and tplayer.railbot
		tplayer.target = nil
		tplayer.rail_ai.mode = "attack"
		tplayer.currentweapon = P_RandomRange(1,6)
		local r = P_RandomRange(-50,50)
		tplayer.lasthit = 0
		tplayer.sm = r
		return
	end
end)

addHook("MobjCollide", function(t, tm)
	if tm.player and tm.player.railbot == true
		if t.flags & MF_MONITOR
			if tm.player.mo.skin == "basesamus" or tm.player.mo.skin == "samus"
                 tm.player.rail_ai.mode = "samattackmonitor"
			else	
			    if tm.player.charability2 == CA2_NONE then
				    tm.player.rail_ai.mode2 = "forcespin"
			    elseif tm.player.charability2 ~= CA2_NONE then
				    tm.player.rail_ai.mode2 = "forcejump"
				end
			end
		end
	end
end)