rawset(_G,"FL_SamusCommands", function(p,cmd)
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
            p.rail_ai.samweaponswitchcooldown = $ - 1
            if p.rail_ai.samweaponswitchcooldown <= 0 then
                p.rail_ai.samweaponswitchcooldown = P_RandomRange(TICRATE*10, TICRATE*30)
             if P_RandomChance(FRACUNIT/2) then
                    cmd.buttons = $|BT_WEAPONNEXT
                else
                    cmd.buttons = $|BT_WEAPONPREV
                end
            end
        end
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
    end
end)