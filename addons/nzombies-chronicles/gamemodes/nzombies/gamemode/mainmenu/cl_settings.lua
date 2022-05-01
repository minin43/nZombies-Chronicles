-- Settings helper functions created by Ethorbit,
-- taken from my Chronicles server's "nZombies Settings Menu"

local PANEL = FindMetaTable("Panel")

function DFrame:ApplynZombiesTheme()
    self.Paint = function()
    	draw.RoundedBox( 8, 0, 0, self:GetWide(), self:GetTall(), Color(130, 45, 45, 255))
    end
end

function PANEL:AddResetButton(convar, reset) -- Add a button to set a convar back to its default value
    if (convar) then
        local option = self
        local resetBtn = vgui.Create("DImageButton", self)
        resetBtn:SetImage("icon16/arrow_redo.png")
        resetBtn:SetSize(15, 15)
        resetBtn:SetPos(440, 0)
        resetBtn.DoClick = function()
            if (istable(convar)) then
                for _,v in pairs(convar) do
                    if (v) then
                        --v:Revert()
                        LocalPlayer():ConCommand(v:GetName() .. " " .. v:GetDefault())
                    end
                end
            else
                --convar:Revert()
                LocalPlayer():ConCommand(convar:GetName() .. " " .. convar:GetDefault())
            end

            reset(option, convar)
        end
    end
end
