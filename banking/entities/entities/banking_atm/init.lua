local PLUGIN = PLUGIN;

include("shared.lua"); 
AddCSLuaFile("cl_init.lua"); 
AddCSLuaFile("shared.lua");

function ENT:Initialize()
	self:SetModel(self:GetDefaultModel())
	self:DrawShadow(true);
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE);

	local physObj = self:GetPhysicsObject();
	if (IsValid(physObj)) then 
			physObj:EnableMotion(false); 
			physObj:Sleep(); 
	end;

	for k, v in pairs(ents.FindInBox(self:LocalToWorld(self:OBBMins()), self:LocalToWorld(self:OBBMaxs()))) do
		if (string.find(v:GetClass(), "prop") and v:GetModel() == model) then
			self:SetPos(v:GetPos());
			self:SetAngles(v:GetAngles());
			SafeRemoveEntity(v);
			return;
		end;
	end;
end;

function ENT:Use(activator)
		if activator:GetBankingID() ~= 0 then
			activator:SyncBanking()
			netstream.Start(activator, 'Bank::OpenATM')
				PLUGIN:BankingLog("Access to banking ATM", activator:GetName(), 1);
		else
			ix.util.Notify("You need to register a banking account to access this ATM!")
		end;
end;