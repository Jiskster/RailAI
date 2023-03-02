--Recent function changes
--makeRailAI to RAI_MakeRailAI
--doModeConditions to RAI_BotConditions
local R = RailAI;


local ButtonsThink = function(bot,cmd) -- Checked
	if bot.rai.pausetime > 0 then
		return
	end
	if bot.railbot == true and bot.mo and bot.mo.valid and bot.valid then
		-- bot goes pew pew
		if bot.rai.mode == "attack" then
			cmd.forwardmove = 50 

			if leveltime % 25*TICRATE then
				cmd.sidemove = P_RandomRange(-50,50) -- bot.sm
				cmd.buttons = $|BT_JUMP
			end
			if leveltime % 15*TICRATE == 0 then
				cmd.buttons = $|BT_ATTACK
			elseif leveltime % 2*TICRATE == 0 and bot.currentweapon == WEP_AUTO --spray and pray baby
				cmd.buttons = $|BT_ATTACK
			end
			-- Check if the bot is Samus
			if bot.mo.skin == "basesamus" or bot.mo.skin == "samus" then
				-- samus logic 
				FL_SamusCommands(bot,cmd)
			end
			
			if bot.blocked == true then
				cmd.sidemove = P_RandomRange(-50,50)  -- bot.sm
			end
					
		elseif bot.rai.mode == "conserve" --bot get ring and suff

			cmd.forwardmove = 50 

		elseif bot.rai.mode == "onspring" --when bot get ring!

			cmd.forwardmove = 50
			if bot.panim == PA_RUN and bot.panim ~= PA_ROLL and leveltime % 8*TICRATE == 0 then
				cmd.buttons = $|BT_SPIN
			end

		end

		if bot.rai.mode2 == "forcejump" then
		    if bot.rai.forcejumpcooldown <= 0 then
			    if bot.rai.forcejumptime < 17 then
				    cmd.buttons = $|BT_JUMP
			        bot.rai.forcejumptime = $ + 1
			    elseif bot.rai.forcejumptime >= 17
				    bot.rai.forcejumptime = 0
			        bot.rai.mode2 = nil
				    bot.rai.forcejumpcooldown = 17
				end
			elseif bot.rai.forcejumpcooldown > 0
			    bot.rai.forcejumpcooldown = $ - 1
				bot.rai.mode2 = nil
			end
		elseif bot.rai.mode2 == "forcespin"
			cmd.buttons = $|BT_SPIN
			bot.rai.mode2 = nil
		--Special mode specifically for Samus to make her shoot monitors open
		elseif bot.rai.mode == "samattackmonitor"
			 if leveltime % 5*TICRATE == 0 then
				cmd.buttons = $|BT_FIRENORMAL
				bot.rai.mode = nil
				bot.mo.target = nil
			 end
		end
		if bot.mo and bot.mo.valid and bot.valid and bot.mo.target then
			if abs(bot.mo.momx) > 30*FRACUNIT or abs(bot.mo.momy) > 30*FRACUNIT then
				if bot.mo.target.type == MT_RING and bot.mo.target.type == MT_FLINGRING and not bot.mo.skin == "basesamus" or not bot.mo.skin == "samus" then
					bot.rai.mode2 = "forcespin"
				end
			end
		end
	end
end


local AimThink = function(bot,cmd)
	if bot and bot.valid and not bot.spectator and bot.mo and bot.mo.valid and bot.railbot == true
		--print(bot.mo.z/FRACUNIT)
		if bot == server then -- Server?
			return -- Don't process anything else
		end
		if not bot.mo.target then-- No target?
			bot.mo.target = FL_LookForEnemy(bot) -- Search for one
		elseif bot.mo.target and not P_CheckSight(bot.mo, bot.mo.target) or bot.mo.target.health == 0 -- Lost sight of your target?
			bot.mo.target = nil -- No more target for you.
		elseif bot.mo.target.player and bot.ctfteam == bot.mo.target.player.ctfteam and gametyperules & GTR_TEAMS
			return
		elseif bot.mo.target.health == 0
			bot.mo.target = nil
			return
		elseif bot.blocked == true
			if bot.mo.z > bot.mo.target.z and bot.rai.thinktime == 0
				if bot.mo.target.flags & MF_MONITOR
					if bot.charability2 == CA2_NONE then
						bot.rai.mode2 = "forcespin"
					elseif bot.charability2 ~= CA2_NONE then
						bot.rai.mode2 = "forcejump"
					end
				end
				bot.rai.thinktime = 35*TICRATE	
			else
				bot.mo.target = nil
			end
			return
		/*
		elseif player.mo.eflags & MFE_SPRUNG
			bot.mo.target = nil
			return
			
		*/
		elseif bot.mo.target.player and bot.rings == 0
			bot.mo.target = nil
			return
		elseif (bot.mo.target.flags & MF_SPRING) and (bot.panim == PA_SPRING)
			
			bot.mo.target = nil
			return
		elseif (bot.mo.target.z > bot.mo.ceilingz)
			bot.mo.target = nil
			return
		end

		if not bot.mo.target then -- Still no target?
			return -- Don't process anything else
		end	
		-- From here, assume the player has a target
		local dist, zdiff
		local angle, aimangle	
		dist = R_PointToDist2(bot.mo.x, bot.mo.y, bot.mo.target.x, bot.mo.target.y)
		zdiff = (bot.mo.target.z - bot.mo.z)
		angle = R_PointToAngle2(bot.mo.x, bot.mo.y, bot.mo.target.x, bot.mo.target.y)
		aimangle = R_PointToAngle2(0, 0, dist, zdiff)
		if bot.mo.target.player then
			cmd.angleturn = angle / P_RandomRange(60000,65536) -- jittery aim
			cmd.aiming = aimangle / P_RandomRange(60000,65536)
		else
			cmd.angleturn = angle / 65536 -- jittery aim
			cmd.aiming = aimangle / 65536
		end-- jittery aim
		--Force jump if target needs jumping to reach
		if bot.mo.target.z > bot.mo.z + bot.mo.height then
		    bot.rai.mode2 = "forcejump"
		end
	end
end


addHook("BotTiccmd", function(bot,cmd) --Iterate
	if not bot.railbot
		return false
	end
	if not bot.mo then return true end
	if (not bot.rai)
		R.RAI_MakeRailAI(bot)
	else -- else if the bot already has the .rai
		AimThink(bot,cmd)
		ButtonsThink(bot,cmd)
		bot.botleader = nil
		bot.spectator = 0
			-- Stop here until you get real

		--P_SetObjectMomZ(player.mo, FRACUNIT/-(gravity), true) -- NEEDED FOR GRAVITY
		R.RAI_BotConditions(bot) -- conditions for modes
	end
	return true
end)




