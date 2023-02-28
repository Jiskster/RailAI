--credits in credits.txt

rawset(_G,"RailAI", true)

local makeRailAI = function(bot)
	bot.rail_ai = $ or {
		--Core
		bot.rail_ai.thinktime = 0,
		bot.rail_ai.mode = nil,
		bot.rail_ai.mode2 = nil,
		bot.rail_ai.pausetime = 0,
		bot.rail_ai.forcejumptime = 0,
		bot.rail_ai.forcejumpcooldown = 0

		--Samus
		local randomTurn = P_RandomRange(-50,50)
		bot.sm = randomTurn
		bot.rail_ai.sammorphtime = 0
		bot.rail_ai.samchargetime = 0
		bot.rail_ai.samcharging = false
		bot.rail_ai.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
		bot.rail_ai.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
	}	
end

local FL_LookForEnemy = function(p) -- Flames code modified
	local lastmo
	local dist
	local zdiff
	local lastdist = 0
	local maxdist = 150
	
	for mo in mobjs.iterate()
		
		if mo == p.mo -- 'Ignore us' check
			continue
		end
		if (mo.health <= 0) -- I'm Dead.
			continue
		end
		if (mo.player and mo.player.spectator == true)
			continue
		end
		
		if (mo.z > p.mo.ceilingz)
			continue
		end
		/*
		if (mo.z > p.mo.ceilingz)
			continue
		end
		*/
		if gametyperules & GTR_TEAMS
			if mo.player and p.ctfteam == mo.player.ctfteam
				continue
			end
		end
		-- Ignore anything EXCEPT Crawlas
		if not ((mo.type == MT_BLUECRAWLA)
		or (mo.type == MT_PLAYER) and p.rings > 2
		or (mo.flags & MF_MONITOR and mo.flags & MF_SOLID) --Check if the monitor is solid to prevent bots from targeting destroyed monitors
		or (mo.type == MT_RING and p.mo.eflags & ~MFE_UNDERWATER)
		or (mo.flags & MF_SPRING) and p.panim ~= PA_SPRING
		--Panels
		or (mo.type == MT_BOUNCEPICKUP) or (mo.type == MT_RAILPICKUP)
		or (mo.type == MT_AUTOPICKUP) or (mo.type == MT_EXPLODEPICKUP)
		or (mo.type == MT_SCATTERPICKUP) or (mo.type == MT_GRENADEPICKUP)
		or (mo.type == MT_FLINGRING) --or (mo.floorz == p.mo.floorz)
		
		
		-- ENEMY
		or (mo.flags & MF_ENEMY)
		or (mo.flags & MF_BOSS)
		
		-- RS NEO
		or RingSlinger and (mo.type == MT_RS_AMMO) 
		and (p.mo.ringslinger) and (p.mo.ringslinger.ammo < p.mo.ringslinger.maxammo) --if ammo is not max ammo, target ammo rings
		or (mo.power) and RingSlinger
		

		/*
			MT_BOUNCEPICKUP
			MT_RAILPICKUP
			MT_AUTOPICKUP
			MT_EXPLODEPICKUP
			MT_SCATTERPICKUP
			MT_GRENADEPICKUP
		*/
		
		--or not (mo.flags & MF_SPRING) -- Springs are an exception.
		)
			continue
		end
		
		-- Can't get it if you can't see it!
		if not P_CheckSight(p.mo,mo)
			continue
		end

		dist = P_AproxDistance(P_AproxDistance(p.mo.x - mo.x, p.mo.y - mo.y), p.mo.z - mo.z)
		if (lastmo and (dist > lastdist)) -- Last one is closer to you?
			continue
		end
		if (lastmo and dist < maxdist)
			continue
		end	

		-- Found a target
		lastmo = mo
		lastdist = dist
	end
	return lastmo
end

local ButtonsThink = function(p,cmd) -- Checked
	if p.rail_ai.pausetime > 0 then
		return
	end
	if p.railbot == true then
		-- bot goes pew pew
		if p.rail_ai.mode == "attack" then
			cmd.forwardmove = 50 

			if leveltime % 25*TICRATE --and p.target.player.valid == true then
				cmd.sidemove = p.sm
				cmd.buttons = $|BT_JUMP
			end
			if p.mo and p.mo.valid and p.valid then
				-- Check if the bot is Samus
			    if p.mo.skin == "basesamus" or p.mo.skin == "samus" then
			        --Charge Beam/Super Missile logic
				    if p.sam_chargebeam and p.rail_ai.samchargetime != 80 then
				        if not p.rail_ai.samcharging then
					        p.rail_ai.samchargecooldown = $ - 1
				    	end
				        if p.rail_ai.samchargecooldown <= 0 then
					        --Use Super Missiles when ammo is available, else Charge Beam
					        if p.samsupermissiles > 0
					            cmd.buttons = $|BT_ATTACK
						    else
						        cmd.buttons = $|BT_FIRENORMAL
						    end
					        p.rail_ai.samchargetime = $ + 1
					        p.rail_ai.samcharging = true
					    end
				    elseif p.rail_ai.samchargetime >= 80
					    p.rail_ai.samchargetime = 0
					    p.rail_ai.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
					    p.rail_ai.samcharging = false
				    end
			        -- If Samus, then randomly use missiles when ammo is available, else beam
			        if leveltime % 5*TICRATE == 0 and not p.rail_ai.samcharging then
				        if p.sammissiles > 0 and P_RandomChance(FRACUNIT/5)
				            cmd.buttons = $|BT_ATTACK
					    else
						    cmd.buttons = $|BT_FIRENORMAL
						end
					end
			    else
			        if leveltime % 15*TICRATE == 0 then
				        cmd.buttons = $|BT_ATTACK
			        elseif leveltime % 2*TICRATE == 0 and p.currentweapon == WEP_AUTO --spray and pray baby
				        cmd.buttons = $|BT_ATTACK
					end
				end
			end
			
			if p.blocked == true then
				cmd.sidemove = p.sm
			end
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
		if p.mo and p.mo.valid and p.valid then
		    --Samus-specific logic
		    if p.mo.skin == "basesamus" or p.mo.skin == "samus" then
		        --Helps prevents bots from getting stuck in Morph Ball mode by attempting to unmorph after 5 seconds
		        if p.sammorphed then
			        p.rail_ai.sammorphtime = $ + 1
				    if p.rail_ai.sammorphtime > 175 then
				        cmd.buttons = $|BT_SPIN
				        p.rail_ai.sammorphtime = 0
				    end
			    end
			    --Randomly switch beams every 10-30 seconds (could be improved to make it truly random)
			    if p.rail_ai.samweaponswitchcooldown > 0 then
			        p.rail_ai.samweaponswitchcooldown = $ - 1 then
			        if p.rail_ai.samweaponswitchcooldown <= 0 then
			            p.rail_ai.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
				     if P_RandomChance(FRACUNIT/2) then
				            cmd.buttons = $|BT_WEAPONNEXT
				        else
				            cmd.buttons = $|BT_WEAPONPREV
					    end
				    end
			    end
		    end
		end
	end
end

local AimThink = function(p,cmd)
	if p and p.valid and not p.spectator
		and p.mo and p.mo.valid and p.railbot == true
		--print(p.mo.z/FRACUNIT)
		if p == server -- Server?
			return -- Don't process anything else
		end
		if not p.mo.target -- No target?
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

		if not p.mo.target -- Still no target?
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
		if p.mo.target.z > p.mo.z + p.mo.height
		    p.rail_ai.mode2 = "forcejump"
		end
	end
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

addHook("BotTiccmd", function(player,cmd)
	if not player.railbot
		return false
	end

	if not player.rail_ai
		makeRailAI(player)
	else -- else if the bot already has the .rail_ai
		AimThink(player,cmd)
		ButtonsThink(player,cmd)
		player.botleader = nil
		player.spectator = 0
		if not player.mo then return true end -- Stop here until you get real
		if player.railbot ~= true return true end
		--P_SetObjectMomZ(p.mo, FRACUNIT/-(gravity), true) -- NEEDED FOR GRAVITY
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