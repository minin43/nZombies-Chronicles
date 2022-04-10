-- Add custom NZ properties we want in the HUD

-- Might break with a future update but oh well \o/
-- they made everything local
if !TFA then return end

nZ = nZ or {}
nZ.TFACompatibility = nZ.TFACompatibility or {} -- hey look, IT'S NOT LOCAL!!!

local TEXT_COLOR = ColorAlpha(TFA.Attachments and TFA.Attachments.Colors and TFA.Attachments.Colors["secondary"] or Color(15, 15, 15, 64), 255)
local BACKGROUND_COLOR = ColorAlpha(TFA.Attachments and TFA.Attachments.Colors and TFA.Attachments.Colors["background"] or Color(15, 15, 15, 64), 255)
local pad = 4
local lbound = 32 + pad

local function TextShadowPaint(myself, w, h)
	if not myself.TextColor then
		myself.TextColor = ColorAlpha(color_white, 0)
	end

	draw.NoTexture()
	draw.SimpleText(myself.Text, myself.Font, 2, 2, ColorAlpha(color_black, myself.TextColor.a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(myself.Text, myself.Font, 0, 0, myself.TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function get_realtime_data()
    return {
        ["screenwidth"] = ScrW(),
        ["screenheight"] = ScrH()
    }
end

-- This kind of reusable code is what the TFA crew should learn how to make
-- and then actually made available to modders unlike 90% of their localized shitty spaghetti code
-- watch and learn :
local function add_inspection_stat_to_panel(statpanel, text_think_func)
    if !text_think_func then return end
    local screenwidth = ScrW()
    local screenheight = ScrH()
    local panelwidth = (screenwidth - lbound)

    local newpanel = statpanel:Add("DPanel")
    newpanel:SetSize(400, 24)

    local textpanel = newpanel:Add("DPanel")

    if text_think_func then
        textpanel.Think = text_think_func(textpanel)
    end

    newpanel.Paint = nil
    newpanel:Dock(TOP)

    textpanel.Font = "TFA_INSPECTION_SMALL"
    textpanel:Dock(LEFT)
    textpanel:SetSize(panelwidth, 24)
    textpanel.Paint = TextShadowPaint

    local w,h = statpanel:GetSize()
    statpanel:SetSize(panelwidth, h + 24)
end

function nZ.TFACompatibility:AddInspectionStat(text_think_func) -- WOW! modders can ACTUALLY USE IT!
    local statpanel = nZ.TFACompatibility.InspectionStatPanel
    if statpanel then
        add_inspection_stat_to_panel(statpanel, text_think_func)
    end
end

hook.Add("TFA_InspectVGUI_InfoStart", "Add_NZ_TFA_Stats", function(wepom, contentpanel)
    local self = wepom
    nZ.TFACompatibility.InspectionStatPanel = contentpanel:Add("DPanel") -- REVOLUTIONARY! Modders can actually access this on the outside because our code isn't retarded

    local statpanel = nZ.TFACompatibility.InspectionStatPanel
    statpanel:SetSize(0,0)
    statpanel:Dock(BOTTOM)
    statpanel:SetBackgroundColor(ColorAlpha(color_white, 0))

    -- Just to create some spacing to separate the NZ from the Normal stats
    add_inspection_stat_to_panel(statpanel, function() end)

    -- DamageHeadshot:
    add_inspection_stat_to_panel(statpanel, function(myself)
        if not IsValid(self) then return end
        local hsMult = self:GetStat("Primary.DamageHeadshot")
        if !isnumber(hsMult) then hsMult = 1.5 end
        local dmgstr = "Headshot Multiplier: " .. hsMult

        myself.Text = dmgstr
        myself.TextColor = TEXT_COLOR
    end)

	-- ProjectileRadius:
	if wepom.Primary and wepom.Primary.ProjectileRadius then
		add_inspection_stat_to_panel(statpanel, function(myself)
			if not IsValid(self) then return end
			local ProjRadius = self:GetStat("Primary.ProjectileRadius")
			if !isnumber(ProjRadius) then return end

			local ProjRadius = "Projectile Radius: " .. ProjRadius

			myself.Text = dmgstr
			myself.TextColor = TEXT_COLOR
		end)
	end
end)
