local PLUGIN = PLUGIN

PLUGIN.bankingAccounts = PLUGIN.bankingAccounts or {}
PLUGIN.bankingLogs	= PLUGIN.bankingLogs or {}
PLUGIN.generalFund	= PLUGIN.generalFund or 0

local entitiesList = {
	"banking_atm",
	"banking_computer",
	"banking_npc",
	"banking_vault"
}

function PLUGIN:SaveData()
	ix.data.Set("banking_accounts", self.bankingAccounts)
	ix.data.Set("banking_logs", self.bankingLogs)
	ix.data.Set("general_fund", self.generalFund)

	local entities = {}
	for i = 1, #entitiesList do
		for k, v in ipairs(ents.FindByClass(entitiesList[i])) do
			entities[#entities+1] = {
				class = v:GetClass(),
				pos	= v:GetPos(),
				angles = v:GetAngles(),
				model = v:GetModel(),
				scenario = v.scenario or nil,
				spawned = v.spawned or true
			}
		end
	end
		
	ix.data.Set("banking_entities", entities)
end

function PLUGIN:LoadData()
		local bAccounts = ix.data.Get("banking_accounts", {})
		local bLogs = ix.data.Get("banking_logs", {})
		local bFund = ix.data.Get("general_fund", 0)
		local bEntites = ix.data.Get("banking_entities", {})

		self.bankingAccounts = bAccounts;
		self.generalFund = bFund;
		self.bankingLogs = bLogs;

		for id, entity in ipairs(bEntites) do
				local ent = ents.Create(entity.class)
				ent:SetPos(entity.pos)
				ent:SetAngles(entity.angles)
				ent:SetModel(entity.model)
				ent.spawned = entity.spawned or false;
				ent:Spawn()
				ent.scenario = entity.scenario or nil;
		end

		for k, v in pairs(bAccounts) do
				v = pon.decode(v)
				if v.invID and v.invID ~= 0 then
					ix.item.loadByID(v.invID)
						:next(function(item) 				
							hook.Run("BankingAccess", item)
					end)
				end
		end
end

function PLUGIN:AnswerExists(index)
		return self.Answers[index];
end;

function PLUGIN:PlayerLoadedCharacter(client, character, lastChar)
		timer.Simple(0.25, function()
				character:SetData("banking_account", character:GetData("banking_account", 0))
		end)

		local acc = client:BankingAccount();
		local id = client:GetBankingID()

		client.usedVault = "";

		if acc then
			if acc.invID ~= 0 then
				ix.item.loadByID(acc.invID)
				:next(function(item) 				
						hook.Run("BankingAccess", item)
						item:sync(client)
				end)
			end;

			local date = os.date( "%d.%m.%y %H:%M:%S" , os.time() );

			if acc.loan ~= 0 and acc.loanUpdate <= date then
					acc.loanUpdate = os.date("%d.%m.%y %H:%M:%S", os.time()+24*60*60);
					acc.loan = math.Round(acc.loan + (acc.loan * acc.interest/100))
					self:BankingSaveData(client:GetBankingID(), acc)
			end
		end;
end;

function PLUGIN:CharacterPreSave(character)
	local client = character:GetPlayer()
	if (IsValid(client)) then
 		character:SetData("banking_account", character:GetData("banking_account", 0))
	end
end


function PLUGIN:PlayerDeath(victim, inflictor, attacker)
		local ent = victim.usedVault
		if ent ~= "" then
			if IsEntity(ent) then
				victim.usedVault.used = false;
				ent:CallShutDown()

				net.Start(victim, 'bank::CloseVaultClientside')
			end
			victim.usedVault = ""
		end
end;

function PLUGIN:PlayerDisconnected(user)
		local ent = user.usedVault
		if ent ~= "" then
			if IsEntity(ent) then
				user.usedVault.used = false;
				ent:CallShutDown()

				net.Start(user, 'bank::CloseVaultClientside')
			end;
			user.usedVault = "";
		end
end;