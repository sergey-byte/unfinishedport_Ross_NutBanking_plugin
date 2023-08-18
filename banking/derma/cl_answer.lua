local PLUGIN = PLUGIN;

local PANEL = {}

PLUGIN.TalkBacks 	= {}
PLUGIN.Answers 		= {}
PLUGIN.vaultScenario = {
		[1] = { // Easy
			NAME = "Easy",
			BINARY = 7,
			INTER = 4,
			ATTEMPTS = 10,
			TIME = 720,
			REWARD = 550,
		},
		[2] = { // Medium
			NAME = "Medium",
			BINARY = 7,
			INTER = 4,
			ATTEMPTS = 5,
			TIME = 300,
			REWARD = 6000,
		},
		[3] = { // Hard
			NAME = "Hard",
			BINARY = 15,
			INTER = 8,
			ATTEMPTS = 3,
			TIME = 120,
			REWARD = 10000,
		}
}

function PLUGIN:AddTalkback(name, data)
		self.TalkBacks[name] = data
end;

-- Answers of NPC;
function PLUGIN:AddAnswer(name, data)
		self.Answers[name] = data
end;

PLUGIN:AddTalkback("hello", {
	text = "Hello! I'm a bank manager and I can help you with some banking things.",
	OnOpen = true,
})
PLUGIN:AddTalkback("bank_acc_open", {
	text = "Good to hear. Do you really want to open a bank account?",
})
PLUGIN:AddTalkback("bank_acc_open_succ", {
	text = "Good, I'm going to open the bank account for you. Have a nice day!",
})
PLUGIN:AddTalkback("bank_acc_open_failed", {
	text = "I'm understand. Return when you want to open an account!",
})
PLUGIN:AddTalkback("bank_deposit", {
	text = "Tell me the amount of how much you want to deposit.",
})
PLUGIN:AddTalkback("bank_withdraw", {
	text = "Tell me the amount of how much you want to withdraw.",
	format = function(text)
			return string.format(text .. "\nYou can withdraw: %d", LocalPlayer():BankData().money)
	end
})
PLUGIN:AddTalkback("bank_loaned", {
	text = "How much of loan do you want to pay?",
	format = function(text)
			return string.format(text .. "\nYou should repay: %d", LocalPlayer():BankData().loan)
	end
})
PLUGIN:AddTalkback("bank_acc_money_amount", {
	text = "Let me check...",
	format = function(text)
			return string.format(text .. "\nYou have: %d", LocalPlayer():BankData().money)
	end
})
PLUGIN:AddTalkback("check_depo", {
	text = "Type here check ID you want to deposit.",
})

-- <><><><><><><><><><> Default answers <><><><><><><><><><> --
PLUGIN:AddAnswer("bank_openacc", {
	text = "I want to open an account",
	callClick = {"bank_yes", "bank_no"},
	remClick = {"bank_openacc", "_bank_ex", "bank_depositcheck"},
	talkBack = "bank_acc_open",
	OnOpen = true,
	CanShow = function(activator) 
		local char = activator:GetCharacter()
		return char:GetData("banking_account") == 0
	end
})
PLUGIN:AddAnswer("bank_openitembox", {
	text = "I want to access itembox",
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")
			
			return acc ~= 0
	end,
	Execute = function(client)
		local bank = client:BankingAccount()

		if bank then
			local bankID = client:GetBankingID();
			local invID = bank.invID

			ix.item.instances[invID]:sync(client)
			netstream.Start(client, 'bank::openCollector', invID)
			PLUGIN:BankingLog("Bank itembox access", client:Name());
		end
	end
})
PLUGIN:AddAnswer("bank_depositmoney", {
	text = "I want to deposit money",
	callClick = {"bank_withdrawmoney", "bank_saymemoney", "bank_openitembox", "bank_depositcheck", "bank_repayLoan", "bank_depositmoney", "_bank_ex"},
	EntryCreate = true,
	talkBack = "bank_deposit",
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local money = activator:GetCharacter():GetMoney()
			local acc = char:GetData("banking_account")
			
			return acc ~= 0 and PLUGIN.bankINFO["money"] and money > 0;
	end,
	Execute = function(activator, val)
			val = tonumber(val)

			if activator.execCD and CurTime() < activator.execCD then
				ix.util.Notify("You need to wait "..math.Round(activator.execCD - CurTime()).." seconds to do an another procedure!")
				return;
			end;
			
			if val then
					activator:BankingOperation("Deposit", val)
					activator.execCD = CurTime() + 4;
			end
	end
})
PLUGIN:AddAnswer("bank_withdrawmoney", {
	text = "I want to withdraw money",
	callClick = {"bank_withdrawmoney", "bank_saymemoney", "bank_openitembox", "bank_depositcheck", "bank_repayLoan", "bank_depositmoney", "_bank_ex"},
	EntryCreate = true,
	talkBack = "bank_withdraw",
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")

			return acc ~= 0 and PLUGIN.bankINFO["money"] and PLUGIN.bankINFO["money"] > 0
	end,
	Execute = function(activator, val)
			val = tonumber(val)
			
			if activator.execCD and CurTime() < activator.execCD then
				ix.util.Notify("You need to wait "..math.Round(activator.execCD - CurTime()).." seconds to do an another procedure!")
				return;
			end;
			
			if val then
					activator:BankingOperation("Withdraw", val)
					activator.execCD = CurTime() + 4;
			end
	end
})
PLUGIN:AddAnswer("bank_depositcheck", {
	text = "Deposit a check",
	callClick = {"bank_openacc", "bank_saymemoney", "bank_withdrawmoney", "bank_openitembox", "bank_depositcheck", "bank_repayLoan", "bank_depositmoney", "_bank_ex"},
	EntryCreate = true,
	talkBack = "check_depo",
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")

			return acc ~= 0
	end,
	Execute = function(activator, val)
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")
			if acc == 0 then
					ix.util.Notify("You don't have a banking account.")
					return
			end
			local check = char:GetInventory():GetItems("check")
			val = tonumber(val)
			if !val then return; end
		
			for id, item in pairs(check) do
					local info = pon.decode(item:GetData("checkData"))
					local find = targe(activator, info.whoIs);
					local check = info.checkID;
					local amount = info.amount;
					if check == val then
						if find then
								local bankID = find:GetBankingID()
								if bankID ~= 0 then
										local banking = PLUGIN:BankingAccount(bankID)
										if banking["money"] >= amount then
												banking.money = banking.money - amount;
												PLUGIN:BankingSaveData(bankID, banking);										
												banking = PLUGIN:BankingAccount(acc);
												banking.money = banking.money + amount;
												PLUGIN:BankingSaveData(acc, banking);
												item:remove()	
												ix.util.Notify("Check is successfully deposited.")
												PLUGIN:BankingLog("Successfull check deposit with amount of "..amount, character:GetName(), 2);
												return;
										else
												ix.util.Notify("The owner of check don't have this amount of money on account.")
												PLUGIN:BankingLog("Check deposit attempt: FAILURE. Reason: the owner don't have enough money on account", character:GetName(), 1);
										end;
								else
										ix.util.Notify("The owner of this check don't have a banking account.")
										PLUGIN:BankingLog("Check deposit attempt: FAILURE. Reason: Invalid owner", character:GetName(), 1);
								end
						else
								ix.util.Notify("Can't find bank account owner named " .. info.whoIs)
								PLUGIN:BankingLog("Check deposit attempt: FAILURE. Reason: Invalid owner", character:GetName(), 1);
						end;
					else
							ix.util.Notify("You don't have a check with such ID: " .. val)
					end
			return;
			end;
			ix.util.Notify("You don't have a check with such ID: " .. val)
	end
})
PLUGIN:AddAnswer("bank_repayLoan", {
	text = "Repay loan",
	callClick = {"bank_withdrawmoney", "bank_saymemoney", "bank_openitembox", "bank_depositcheck", "bank_repayLoan", "bank_depositmoney", "_bank_ex"},
	EntryCreate = true,
	talkBack = "bank_loaned",
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")

			return acc ~= 0 and PLUGIN.bankINFO["loan"] and PLUGIN.bankINFO["loan"] > 0
	end,
	Execute = function(client, val)
			local bank = client:BankingAccount()
			local char = client:GetCharacter()
			local money = char:GetMoney()
			val = tonumber(val)
			if val and bank then
				if money >= val then
					char:takeMoney(val)
					bank.loan = math.max(bank.loan - val, 0);
					PLUGIN.generalFund = PLUGIN.generalFund + val
					if bank.loan == 0 then
							bank.startloan = 0;
							bank.bankeer = "None"
							bank.interest = 1
							bank.loanUpdate = ""
					end
					ix.util.Notify("You repaid " .. bank.startloan - bank.loan .. " out of " .. bank.startloan)
					PLUGIN:BankingLog("Loan repay with amount of "..val, character:GetName(), 2);
					client:BankingSaveData(bank)
				else
					ix.util.Notify("You don't have that amount of money to pay.")
				end;
			end
	end
})
PLUGIN:AddAnswer("bank_saymemoney", {
	text = "How much money do I have on a account?",
	OnOpen = true,
	CanShow = function(activator) 
			local char = activator:GetCharacter()
			local acc = char:GetData("banking_account")

			return acc ~= 0
	end,
	talkBack = "bank_acc_money_amount",
})
-- <><><><><><><><><><> Default answers <><><><><><><><><><> --

-- <><><><><><><><><><> Do's <><><><><><><><><><> --
PLUGIN:AddAnswer("bank_yes", {
	text = "Yes",
	callClick = {"bank_withdrawmoney", "bank_saymemoney", "bank_depositcheck", "bank_openitembox", "bank_repayLoan", "bank_depositmoney", "_bank_ex"},
	remClick = {"bank_yes", "bank_no"},
	talkBack = "bank_acc_open_succ",
	Execute = function(client)
			local char = client:GetCharacter()
			
			timer.Simple(0, function()
				char:SetData("banking_account", os.time() + 32)
				client:RegisterBanking(char:GetData("banking_account"));
			end)
	end,
})
PLUGIN:AddAnswer("bank_no", {
	text = "No",
	callClick = {"bank_openacc", "bank_regitembox", "bank_depositcheck", "_bank_ex"},
	remClick = {"bank_yes", "bank_no"},
	talkBack = "bank_acc_open_failed",
})
-- <><><><><><><><><><> Do's <><><><><><><><><><> --

-- <><><><><><><><><><> Functionality <><><><><><><><><><> --
PLUGIN:AddAnswer("_bank_ex", {
	text = "Exit",
	Close = true,
	OnOpen = true,
})

function PANEL:Init()
	self:SetContentAlignment(5)
	self:Dock(TOP)
	self:DockMargin(10, 0, 10, 0)
	self:SetCursor("hand")
	self:SetMouseInputEnabled( true )
end

function PANEL:SetData(index, data)
    self.data = data;
		self.index = index;

    self:Populate()
end;

function PANEL:Paint(w, h)
		if self:IsHovered() then
			if !self.soundPlayed then
				surface.PlaySound("helix/ui/rollover.wav")
				self:ColorTo(Color(255, 185, 138), .2, 0, function() self:SetColor(Color(255, 185, 138)) end);
				self.soundPlayed = true;
			end;
		elseif !self:IsHovered() then
			self:SetColor(color_white)
			self.soundPlayed = false;
		end
end;

function PANEL:Populate()
    if !self.data then return end
    local data = self.data
		
	self:SetText(data.text)
end

function PANEL:DoClick()
		local data = self.data
		local interface = PLUGIN.interface
		if !interface or data.close then PLUGIN.interface:Close() return end;
		local index = self.index;

		buff = interface:Reinform(data)

		if data.EntryCreate then
				interface.answers:Clear();
				interface.numEntry = interface.answers:Add("ModEntry")
				interface.numEntry:DockMargin(200, 5, 200, 5)

				interface.numEntry_btn = interface.answers:Add("ModLabel")
				interface.numEntry_btn:SetContentAlignment(5)
				interface.numEntry_btn:SetText("Enter")
				interface.numEntry_btn:Dock(TOP)
				interface.numEntry_btn:DockMargin(10, 0, 10, 0)
				interface.numEntry_btn:SetCursor("hand")
				interface.numEntry_btn:SetMouseInputEnabled( true )

				interface.numEntry_btn.DoClick = function(btn)
						if data.Execute and LocalPlayer():ValidateNPC("banking_npc") then
								netstream.Start('bankeer::exec', index, interface.numEntry:GetText())
						end

						timer.Simple(0, function()
							buff = interface:Reinform(data, true)
							interface:Remake(buff)
						end);
				end;
				return;
		end

		if data.Execute and LocalPlayer():ValidateNPC("banking_npc") then
				netstream.Start('bankeer::exec', index)
		end
			
		timer.Simple(0, function()
				buff = interface:Reinform(data)
				interface:Remake(buff)
		end)
end;

vgui.Register( "Answer", PANEL, "ModLabel" )