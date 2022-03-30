-- Better crosshair (proper nextbot support, team colors, and target collision)
-- This may break with a future TFA update, but oh well \o/ they made everything local

-- I'll just fix it when it's reported to me

CreateConVar("cl_tfa_hud_crosshair_color_enemy", 1, FCVAR_NONE, "Should crosshair use enemy color of entity being aimed at?")

local CMIX_MULT = 1
local c1t = {}
local c2t = {}

local function ColorMix(c1, c2, fac, t)
	c1 = c1 or color_white
	c2 = c2 or color_white
	c1t.r = c1.r
	c1t.g = c1.g
	c1t.b = c1.b
	c1t.a = c1.a
	c2t.r = c2.r
	c2t.g = c2.g
	c2t.b = c2.b
	c2t.a = c2.a

	for k, v in pairs(c1t) do
		if t == CMIX_MULT then
			c1t[k] = Lerp(fac, v, (c1t[k] / 255 * c2t[k] / 255) * 255)
		else
			c1t[k] = Lerp(fac, v, c2t[k])
		end
	end

	return Color(c1t.r, c1t.g, c1t.b, c1t.a)
end

local c_red = Color(255, 0, 0, 255)
local c_grn = Color(0, 255, 0, 255)

local hostilenpcmaps = {
	["gm_lasers"] = true,
	["gm_locals"] = true,
	["gm_raid"] = true,
	["gm_slam"] = true
}

local mymap
local cl_tfa_hud_crosshair_color_teamcvar

local function GetTeamColor(ent)
	if not cl_tfa_hud_crosshair_color_teamcvar then
		cl_tfa_hud_crosshair_color_teamcvar = GetConVar("cl_tfa_hud_crosshair_color_team")
	end

	if not cl_tfa_hud_crosshair_color_enemycvar then
		cl_tfa_hud_crosshair_color_enemycvar = GetConVar("cl_tfa_hud_crosshair_color_enemy")
	end

	if not mymap then
		mymap = game.GetMap()
	end

	local ply = LocalPlayer()
	if not IsValid(ply) then return color_white end
	if ent == LocalPlayer() then return color_white end

	if ent:IsPlayer() then
		if not cl_tfa_hud_crosshair_color_teamcvar or not cl_tfa_hud_crosshair_color_teamcvar:GetBool() then return color_white end

		return cl_tfa_hud_crosshair_color_teamcvar:GetInt() == 1 and (playerColors and playerColors[ent:EntIndex()] or c_grn) or c_grn
	end

    -- Finally give nextbots crosshair color... Don't know why they chose not to do this.....
    if ent.Type == "nextbot" then
        return c_red
    end

	if ent:IsNPC() then
		local disp = ent:GetNW2Int("tfa_disposition", -1)

		if disp > 0 then
			if disp == (D_FR or 2) or disp == (D_HT or 1) then
                if not cl_tfa_hud_crosshair_color_enemycvar or not cl_tfa_hud_crosshair_color_enemycvar:GetBool() then return color_white end
				return c_red
			else
				return c_grn
			end
		end

		if IsFriendEntityName(ent:GetClass()) and not hostilenpcmaps[mymap] then
            if not cl_tfa_hud_crosshair_color_teamcvar or not cl_tfa_hud_crosshair_color_teamcvar:GetBool() then return color_white end
			return c_grn
		else
            if not cl_tfa_hud_crosshair_color_enemycvar or not cl_tfa_hud_crosshair_color_enemycvar:GetBool() then return color_white end
			return c_red
		end
	end

	return color_white
end

local crosscol = Color(255, 255, 255, 255)
local crossa_cvar = GetConVar("cl_tfa_hud_crosshair_color_a")
local outa_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_a")
local crosscustomenable_cvar = GetConVar("cl_tfa_hud_crosshair_enable_custom")
local crossr_cvar = GetConVar("cl_tfa_hud_crosshair_color_r")
local crossg_cvar = GetConVar("cl_tfa_hud_crosshair_color_g")
local crossb_cvar = GetConVar("cl_tfa_hud_crosshair_color_b")
local crosslen_cvar = GetConVar("cl_tfa_hud_crosshair_length")
local crosshairwidth_cvar = GetConVar("cl_tfa_hud_crosshair_width")
local drawdot_cvar = GetConVar("cl_tfa_hud_crosshair_dot")
local clen_usepixels = GetConVar("cl_tfa_hud_crosshair_length_use_pixels")
local outline_enabled_cvar = GetConVar("cl_tfa_hud_crosshair_outline_enabled")
local outr_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_r")
local outg_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_g")
local outb_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_b")
local outlinewidth_cvar = GetConVar("cl_tfa_hud_crosshair_outline_width")
local hudenabled_cvar = GetConVar("cl_tfa_hud_enabled")
local cgapscale_cvar = GetConVar("cl_tfa_hud_crosshair_gap_scale")
local tricross_cvar = GetConVar("cl_tfa_hud_crosshair_triangular")

local sv_tfa_recoil_legacy = GetConVar("sv_tfa_recoil_legacy")
local cl_tfa_hud_crosshair_pump = GetConVar("cl_tfa_hud_crosshair_pump")
local sv_tfa_fixed_crosshair = GetConVar("sv_tfa_fixed_crosshair")

local crosshairMatrix = Matrix()
local crosshairMatrixLeft = Matrix()
local crosshairMatrixRight = Matrix()
local crosshairRotation = Angle()

local pixelperfectshift = Vector(0.0)

hook.Add("TFA_Initialize", "NZ_Crosshair_Fix", function(wepom)
    if !wepom.IsTFAWeapon then return end

    wepom.DoDrawCrosshair = function()
        local self = wepom
        local self2 = self:GetTable()
        local x, y

        if not self2.ratios_calc or not self2.DrawCrosshairDefault then return true end
        if self2.GetHolding(self) then return true end

        local stat = self2.GetStatus(self)

        if not crosscustomenable_cvar:GetBool() then
            return TFA.Enum.ReloadStatus[stat] or math.min(1 - (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()), 1 - self:GetSprintProgress(), 1 - self:GetInspectingProgress()) <= 0.5
        end

        self2.clrelp = self2.clrelp or 0
        self2.clrelp = math.Approach(
            self2.clrelp,
            TFA.Enum.ReloadStatus[stat] and 0 or 1,
            ((TFA.Enum.ReloadStatus[stat] and 0 or 1) - self2.clrelp) * RealFrameTime() * 7)

        local crossa = crossa_cvar:GetFloat() *
            math.pow(math.min(1 - (((self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) and
                not self2.GetStatL(self, "DrawCrosshairIronSights")) and (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) or 0),
                1 - self:GetSprintProgress(),
                1 - self:GetInspectingProgress(),
                self2.clrelp),
            2)

        local outa = outa_cvar:GetFloat() *
            math.pow(math.min(1 - (((self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) and
                not self2.GetStatL(self, "DrawCrosshairIronSights")) and (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) or 0),
                1 - self:GetSprintProgress(),
                1 - self:GetInspectingProgress(),
                self2.clrelp),
            2)

        local ply = LocalPlayer()
        if not ply:IsValid() or self:GetOwner() ~= ply then return false end

        if not ply.interpposx then
            ply.interpposx = ScrW() / 2
        end

        if not ply.interpposy then
            ply.interpposy = ScrH() / 2
        end

        local targent

        -- If we're drawing the local player, draw the crosshair where they're aiming
        -- instead of in the center of the screen.
        if self:GetOwner():ShouldDrawLocalPlayer() and not ply:GetNW2Bool("ThirtOTS", false) then
            local tr = util.GetPlayerTrace(self:GetOwner())
            tr.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_MONSTER + CONTENTS_WINDOW + CONTENTS_DEBRIS + CONTENTS_GRATE + CONTENTS_AUX -- This controls what the crosshair will be projected onto.
            local trace = util.TraceLine(tr)
            targent = trace.Entity
            local coords = trace.HitPos:ToScreen()
            coords.x = math.Clamp(coords.x, 0, ScrW())
            coords.y = math.Clamp(coords.y, 0, ScrH())
            ply.interpposx = math.Approach(ply.interpposx, coords.x, (ply.interpposx - coords.x) * RealFrameTime() * 7.5)
            ply.interpposy = math.Approach(ply.interpposy, coords.y, (ply.interpposy - coords.y) * RealFrameTime() * 7.5)
            x, y = ply.interpposx, ply.interpposy
            -- Center of screen
        elseif sv_tfa_fixed_crosshair:GetBool() then
            x, y = ScrW() / 2, ScrH() / 2
            local tr = util.QuickTrace(ply:GetShootPos(), EyeAngles():Forward() * 0x7FFF, self2.selftbl)
            targent = tr.Entity
        else
            local ang = self:GetAimAngle()
            local tr = util.QuickTrace(ply:GetShootPos(), ang:Forward() * 0x7FFF, self2.selftbl)
            targent = tr.Entity
            local pos = tr.HitPos:ToScreen()
            x, y = pos.x, pos.y
        end

        TFA.LastCrosshairPosX, TFA.LastCrosshairPosY = x, y

        local s_cone = self:CalculateCrosshairConeRecoil()

        if not self2.selftbl then
            self2.selftbl = {ply, self}
        end

        -- Much better trace..
        local targent = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * 0x7FFF,
            mask = MASK_VISIBLE_AND_NPCS,
            filter = LocalPlayer()
        }).Entity

        local crossr, crossg, crossb, crosslen, crosshairwidth, drawdot, teamcol
        teamcol = GetTeamColor(targent)
        crossr = crossr_cvar:GetFloat()
        crossg = crossg_cvar:GetFloat()
        crossb = crossb_cvar:GetFloat()
        crosslen = crosslen_cvar:GetFloat() * 0.01
        crosscol.r = crossr
        crosscol.g = crossg
        crosscol.b = crossb
        crosscol.a = crossa
        crosscol = ColorMix(crosscol, teamcol, 1, CMIX_MULT)
        crossr = crosscol.r
        crossg = crosscol.g
        crossb = crosscol.b
        crossa = crosscol.a
        crosshairwidth = crosshairwidth_cvar:GetFloat()
        drawdot = drawdot_cvar:GetBool()
        local scale = (s_cone * 90) / self:GetOwner():GetFOV() * ScrH() / 1.44 * cgapscale_cvar:GetFloat()

        if self:GetSprintProgress() >= 0.1 and not self:GetStatL("AllowSprintAttack", false) then
            scale = scale * (1 + TFA.Cubic(self:GetSprintProgress() - 0.1) * 6)
        end

        if self2.clrelp < 0.9 then
            scale = scale * Lerp(TFA.Cubic(0.9 - self2.clrelp) * 1.111, 1, 8)
        end

        local gap = math.Round(scale / 2) * 2
        local length

        if not clen_usepixels:GetBool() then
            length = gap + ScrH() * 1.777 * crosslen
        else
            length = gap + crosslen * 100
        end

        local extraRotation = 0
        local cPos = Vector(x, y)

        if stat == TFA.Enum.STATUS_PUMP and cl_tfa_hud_crosshair_pump:GetBool() then
            if tricross_cvar:GetBool() then
                extraRotation =  TFA.Quintic(self:GetStatusProgress(true))
                local mul = 360
                extraRotation = extraRotation * mul
            else
                extraRotation = TFA.Quintic(TFA.Cosine(self:GetStatusProgress(true)))
                local mul = -180

                if extraRotation < 0.5 then
                    extraRotation = extraRotation * mul
                else
                    extraRotation = (1 - extraRotation) * mul
                end
            end
        end

        extraRotation = extraRotation - EyeAngles().r

        crosshairMatrix:Identity()
        crosshairMatrix:Translate(cPos)
        crosshairRotation.y = extraRotation
        crosshairMatrix:Rotate(crosshairRotation)

        if tricross_cvar:GetBool() then
            crosshairMatrixLeft:Identity()
            crosshairMatrixRight:Identity()

            crosshairMatrixLeft:Translate(cPos)
            crosshairMatrixRight:Translate(cPos)

            crosshairRotation.y = extraRotation + 135
            crosshairMatrixRight:SetAngles(crosshairRotation)
            crosshairRotation.y = extraRotation - 135
            crosshairMatrixLeft:SetAngles(crosshairRotation)

            if crosshairwidth % 2 ~= 0 then
                crosshairMatrixLeft:Translate(pixelperfectshift)
                crosshairMatrixRight:Translate(pixelperfectshift)
            end
        end

        DisableClipping(true)

        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)

        --Outline
        if outline_enabled_cvar:GetBool() then
            local outr, outg, outb, outlinewidth
            outr = outr_cvar:GetFloat()
            outg = outg_cvar:GetFloat()
            outb = outb_cvar:GetFloat()
            outlinewidth = outlinewidth_cvar:GetFloat()

            cam.PushModelMatrix(crosshairMatrix)
            surface.SetDrawColor(outr, outg, outb, outa)

            local tHeight = math.Round(length - gap + outlinewidth * 2) + crosshairwidth

            local tX, tY, tWidth =
                math.Round(-outlinewidth) - crosshairwidth / 2,
                -gap * self:GetStatL("Primary.SpreadBiasPitch") - tHeight + outlinewidth,
                math.Round(outlinewidth * 2) + crosshairwidth

            -- Top
            surface.DrawRect(tX, tY, tWidth, tHeight)
            cam.PopModelMatrix()

            if tricross_cvar:GetBool() then
                tY = -gap - tHeight

                cam.PushModelMatrix(crosshairMatrixLeft)
                surface.DrawRect(tX, tY + outlinewidth, tWidth, tHeight)
                cam.PopModelMatrix()

                cam.PushModelMatrix(crosshairMatrixRight)
                surface.DrawRect(tX, tY + outlinewidth, tWidth, tHeight)
                cam.PopModelMatrix()
            else
                cam.PushModelMatrix(crosshairMatrix)

                local width = math.Round(length - gap + outlinewidth * 2) + crosshairwidth
                local realgap = math.Round(gap * self:GetStatL("Primary.SpreadBiasYaw") - outlinewidth) - crosshairwidth / 2

                -- Left
                surface.DrawRect(
                    -realgap - width,
                    math.Round(-outlinewidth) - crosshairwidth / 2,
                    width,
                    math.Round(outlinewidth * 2) + crosshairwidth)

                -- Right
                surface.DrawRect(
                    realgap,
                    math.Round(-outlinewidth) - crosshairwidth / 2,
                    width,
                    math.Round(outlinewidth * 2) + crosshairwidth)

                -- Bottom
                surface.DrawRect(
                    math.Round(-outlinewidth) - crosshairwidth / 2,
                    math.Round(gap * self:GetStatL("Primary.SpreadBiasPitch") - outlinewidth) - crosshairwidth / 2,
                    math.Round(outlinewidth * 2) + crosshairwidth,
                    math.Round(length - gap + outlinewidth * 2) + crosshairwidth)

                cam.PopModelMatrix()
            end

            if drawdot then
                cam.PushModelMatrix(crosshairMatrix)
                surface.DrawRect(-math.Round((crosshairwidth - 1) / 2) - math.Round(outlinewidth), -math.Round((crosshairwidth - 1) / 2) - math.Round(outlinewidth), math.Round(outlinewidth * 2) + crosshairwidth, math.Round(outlinewidth * 2) + crosshairwidth) --dot
                cam.PopModelMatrix()
            end
        end

        --Main Crosshair
        cam.PushModelMatrix(crosshairMatrix)
        surface.SetDrawColor(crossr, crossg, crossb, crossa)

        local tHeight = math.Round(length - gap) + crosshairwidth

        local tX, tY, tWidth =
            -crosshairwidth / 2,
            math.Round(-gap * self:GetStatL("Primary.SpreadBiasPitch") - tHeight),
            crosshairwidth

        -- Top
        surface.DrawRect(tX, tY, tWidth, tHeight)
        cam.PopModelMatrix()

        if tricross_cvar:GetBool() then
            local xhl = math.Round(length - gap) + crosshairwidth

            tY = math.Round(-gap - tHeight)

            cam.PushModelMatrix(crosshairMatrixLeft)
            surface.DrawRect(tX, tY, tWidth, tHeight)
            cam.PopModelMatrix()

            cam.PushModelMatrix(crosshairMatrixRight)
            surface.DrawRect(tX, tY, tWidth, tHeight)
            cam.PopModelMatrix()
        else
            cam.PushModelMatrix(crosshairMatrix)

            local width = math.Round(length - gap) + crosshairwidth
            local realgap = math.Round(gap * self:GetStatL("Primary.SpreadBiasYaw")) - crosshairwidth / 2

            -- Left
            surface.DrawRect(
                -realgap - width,
                -crosshairwidth / 2,
                width,
                crosshairwidth)

            -- Right
            surface.DrawRect(
                realgap,
                -crosshairwidth / 2,
                width,
                crosshairwidth)

            -- Bottom
            surface.DrawRect(
                -crosshairwidth / 2,
                math.Round(gap * self:GetStatL("Primary.SpreadBiasPitch")) - crosshairwidth / 2,
                crosshairwidth,
                math.Round(length - gap) + crosshairwidth)

            cam.PopModelMatrix()
        end

        render.PopFilterMag()
        render.PopFilterMin()

        if drawdot then
            cam.PushModelMatrix(crosshairMatrix)
            surface.DrawRect(-math.Round((crosshairwidth - 1) / 2), -math.Round((crosshairwidth - 1) / 2), crosshairwidth, crosshairwidth) --dot
            cam.PopModelMatrix()
        end

        DisableClipping(false)

        return true
    end
end)
