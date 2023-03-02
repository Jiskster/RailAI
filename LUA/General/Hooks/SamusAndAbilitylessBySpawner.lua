addHook("MobjCollide", function(t, tm)
	if tm.player and tm.player.railbot == true
		if t.flags & MF_MONITOR
			if tm.player.mo.skin == "basesamus" or tm.player.mo.skin == "samus"
                 tm.player.rai.mode = "samattackmonitor"
			else	
			    if tm.player.charability2 == CA2_NONE then
				    tm.player.rai.mode2 = "forcespin"
			    elseif tm.player.charability2 ~= CA2_NONE then
				    tm.player.rai.mode2 = "forcejump"
				end
			end
		end
	end
end)

--fixing paths later