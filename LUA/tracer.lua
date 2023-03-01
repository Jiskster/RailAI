addHook("PlayerSpawn", function(player) --spawn tracer
    if player.mo and player.mo.valid and player.railbot then
        local tk = P_SpawnMobj(player.mo.x,player.mo.y,player.mo.z,MT_UNKNOWN)
        tk.master = player.mo
        player.mo.pawn = tk
        local master = tk.master
        local aim_x = master.x + cos(master.angle) * (50*FRACUNIT)
        local aim_y = master.y + sin(master.angle) * (50*FRACUNIT)
        P_TeleportMove(tk, aim_x, aim_y, master.z)
    end
end)


addHook("MobjThinker",function(mobj) --angle the tracer
    if mobj.master and mobj.valid and mobj.master.valid then
        local master = mobj.master
        local aim_x = master.x + cos(master.angle) * (150)
        local aim_y = master.y + sin(master.angle) * (150)
        P_TeleportMove(mobj, aim_x, aim_y, master.z)
        master.canSeeTracer = P_CheckSight(mobj, master)
        master.overCliff = mobj.floorz < master.floorz
        --print(P_CheckSight(mobj, master))
        mobj.sprite =  SPR_NULL -- SPR_SHLL for visible
        
    end
end)


addHook("PreThinkFrame", function() --jump commands
    for player in players.iterate do
        if player.mo and player.mo.valid then 
            if (leveltime % 50) == 0 then
                player.mo.canSeeTracer = true
            end
            if player.mo.canSeeTracer == false or player.mo.overCliff == true then
                //print(1)
                player.cmd.buttons = $|BT_JUMP
            end
        end
    end
end)