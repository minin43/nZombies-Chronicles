-- Settings helper functions created by Ethorbit,
-- taken from my Chronicles server's "nZombies Settings Menu"

local PANEL = FindMetaTable("Panel")

function DFrame:ApplynZombiesTheme()
    self.Paint = function()
    	draw.RoundedBox( 8, 0, 0, self:GetWide(), self:GetTall(), Color(130, 45, 45, 255))
    end
end

-- Show a confirmation menu inside the center of a panel
-- cb is callback function which returns whether or not
-- the user pressed "Yes"
function PANEL:ShowConfirmationMenu(title, message, cb)
    local confirmMenuFrame = vgui.Create("DFrame", self)
    confirmMenuFrame:SetTitle(title or "Are you sure?")
    confirmMenuFrame:SetWide(self:GetWide() / 2)
    confirmMenuFrame:SetTall(self:GetTall() / 2)
    confirmMenuFrame:ApplynZombiesTheme()
    confirmMenuFrame:Center()
    confirmMenuFrame.OnClose = function()
        cb(false)
    end

    local confirmMenuPanel = vgui.Create("DPanel", confirmMenuFrame)
    confirmMenuPanel:SetTall(confirmMenuFrame:GetTall() / 1.5)
    confirmMenuPanel:SetWide(confirmMenuFrame:GetWide() - 20)
    confirmMenuPanel:Center()
    local confirmMenuPanelPosX,confirmMenuPanelPosY = confirmMenuPanel:GetPos()
    confirmMenuPanel:SetPos(confirmMenuPanelPosX, confirmMenuPanelPosY + 10)

    confirmMenuPanel.Paint = function()
    end

    local messagePanel = vgui.Create("DScrollPanel", confirmMenuPanel)
    messagePanel:Dock(FILL)
    messagePanel:DockPadding(1, 1, 1, 1)

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(TOP)
    messageLabel:SetAutoStretchVertical(true)
    --messageLabel:SetColor(Color(0, 0, 0))
    messageLabel:SetFont("CenterPrintText")
    messageLabel:SetText(message)
    messageLabel:SetWrap(true)

    local buttonPanel = vgui.Create("DPanel", confirmMenuPanel)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(40)
    buttonPanel.Paint = function() end

    local spacing = vgui.Create("DPanel", confirmMenuPanel)
    spacing:Dock(BOTTOM)
    spacing:SetTall(10)
    spacing.Paint = function() end

    local yesBtn = vgui.Create("DButton", buttonPanel)
    yesBtn:Dock(LEFT)
    yesBtn:SetText("Yes")

    yesBtn.DoClick = function()
        cb(true)
        confirmMenuFrame:Remove()
    end

    yesBtn:SetWide((confirmMenuPanel:GetWide() / 2) - 1)

    local noBtn = vgui.Create("DButton", buttonPanel)
    noBtn:Dock(RIGHT)
    noBtn:SetText("No")

    noBtn.DoClick = function()
        cb(false)
        confirmMenuFrame:Remove()
    end

    noBtn:SetWide((confirmMenuPanel:GetWide() / 2) - 1)
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
