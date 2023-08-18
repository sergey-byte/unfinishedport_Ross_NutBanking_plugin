local PLUGIN = PLUGIN or {}
PLUGIN.bankINFO = PLUGIN.bankINFO or {}

-- Hook to start talking
netstream.Hook('Bank::StartTalk', function()
    if IsValid(PLUGIN.interface) then
        PLUGIN.interface:Close()
    end
    PLUGIN.interface = vgui.Create("Talking")
    PLUGIN.interface:Populate()
end)

-- Hook to show check
netstream.Hook('bank::showCheck', function(check)
    local checkItem = pon.decode(check)

    if IsValid(PLUGIN.interface) then
        PLUGIN.interface:Close()
    end
    PLUGIN.interface = vgui.Create("CheckPanel")
    PLUGIN.interface:Populate()
end)

-- Hook to open ATM
netstream.Hook('Bank::OpenATM', function()
    if IsValid(PLUGIN.atm) then
        PLUGIN.atm:Close()
    end
    PLUGIN.atm = vgui.Create("ATMUI")
    PLUGIN.atm:Populate()
end)

-- Hook to send account info
netstream.Hook('bank::sendAccInfo', function(data)
    PLUGIN.bankINFO = pon.decode(data)
    if IsValid(PLUGIN.atm) then
        PLUGIN.atm.MoneyAmount:SetText("Money: " .. PLUGIN.bankINFO["money"] .. nut.currency.symbol)
        PLUGIN.atm.Loan:SetText("Loan: " .. PLUGIN.bankINFO["loan"] .. nut.currency.symbol)
    end
end)

netstream.Hook('bank::openBanking', function(data)
	local data = pon.decode(data)
	PLUGIN.accsList = data[1];
	PLUGIN.fund = data[2]
	if PLUGIN.dbOpened and PLUGIN.dbOpened:IsValid() then
		PLUGIN.dbOpened:Close()
	end

	PLUGIN.dbOpened = vgui.Create("Bank_Database")
	PLUGIN.dbOpened:Populate()
end)

netstream.Hook('bank::openCollector', function(id)
	if ix.item.instances[id] then
		PLUGIN:BankStorage(ix.item.instances[id])
	end
end)

netstream.Hook('bank::hackVault', function(data, scenario, timeLeft, fund)
	local SCENARIO = PLUGIN.vaultScenario[scenario]
	if !SCENARIO then return end;
		
	local DIFF = pon.decode(data);
	DIFF["stack"] = pon.decode(DIFF["stack"])
	DIFF["positions"] = pon.decode(DIFF["positions"])
	PASSWD = "";
	FUND = fund;
	ATTEMPTS = SCENARIO.ATTEMPTS

	if PLUGIN.vaultInterface and PLUGIN.vaultInterface:IsValid() then
			PLUGIN.vaultInterface:Close()
	end

	PLUGIN.vaultInterface = vgui.Create("Mini_game_SW")
	PLUGIN.vaultInterface:Populate()

	timer.Create("LocalVaultTimer", 1, timeLeft, function()
		if !PLUGIN.vaultInterface or !PLUGIN.vaultInterface:IsValid() then
			timer.Remove("LocalVaultTimer")
			return
		end

		if PLUGIN.vaultInterface:IsValid() then
			local time = timer.RepsLeft("LocalVaultTimer");
			
			if time > 60 then
				local lTime = math.floor(time / 60);
				
				if lTime > 9 then
					formatTime = math.floor(time / 60) .. ":"
				else
					formatTime = "0" .. math.floor(time / 60) .. ":"
				end;
				
				if time % 60 < 10 then
					formatTime = formatTime .. "0" .. time % 60
				else
					formatTime = formatTime .. time % 60
				end
			else
				formatTime = "00:" .. time
			end
			
			PLUGIN.vaultInterface.time:SetText(formatTime)
			
			if time <= 0 then
				PLUGIN.vaultInterface:Close()
			end
		end
	end)
end)

netstream.Hook('bank::CloseVaultClientside', function()
	if PLUGIN.vaultInterface and PLUGIN.vaultInterface:IsValid() then
		PLUGIN.vaultInterface:Close()
	end
end)

netstream.Hook('bank::SyncAttempts', function(atts)
	if PLUGIN.vaultInterface and PLUGIN.vaultInterface:IsValid() then
		PLUGIN.vaultInterface.att:SetText("Attempts: " .. math.max(atts, 0) .. "/" .. SCENARIO.ATTEMPTS)
		if atts <= 0 then
			PLUGIN.vaultInterface:Close()
		end
	end
end)

netstream.Hook('bank::OpenLogsList', function(data)
	if PLUGIN.bankingLogs and PLUGIN.bankingLogs:IsValid() then
		PLUGIN.bankingLogs:Close()
	end

	local BankingLogs = pon.decode(data)
		
	PLUGIN.bankingLogs = vgui.Create("Banking_logs")
	PLUGIN.bankingLogs:Populate()
end)

function PLUGIN:BankStorage(storage)
    local PADDING = 4

    if not storage then return end

    local localInv = LocalPlayer():GetCharacter():GetInventory()
    if not localInv then return end

    local localInvPanel = nut.gui.inv1
    local storageInvPanel = nut.gui.inv2

    storageInvPanel:SetTitle("Local storage")

    localInvPanel:ShowCloseButton(true)
    storageInvPanel:ShowCloseButton(true)

    local extraWidth = (storageInvPanel:GetWide() + PADDING) / 2
    localInvPanel:Center()
    storageInvPanel:Center()
    localInvPanel.x = localInvPanel.x + extraWidth
    storageInvPanel:MoveLeftOf(localInvPanel, PADDING)

    local function exitStorageOnRemove(panel)
        if IsValid(storageInvPanel) then
            storageInvPanel:Remove()
        end
        panel:oldOnRemove()
    end

    hook.Run("OnCreateStoragePanel", localInvPanel, storageInvPanel, storage)

    localInvPanel.OnRemove = exitStorageOnRemove
    storageInvPanel.OnRemove = exitStorageOnRemove
end