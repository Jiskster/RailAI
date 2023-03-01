
rawset(_G,"FL_LookForEnemy", function(p) -- Flames Aim code modified
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
		-- checks
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
		--Emeralds
		or (mo.type == 
        (MT_EMERALD1 or MT_EMERALD2 or MT_EMERALD3 or MT_EMERALD4 or MT_EMERALD5 or MT_EMERALD6 or MT_EMERALD7))
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
end)
