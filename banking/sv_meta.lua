local PLUGIN = PLUGIN;

local user = FindMetaTable("Player")

function user:BankingOperation(operation, num)
		local money = self:GetMoney();
		local bank = self:BankingAccount()
		local char = self:GetCharacter()

		if !bank or num == 0 then return end;

		num = math.abs(num)
		if operation == "Deposit" then
			if money >= num then
					bank.money = bank.money + num;
					self:BankingSaveData(bank);
					char:TakeMoney(num)
					self:NotifyLocalized("You deposited " .. nut.currency.get(num) )
					PLUGIN:BankingLog("Money deposit with amount of "..nut.currency.get(num).." to account #"..self:GetBankingID(), self:Name())
			else
					self:NotifyLocalized("You don't have enough money.")
			end
		elseif operation == "Withdraw" then
			if bank.money - num >= 0 then				
					bank.money = bank.money - num;
					self:BankingSaveData(bank);
					char:GiveMoney(num)
					self:NotifyLocalized("You withdrawed " ..nut.currency.get(num) )
					PLUGIN:BankingLog("Money withdraw with amount of " .. nut.currency.get(num).." from account #"..self:GetBankingID(), self:Name())
			else
					self:NotifyLocalized("Your bank account don't have enough money.")
			end
		end;
end;

function user:RegisterBanking(id)
		if !PLUGIN.bankingAccounts[id] then
				PLUGIN.bankingAccounts[id] = pon.encode({
						name = self:GetName(),
						bankeer = "None",
						startloan = 0,
						loan = 0,
						money = 0,
						interest = 1,
						invID = 0,
						loanUpdate = "",
				})
				self:SyncBanking()
				PLUGIN:BankingLog("Banking account register with id: #"..id, self:GetName(), 2)
				ix.inventory.New("grid", {w = 10, h = 10},
				function(inventory)
						inventory.id = inventory:GetID()
						--hook.Run("BankingAccess", inventory)
						local data = self:BankingAccount()
						data.invID = inventory.id
						self:BankingSaveData(data)
						inventory:Sync(self)
				end)
		end
end

function user:GetBankingID()
		return self:GetCharacter():GetData("banking_account")
end;

function user:BankingAccount()
		local bank = self:GetBankingID()

		if bank ~= 0 and !PLUGIN:BankingAccount(bank) then
				self:GetCharacter():SetData("banking_account", 0)
				return false;
		end

		return bank ~= 0 and PLUGIN:BankingAccount(bank);
end;

function user:BankingSaveData(data)
		local id = self:GetBankingID()
		if id then
				PLUGIN.bankingAccounts[id] = pon.encode(data);

				self:SyncBanking()
		end;
end;

function user:RemoveBanking()
		local bank = self:BankingAccount()

		if bank then
			local id = self:GetBankingID();

			ix.item.instances[bank.invID] = nil;
			PLUGIN.bankingAccounts[id] = nil;
			self:GetCharacter():SetData("banking_account", 0)
		end
end;

function user:SyncBanking()
		if self:BankingAccount() then
				netstream.Start(self, 'bank::sendAccInfo', pon.encode(self:BankingAccount()))
		end
end;

--[[
<><><><><><><><><> PLUGIN META: <><><><><><><><><>
--]]
function PLUGIN:BankingAccount(id)
		return self.bankingAccounts[id] and pon.decode(self.bankingAccounts[id])
end;

function PLUGIN:BankingSaveData(id, data)
		local acc = self:BankingAccount(id)
		if acc then
				self.bankingAccounts[id] = pon.encode(data);
		end
end;

function PLUGIN:RemoveBanking(id)
		local bank = self:BankingAccount(id)
		if bank then
			ix.item.instances[bank.invID] = nil;
			self.bankingAccounts[id] = nil;
		end
end;

function PLUGIN:CheckCanRob()
		local int = 0;
		if !SCHEMA.isEmpireFaction then return true end;
		for k, v in ipairs(player.GetAll()) do
			if v:IsValid() and v:GetCharacter() then
					if SCHEMA:isEmpireFaction(v:GetCharacter():GetFaction()) then
							int = int + 1;
							if int >= 3 then
									return true
							end
					end
			end
		end
		return false
end

function PLUGIN:BankingLog(text, whoIs, priority)
		local date = os.date("%m/%d/%y %I:%M %p")
		local index = #self.bankingLogs

		if !priority then priority = 0 end
		
		self.bankingLogs[index + 1] = pon.encode({
			text = text, 
			whoIs = whoIs,
			date = date,
			priority = priority,
		})
end