-- XP-Tools support added by: Ethorbit
if !Maxwell then return end

-- XP Gain
local nextstreak = 0 -- This amount for another streak to occur
local streaks = 0 -- The higher the amount, the crazier the XP counter gets. (Can change size/colors and shake)
surface.CreateFont( "XPVisualFont", {
	font = "ChatFont",
	extended = false,
	size = 50,
	weight = 1500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local showXPGain = false
--local xpCvar = CreateClientConVar("cl_xp_show", "1", true, false, "Show/Hide the visuals that display on screen when you earn XP.")
local xpCvar = GetConVar("nz_xp_visuals") -- Inside config/sh_constructor.lua

local xpTime = 0 -- The duration of the XP visual
local currentXPAmount = 0 -- The amount currently being displayed to the player

net.Receive("ShowXPGain", function()
    local amount = net.ReadInt(32)
    xpTime = CurTime() + 3
    currentXPAmount = !currentXPAmount and amount or currentXPAmount + amount

    if nextstreak == 0 then nextstreak = currentXPAmount * 2 end
    if currentXPAmount >= nextstreak then
        nextstreak = nextstreak * 1.2
        streaks = streaks + 1
    end
end)

local colortime = 0 -- The higher the streak the faster the colors change
local fadetime = 0
local streakX = 20
local streakY = 20
local alpha = 100
hook.Add("HUDPaint", "ShowXPGainClient", function()
    if xpCvar:GetBool() and CurTime() < xpTime and currentXPAmount > 0 then
        local streaksize = streaks > 0 and 20 + (5 * streaks) or 20

        if streaks <= 12 then
            streakcolor = Color(52, 104, 104, alpha)
        end

        if streaks > 12 and streaks < 20 then
            streakX = math.random(20, 22)
            streakY = math.random(20, 22)
        end

        if streaks > 20 and streaks < 35 then
            streakX = math.random(20, 26)
            streakY = math.random(20, 26)
        end

        if streaks > 35 and streaks < 40 then
            streakX = math.random(20, 28)
            streakY = math.random(20, 28)
        end

        if streaks > 12 and streaks < 20 then
            if CurTime() > colortime then
                colortime = CurTime() + 1
                streakcolor = Color(math.random(100, 255), math.random(100, 255), math.random(100, 255), alpha)
            end
        end

        if streaks > 20 and streaks < 40 then
            if CurTime() > colortime then
                colortime = CurTime() + 0.3
                streakcolor = Color(math.random(100, 255), math.random(100, 255), math.random(100, 255), alpha)
            end
        end

        if streaks > 40 then
            if CurTime() > colortime then
                colortime = CurTime() + 0.1
                streakcolor = Color(math.random(100, 255), math.random(100, 255), math.random(100, 255), alpha)
            end
        end

        if streaks > 40 and streaks < 50 then
            streakX = math.random(20, 31)
            streakY = math.random(20, 31)
        end

        if streaks > 50 then
            streakX = math.random(20, 35)
            streakY = math.random(20, 35)
        end

        if xpTime - CurTime() <= 2 then
            if CurTime() > fadetime then
                fadetime = CurTime() + 0.2
                alpha = alpha - 10 > 0 and alpha - 10 or 0
            end
        else
            alpha = 100
        end

        draw.SimpleTextOutlined(
            "+" .. tostring(currentXPAmount) .. "XP",
            "XPVisualFont",
            streakX,
            ScrH() - 310 + streakY,
            streakcolor,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP,
            1,
            Color(0, 0, 0, alpha)
        )
    else
        currentXPAmount = 0 -- XP duration expired, reset their XP amount (Just the visuals)
        colortime = 0
        streaks = 0
        nextstreak = 0
        streakX = 20
        streakY = 20
        alpha = 100
    end
end)


-- XP Notifications
local randColorTime = 0
local IsText = 0
local color = nil
local notified = false

surface.CreateFont( "HugeRandomXP", {
	font = "Trebuchet24", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 73,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true,
})

net.Receive("DoubleXPGreet", function()
    if notified then return end
    notified = true
    local fadeTime = 0
    local fadeMore = 0
    local alpha = 255
    local remFunc = nil

    hook.Add("HUDPaint", "DoubleXPGraphics", function()
        if !remFunc then remFunc = timer.Simple(13, function() -- Only show beautiful graphics for 13 seconds
                hook.Remove("HUDPaint", "DoubleXPGraphics")
            end)
        end

        if fadeTime == 0 then fadeTime = CurTime() + 3 end

        local function pickRandomColor()
            color = Color(math.random(100, 255), math.random(100, 255), math.random(100, 255), alpha)
        end

        local function FadeMore()
            fadeMore = CurTime() + 0.1
            alpha = alpha - 20
        end

        if CurTime() > fadeTime then
            if fadeMore == 0 then fadeMore = CurTime() + 0.1 end

            if CurTime() > fadeMore then
                FadeMore()
                if alpha <= 0 then alpha = 0 end
            end
        end

        if CurTime() > randColorTime then
            randColorTime = CurTime() + 0.1
            pickRandomColor()
        end

        draw.DrawText(
            "DOUBLE XP WEEKEND!",
            "HugeRandomXP",
            ScrW() / 2 +  math.random(1, 5),
            math.random(1, 5),
            color,
            TEXT_ALIGN_CENTER
        )
    end)
end)
