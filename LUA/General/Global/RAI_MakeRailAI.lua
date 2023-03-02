local R = RailAI;
R.RAI_MakeRailAI = function(bot)
	bot.rai = {}
	--Core
	bot.rai.thinktime = 0
	bot.rai.mode = nil
	bot.rai.mode2 = nil
	bot.rai.pausetime = 0
	bot.rai.forcejumptime = 0
	bot.rai.forcejumpcooldown = 0
	bot.rai.lasthit = 0
	--Samus
	
	bot.rai.sammorphtime = 0
	bot.rai.samchargetime = 0
	bot.rai.samcharging = false
	bot.rai.samchargecooldown = P_RandomRange(TICRATE*2, TICRATE*5)
	bot.rai.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
end
