local R = RailAI;
R.RAI_BotConditions = function(bot)
	if bot.rai.thinktime > 0 then
		bot.rai.thinktime = $ - 1
	end
	if not bot.mo.target return end
	
	if bot.rai.pausetime > 0 then
		bot.rai.pausetime = $ - 1
	end
	if bot.currentweapon == 0  --grenade blacklist
        bot.currentweapon = P_RandomRange(1,6)
	elseif bot.currentweapon == 4 --grenade blacklist
        bot.currentweapon = P_RandomRange(1,6)
	end


	if bot.mo.target.type == MT_PLAYER 
        bot.rai.mode = "attack"
		return true
	elseif bot.mo.target.type ~= MT_PLAYER and bot.mo.target.flags & ~MF_SPRING 
        bot.rai.mode = "conserve"
		return true
	elseif bot.mo.target.flags & MF_SPRING 
        bot.rai.mode = "onspring"
		return true
	end
end