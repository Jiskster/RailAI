//credits in credits.txt
rawset(_G,"RailAi", true)
local function FL_LookForEnemy(p) -- Flames code modified
	local lastmo
	local dist
	local zdiff
	local lastdist = 0
	local maxdist = 150
	
	for mo in mobjs.iterate()
		
		if mo == p.mo // 'Ignore us' check
			continue
		end
		if (mo.health <= 0) // I'm Dead.
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
		// Ignore anything EXCEPT Crawlas
		if not ((mo.type == MT_BLUECRAWLA)
		or (mo.type == MT_PLAYER) and p.rings > 2
		or (mo.flags & MF_MONITOR and mo.flags & MF_SOLID) //Check if the monitor is solid to prevent bots from targeting destroyed monitors
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
		
		//or not (mo.flags & MF_SPRING) // Springs are an exception.
		)
			continue
		end
		
		// Can't get it if you can't see it!
		if not P_CheckSight(p.mo,mo)
			continue
		end

		dist = P_AproxDistance(P_AproxDistance(p.mo.x - mo.x, p.mo.y - mo.y), p.mo.z - mo.z)
		if (lastmo and (dist > lastdist)) // Last one is closer to you?
			continue
		end
		if (lastmo and dist < maxdist)
			continue
		end	

		// Found a target
		lastmo = mo
		lastdist = dist
	end
	return lastmo
end

local function ButtonsThink(p,cmd)
	if p.ai_rail.pausetime > 0 then
		return
	end
	if p.railbot == true
		--bot goes pew pew
		if p.ai_rail.mode == "attack"
			cmd.forwardmove = 50 

			if leveltime % 25*TICRATE //and p.target.player.valid == true
				cmd.sidemove = p.sm
				cmd.buttons = $|BT_JUMP
			end
			if p.mo and p.mo.valid and p.valid
				//Check if the bot is Samus
			    if p.mo.skin == "basesamus" or p.mo.skin == "samus"
			        //Charge Beam/Super Missile logic
				    if p.sam_chargebeam and p.ai_rail.samchargetime != 80
				        if not p.ai_rail.samcharging
					        p.ai_rail.samchargecooldown = $ - 1
				    	end
				        if p.ai_rail.samchargecooldown <= 0
					        //Use Super Missiles when ammo is available, else Charge Beam
					        if p.samsupermissiles > 0
					            cmd.buttons = $|BT_ATTACK
						    else
						        cmd.buttons = $|BT_FIRENORMAL
						    end
					        p.ai_rail.samchargetime = $ + 1
					        p.ai_rail.samcharging = true
					    end
				    elseif p.ai_rail.samchargetime >= 80
					    p.ai_rail.samchargetime = 0
					    p.ai_rail.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
					    p.ai_rail.samcharging = false
				    end
			        // If Samus, then randomly use missiles when ammo is available, else beam
			        if leveltime % 5*TICRATE == 0 and not p.ai_rail.samcharging
				        if p.sammissiles > 0 and P_RandomChance(FRACUNIT/5)
				            cmd.buttons = $|BT_ATTACK
					    else
						    cmd.buttons = $|BT_FIRENORMAL
						end
					end
			    else
			        if leveltime % 15*TICRATE == 0
				        cmd.buttons = $|BT_ATTACK
			        elseif leveltime % 2*TICRATE == 0 and p.currentweapon == WEP_AUTO --spray and pray baby
				        cmd.buttons = $|BT_ATTACK
					end
				end
			end
			
			if p.blocked == true
				cmd.sidemove = p.sm
			end
		elseif p.ai_rail.mode == "conserve" --bot get ring and suff
			cmd.forwardmove = 50 
		elseif p.ai_rail.mode == "onspring" --when bot get ring!
			cmd.forwardmove = 50
			if p.panim == PA_RUN and p.panim ~= PA_ROLL and leveltime % 8*TICRATE == 0
				cmd.buttons = $|BT_SPIN
			end
		end

		if p.ai_rail.mode2 == "forcejump"
		    if p.ai_rail.forcejumpcooldown <= 0
			    if p.ai_rail.forcejumptime < 17
				    cmd.buttons = $|BT_JUMP
			        p.ai_rail.forcejumptime = $ + 1
			    elseif p.ai_rail.forcejumptime >= 17
				    p.ai_rail.forcejumptime = 0
			        p.ai_rail.mode2 = nil
				    p.ai_rail.forcejumpcooldown = 17
				end
			elseif p.ai_rail.forcejumpcooldown > 0
			    p.ai_rail.forcejumpcooldown = $ - 1
				p.ai_rail.mode2 = nil
			end
		elseif p.ai_rail.mode2 == "forcespin"
			cmd.buttons = $|BT_SPIN
			p.ai_rail.mode2 = nil
		//Special mode specifically for Samus to make her shoot monitors open
		elseif p.ai_rail.mode == "samattackmonitor"
			 if leveltime % 5*TICRATE == 0
				cmd.buttons = $|BT_FIRENORMAL
				p.ai_rail.mode = nil
				p.mo.target = nil
			 end
		end
		if p.mo and p.mo.valid and p.valid and p.mo.target then
			if abs(p.mo.momx) > 30*FRACUNIT or abs(p.mo.momy) > 30*FRACUNIT then
				if p.mo.target.type == MT_RING and p.mo.target.type == MT_FLINGRING and not p.mo.skin == "basesamus" or not p.mo.skin == "samus"
					p.ai_rail.mode2 = "forcespin"
				end
			end
		end
		if p.mo and p.mo.valid and p.valid
		    //Samus-specific logic
		    if p.mo.skin == "basesamus" or p.mo.skin == "samus"
		        //Helps prevents bots from getting stuck in Morph Ball mode by attempting to unmorph after 5 seconds
		        if p.sammorphed
			        p.ai_rail.sammorphtime = $ + 1
				    if p.ai_rail.sammorphtime > 175
				        cmd.buttons = $|BT_SPIN
				        p.ai_rail.sammorphtime = 0
				    end
			    end
			    //Randomly switch beams every 10-30 seconds (could be improved to make it truly random)
			    if p.ai_rail.samweaponswitchcooldown > 0
			        p.ai_rail.samweaponswitchcooldown = $ - 1
			        if p.ai_rail.samweaponswitchcooldown <= 0
			            p.ai_rail.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
				     if P_RandomChance(FRACUNIT/2)
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

local function AimThink(p,cmd)
	if p and p.valid and not p.spectator
		and p.mo and p.mo.valid and p.railbot == true
		//print(p.mo.z/FRACUNIT)
		if p == server // Server?
			return // Don't process anything else
		end
		if not p.mo.target // No target?
			p.mo.target = FL_LookForEnemy(p) // Search for one
		elseif p.mo.target and not P_CheckSight(p.mo, p.mo.target) or p.mo.target.health == 0 // Lost sight of your target?
			p.mo.target = nil // No more target for you.
		elseif p.mo.target.player and p.ctfteam == p.mo.target.player.ctfteam and gametyperules & GTR_TEAMS
			return
		elseif p.mo.target.health == 0
			p.mo.target = nil
			return
		elseif p.blocked == true
			if p.mo.z > p.mo.target.z and p.ai_rail.thinktime == 0
				if p.mo.target.flags & MF_MONITOR
					if p.charability2 == CA2_NONE then
						p.ai_rail.mode2 = "forcespin"
					elseif p.charability2 ~= CA2_NONE then
						p.ai_rail.mode2 = "forcejump"
					end
				end
				p.ai_rail.thinktime = 35*TICRATE	
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

		if not p.mo.target // Still no target?
			return // Don't process anything else
		end

		
		
		// From here, assume the player has a target
		local dist, zdiff
		local angle, aimangle
		
		// Calculate your target's distance
		--dist = P_AproxDistance(P_AproxDistance(
		--p.mo.target.x - p.mo.x,
		--p.mo.target.y - p.mo.y),
		--p.mo.target.z - p.mo.z)
		
		dist = R_PointToDist2(p.mo.x, p.mo.y, p.mo.target.x, p.mo.target.y)
		zdiff = (p.mo.target.z - p.mo.z)
		
		// Point at your target
		//angle = R_PointToAngle2(p.mo.target.x, p.mo.target.y, p.mo.x, p.mo.y) -- For inverse angle
		
		
		
		// Aim at your target
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
		//Force jump if target needs jumping to reach
		if p.mo.target.z > p.mo.z + p.mo.height
		    p.ai_rail.mode2 = "forcejump"
		end
	end
end

addHook("BotTiccmd", function(p,cmd)
	if not p.railbot
		return false
	end
	
	if not p.ai_rail
		p.ai_rail = {}
		p.ai_rail.thinktime = 0
		p.ai_rail.mode = nil
		p.ai_rail.mode2 = nil
		p.ai_rail.pausetime = 0
		p.ai_rail.forcejumptime = 0
		p.ai_rail.forcejumpcooldown = 0
		local r = P_RandomRange(-50,50)
		p.sm = r
		p.ai_rail.sammorphtime = 0
		p.ai_rail.samchargetime = 0
		p.ai_rail.samcharging = false
		p.ai_rail.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
		p.ai_rail.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
	else
		AimThink(p,cmd)
		ButtonsThink(p,cmd)
		p.botleader = nil
		if not p.mo then return true end // stop here buddy until r e a l
		p.spectator = 0
		// Mode Conditions Start
		if p.railbot ~= true return end
		--P_SetObjectMomZ(p.mo, FRACUNIT/-(gravity), true)
		if p.ai_rail.thinktime > 0 then
			p.ai_rail.thinktime = $ - 1
		end
		if not p.mo.target return end
		
		if p.ai_rail.pausetime > 0 then
			p.ai_rail.pausetime = $ - 1
		end
		if p.currentweapon == 0  //grenade blacklist
			p.currentweapon = P_RandomRange(1,6)
		elseif p.currentweapon == 4 //grenade blacklist
			p.currentweapon = P_RandomRange(1,6)
		end
		if p.mo.target.type == MT_PLAYER //and p.mode == "conserve" //or p.rings > 5 and mo.type == MT_PLAYER
			p.ai_rail.mode = "attack"
			return true
		elseif p.mo.target.type ~= MT_PLAYER and p.mo.target.flags & ~MF_SPRING //and p.mode == "attack" //or p.rings <= 4 and mo.type ~= MT_PLAYER
			p.ai_rail.mode = "conserve"
			return true
		elseif p.mo.target.flags & MF_SPRING 
			p.ai_rail.mode = "onspring"
			return true
		end
		//Mode Conditions End		
	end
	return true
end)


addHook("MobjDamage", function(target, inflictor) 
	local iplayer,tplayer = inflictor.player,target.player
	if iplayer and tplayer and tplayer.railbot
		tplayer.target = nil
		tplayer.ai_rail.mode = "attack"
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
                 tm.player.ai_rail.mode = "samattackmonitor"
			else	
			    if tm.player.charability2 == CA2_NONE then
				    tm.player.ai_rail.mode2 = "forcespin"
			    elseif tm.player.charability2 ~= CA2_NONE then
				    tm.player.ai_rail.mode2 = "forcejump"
				end
			end
		end
	end
end)