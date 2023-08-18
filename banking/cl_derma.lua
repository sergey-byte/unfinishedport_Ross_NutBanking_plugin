local math = math
local appr = math.Approach
local PANEL = {}
local PLUGIN = PLUGIN
    
function PANEL:DebugClose()
		local use = input.IsKeyDown( KEY_PAD_MINUS );

	if use and self.debugClose then
			self.debugClose = false;
    	surface.PlaySound("ui/buttonclick.wav");
    	self:Close();
  end;
end;

function PANEL:InitHover(defaultColor, incrementTo, colorSpeed, borderColor)
	self.initedHover = true
    self.dColor = !defaultColor and Color(60, 60, 60) or defaultColor
    self.IncTo = !incrementTo and Color(70, 70, 70) or incrementTo
    self.cSpeed = !colorSpeed and 7 * 100 or colorSpeed * 700;
    self.cCopy = self.dColor
    self.bColor = !borderColor and Color(90, 90, 90) or borderColor
end;

function PANEL:HoverButton(w, h)
		if !CLIENT then return end;
		if !self.initedHover then return end;

	local incTo = self.IncTo
    local cCopy = self.cCopy;
    local dis = self.Disable
    local hov = self:IsHovered()
    if dis then
        surface.SetDrawColor(Color(cCopy.r, cCopy.g, cCopy.b, 100));
        surface.DrawRect(0, 0, w, h)
        return
    end
    local red, green, blue = self.dColor.r, self.dColor.g, self.dColor.b
    self.dColor = {
        r = appr(red, hov and incTo.r or cCopy.r, FrameTime() * self.cSpeed),
        g = appr(green, hov and incTo.g or cCopy.g, FrameTime() * self.cSpeed),
        b = appr(blue, hov and incTo.b or cCopy.b, FrameTime() * self.cSpeed)
    }
    surface.SetDrawColor(self.dColor)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(Color(40, 40, 40))
    surface.DrawOutlinedRect( 0, 0, w, h, 1 )
end;

function PLUGIN:BankStorage(container)
		-- Number of pixels between the local inventory and container inventory.
		local PADDING = 4

        if not container then return end

        local client = container:GetPlayerOwner()

        -- Show both the container and inventory.
        local localInvPanel = client:GetCharacter():GetInventory():Show()
        local containerInvPanel = container:Show()

        -- Set titles for the panels
        localInvPanel:SetTitle("Local inventory")
        containerInvPanel:SetTitle("Container inventory")

        -- Allow the inventory panels to close.
        localInvPanel:ShowCloseButton(true)
        containerInvPanel:ShowCloseButton(true)

        -- Put the two panels, side by side, in the middle.
        local extraWidth = (containerInvPanel:GetWide() + PADDING) / 2
        localInvPanel:Center()
        containerInvPanel:Center()
        localInvPanel.x = localInvPanel.x - extraWidth
        containerInvPanel:MoveRightOf(localInvPanel, PADDING)

        -- Signal that the user left the inventory if either closes.
        local firstToRemove = true
        localInvPanel.oldOnRemove = localInvPanel.OnRemove
        containerInvPanel.oldOnRemove = containerInvPanel.OnRemove

        local function exitStorageOnRemove(panel)
            if firstToRemove then
                firstToRemove = false
                container:ExitStorage()
                local otherPanel =
                    panel == localInvPanel and containerInvPanel or localInvPanel
                if IsValid(otherPanel) then otherPanel:Remove() end
            end
            panel:oldOnRemove()
        end

        hook.Run("OnCreateStoragePanel", localInvPanel, containerInvPanel, container)

        localInvPanel.OnRemove = exitStorageOnRemove
        containerInvPanel.OnRemove = exitStorageOnRemove
end