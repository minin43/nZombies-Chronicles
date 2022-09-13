if SERVER then
    util.AddNetworkString("UpdateIndividualGunStat")

    --//WepClass is weapon class name, stat is the SWEP stat to change, value is the value to multiply by, ply is the targeted player
    function SendPlayerGunUpdate(wepClass, stat, value, ply)
        net.Start("UpdateIndividualGunStat")
            net.WriteString(wepClass)
            net.WriteString(stat)
            net.WriteFloat(value)
        net.Send(ply)
    end
    function SendPlayerAllGunUpdates(stat, value, ply)
        for k, v in pairs(ply:GetWeapons()) do
            SetTfaWeaponStat(v, stat, value)
            SendPlayerGunUpdate(v:GetClass(), stat, value, ply)
        end
    end

    GAMEMODE.DeadshotMonitoring = {}
    local wepValue = "Spread"
    local amount = 0.5

    hook.Add("OnPlayerGetPerk", "PlayerBuysDeadshot", function(ply, perkId, machineEnt)
        if perkId == "deadshot" then
            GAMEMODE.DeadshotMonitoring[ply] = {}

            SendPlayerAllGunUpdates(wepValue, amount, ply)
        end
    end)

    hook.Add("OnPlayerLostPerk", "PlayerLosesDeadshot", function(ply, perkId, machineEnt)
        if perkId == "deadshot" then
            GAMEMODE.DeadshotMonitoring[ply] = nil
            
            SendPlayerAllGunUpdates(wepValue, amount * 4, ply)
        end
    end)

    hook.Add("WeaponEquip", "DeadshotNewWeaponEquipped", function(wep, ply)
        if ply:HasPerk("deadshot") and GAMEMODE.DeadshotMonitoring[ply] then
            table.insert(GAMEMODE.DeadshotMonitoring[ply], wep:GetClass(), true)

            SetTfaWeaponStat(wep, wepValue, amount)
            SendPlayerGunUpdate(wep:GetClass(), wepValue, amount, ply)
        end
    end)
else
    net.Receive("UpdateIndividualGunStat", function()
        local wepClass = new.ReadString()
        local stat = net.ReadString()
        local value = net.ReadFloat()

        local wep = LocalPlayer():GetWeapon(wepClass)
        if wep and wep:IsValid() then
            SetTfaWeaponStat(wep, stat, value)
        end
    end)
end

--//Val is treated as a multiplier
function SetTfaWeaponStat(wep, stat, val)
    if wep.Base == "tfa_gun_base" then
        if wep["Primary"][stat] then
            wep["Primary"][stat] = wep["Primary"][stat] * val
        else
            wep[stat] = wep[stat] * val
        end
    end
end