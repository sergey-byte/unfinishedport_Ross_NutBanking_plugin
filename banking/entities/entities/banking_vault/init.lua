include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local PLUGIN = PLUGIN

function ENT:Initialize()
	self:SetModel("models/myproject/mesh_0989.mdl")
	self:DrawShadow(true)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local physObj = self:GetPhysicsObject()
	if (IsValid(physObj)) then 
			physObj:EnableMotion(false);
			physObj:Sleep()
	end;

	self.scenario = 1
	self.passwd = ""

	self.used = false

	self.DataService = {}

	for k, v in pairs(ents.FindInBox(self:LocalToWorld(self:OBBMins()), self:LocalToWorld(self:OBBMaxs()))) do
		if (string.find(v:GetClass(), "prop") and v:GetModel() == model) then
			self:SetPos(v:GetPos())
			self:SetAngles(v:GetAngles())
			SafeRemoveEntity(v)
			return
		end
	end

	local filter = RecipientFilter()
	filter:AddAllPlayers()
	self.LoopingSound = CreateSound(self, "ambient/machines/lab_loop1.wav", filter)
	self.AlarmSound = CreateSound(self, "ambient/alarms/combine_bank_alarm_loop4.wav", filter)
		
	self:PendData()
	self.LoopingSound:Play();
	timer.Create(self:EntIndex() .. " - make a counts", PLUGIN.vaultScenario[self.scenario]["TIME"], 0, function()
			if !self:IsValid() then
				timer.Remove(self:EntIndex() .. " - make a counts")
				return;
			end

			self:PendData()
	end)
end
function ENT:Use(activator)

		if self.UseCD and CurTime() < self.UseCD then
				ix.util.Notify("< Use cooldown >")
				return;
		end

		if activator:KeyDown(IN_SPEED) and (activator:IsAdmin() or activator:IsSuperAdmin()) then
			self.scenario = self.scenario + 1;

			if self.scenario > #PLUGIN.vaultScenario then
				self.scenario = 1;
			end
			ix.util.Notify("Scenario is changed to " .. PLUGIN.vaultScenario[self.scenario].NAME)
			self:PendData()
			self.UseCD = CurTime() + 3;
			return;
		end
		if !PLUGIN:CheckCanRob() then 
			ix.util.Notify("You can't rob the vault right now!")
			return 
		end;
		
		self.UseCD = CurTime() + 2;

		if self:GetShutDown() then 
			ix.util.Notify("This vault is in shutdown!")
			return 
		end;
		if !self.used and activator.usedVault == "" then
			if self.DataService["stack"] then
					self.used = true;
					activator.usedVault = self
					local vault = pon.encode(self.DataService)
					local timeLeft = timer.TimeLeft(self:EntIndex() .. " - make a counts")
					activator.attempts = PLUGIN.vaultScenario[self.scenario].ATTEMPTS
					netstream.Start(activator, 'bank::hackVault', vault, self.scenario, timeLeft, PLUGIN.generalFund)

					self:NotifyForces()
			else
					ix.util.Notify("The data for this vault is still pending...")
			end;
		else
				ix.util.Notify("Somebody is already using this vault.")
		end
end;

function ENT:PendData()

			local vault = PLUGIN.vaultScenario[self.scenario];
			local inter = vault.INTER;
			local passPointer = 1;
			local STACK = {};
			local POSITIONS = {}
			local binary = vault.BINARY;

			if binary > 15 then binary = 15 end;
			if inter > binary then inter = binary end;

			for i = 1, inter do
				local num = bit.tohex(math.random(-256, 255), 2)
				self.passwd = self.passwd .. num;
			end
			self.passwd = self.passwd:upper()

			for line = 0, binary do
					if line <= binary then
							local int = bit.tohex(math.random(-255, 254), 2)
							int = int:upper();

							STACK[line] = {}
							STACK[line][int] = {};

							for i = 0, binary do
									STACK[line][int][i] = bit.tohex(math.random(-255, 254), 2):upper();
							end
					end
			end

			for i = 0, binary do
					local ranLine = math.random(0, binary)
					for k, v in pairs(STACK[ranLine]) do
							local ranIndex = math.random(0, binary) 
							local subPass = self.passwd:sub(passPointer, passPointer+1)
							if passPointer+1 > #self.passwd then break end;
							
							if passPointer+1 <= #self.passwd and STACK[ranLine][k][ranIndex] ~= subPass then
									STACK[ranLine][k][ranIndex] = subPass;							
							end

							local TAG = math.IntToBin("0x" .. k);
							local column = math.IntToBin(ranIndex);
							local row = math.IntToBin(ranLine);
							POSITIONS[#POSITIONS + 1] = TAG .. column .. row;
							passPointer = passPointer + 2;
					end	
			end

			self.DataService = {
					stack = pon.encode(STACK),
					positions = pon.encode(POSITIONS)
			}
end;

function ENT:CallShutDown()
	self.LoopingSound:Stop()
	self:EmitSound("ambient/machines/thumper_shutdown1.wav")
	self:SetShutDown(true)
	self.AlarmSound:Play()
	self:PendData()

	timer.Create(self:EntIndex() .. " - alarm", 60, 1, function()
		if !self:IsValid() then
			timer.Remove(self:EntIndex() .. " - alarm")
			return;
		end
		self:SetShutDown(false)
		if self.AlarmSound then
				self.AlarmSound:Stop()
		end;
		
		timer.Simple(1, function()
				self.LoopingSound:Play();
		end)
		
		end)
end;

function ENT:OnRemove()
	if self.LoopingSound then
			self.LoopingSound:Stop();
	end;
	if self.AlarmSound then
			self.AlarmSound:Stop()
	end;
end;

function ENT:NotifyForces()
		if SCHEMA.isEmpireFactivatorion then
				for k, v in ipairs(player.GetAll()) do
					if SCHEMA:isEmpireFactivatorion(v:GetCharacter():getFactivatorion()) then
						ix.util.Notify("[BANK VAULT] BANK VAULT HACK ALERT!")
					end
				end
		end;
end;