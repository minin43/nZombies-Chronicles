-- XP-Tools support added by: Ethorbit
if !Maxwell then return end

if NZDoubleXP == nil then
    NZDoubleXP = false
end

-- XP from records
hook.Add("XPFromRecord", "NZGiveRecordXP", function(ply)
	if !IsValid(ply) then ServerLog("Can't give record XP! ply is nil.") return end
    if Maxwell.XPFromRecords then
        ply:GiveXP(Maxwell.XPAmountFromRecords)
    end
end)

-- XP from zombies
hook.Add("XPFromZombie", "NZGiveZombieXP", function(ply, zombie)
    --if (zombie and zombie.isdead) then return end

    if (IsValid(zombie) and zombie:Health() <= 0 and !zombie.NZBoss) then
        zombie.isdead = true

        if Maxwell.XPFromNPCs then
            ply:GiveXP(Maxwell.XPAmountFromNPCs)
            hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromNPCs)
        end
    end
end)

-- XP from revives
hook.Add("XPFromRevive", "NZGiveReviveXP", function(ply)
    if Maxwell.XPFromReviving then
        ply:GiveXP(Maxwell.XPAmountFromRevives)
        hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromRevives)
    end
end)

-- XP from barrier
hook.Add("XPFromBarrier", "NZGiveBarrierXP", function(ply, barricade)
    -- if ply.XPbarriersPlaced == nil then
    --     ply.XPbarriersPlaced = 1
    -- else
    --     ply.XPbarriersPlaced = ply.XPbarriersPlaced + 1
    -- end

    -- if ply.XPbarriersPlaced >= 60 then return end -- This is a hard limit to avoid infinite XP abusers

    if Maxwell.XPFromBarriers then
        ply:GiveXP(Maxwell.XPAmountFromBarriers)
        hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromBarriers)
    end
end)

-- XP from door
hook.Add("XPFromDoor", "NZGiveDoorXP", function(ply, price)
    if Maxwell.XPFromDoors then
        local xpAmount = math.Round(price / 75)
        if !NZDoubleXP then
            ply:GiveXP(xpAmount)
            hook.Call("XPAddedToPly", nil, ply, xpAmount)
        else
            ply:GiveXP(xpAmount * 2)
            hook.Call("XPAddedToPly", nil, ply, xpAmount * 2)
        end
    end
end)

-- XP from powerup
hook.Add("OnPlayerPickupPowerUp", "NZGivePowerUpXP", function(ply, id)
    if Maxwell.XPFromPowerUps and IsValid(ply) then
        ply:GiveXP(Maxwell.XPAmountFromPowerUps)
        hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromPowerUps)
    end
end)

-- XP from box
hook.Add("OnPlayerBuyBox", "NZGiveBoxXP", function(ply)
    if Maxwell.XPFromBox and IsValid(ply) then
        ply:GiveXP(Maxwell.XPAmountFromBox)
        hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromBox)
    end
end)

-- XP from bosses
hook.Add("EntityTakeDamage", "NZBossXP", function(target, dmginfo)
    local ply = dmginfo:GetAttacker()
    if !IsValid(target) or !IsValid(ply) or !ply:IsPlayer() then return end

    if Maxwell.XPFromBoss then
        if (target.NZBoss) then
            timer.Simple(0.1, function()
                if (IsValid(ply) and IsValid(target) and !target:Alive()) then
                    if (!ply.XPBoss or ply.XPBoss != target) then
                        ply:GiveXP(Maxwell.XPAmountFromBoss)
                        hook.Call("XPAddedToPly", nil, ply, Maxwell.XPAmountFromBoss)
                    end

                    ply.XPBoss = target -- This will prevent them from getting boss XP from the same boss
                end
            end)
        end
    end
end)

util.AddNetworkString("ShowXPGain")
hook.Add("XPAddedToPly", "ShowPlyXP", function(ply, amount)
    if !IsValid(ply) or !amount then return end
    net.Start("ShowXPGain")
    net.WriteInt(amount, 32)
    net.Send(ply)
end)

-- Check if a player unlocked a new level item when they level up:
--local SFXVar = GetConVar("nz_levelup_sound") -- in config/sh_constructor.lua
hook.Add("PlayerLevelUp", "InformPlayerOfNewItem", function(ply, lvl)
    if !IsValid(ply) or !lvl then return end

    --if SFXVar and SFXVar:GetBool() then
    ply:SendLua("surface.PlaySound(\"chron/nz/bo/levels/rank_up.wav\")")
    --end
end)
