addHook("MobjDamage", function(target, inflictor) 
    local iplayer,tplayer = inflictor.player,target.player
    if iplayer and tplayer and tplayer.railbot
        tplayer.target = nil
        tplayer.rai.mode = "attack"
        tplayer.currentweapon = P_RandomRange(1,6)
        tplayer.rai.lasthit = 0
        return
    end
end)