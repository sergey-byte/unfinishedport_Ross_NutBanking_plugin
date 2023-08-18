local PLUGIN = PLUGIN
PLUGIN.name = "Banking plugin"
PLUGIN.author = "Ross Cattero"
PLUGIN.description = "Banking plugin done by Ross."

ix.flag.Add("B", "Access to banking")

ix.util.Include("sh_meta.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sv_meta.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_plugin.lua")
ix.util.Include("sv_access_rules.lua")
ix.util.Include("sh_answer.lua")

if CLIENT then
	surface.CreateFont( "Generic Banking", {
		font = "Quicksand Light",
		size = ScreenScale( 9 ),
		outline = true,
	})
	surface.CreateFont( "Banking handly", {
		font = "Indie Flower",
		extended = false,
		size = ScreenScale( 8 ),
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking handly big", {
		font = "Indie Flower",
		extended = false,
		size = ScreenScale( 11 ),
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking typo little", {
		font = "Times New Roman",
		extended = false,
		size = ScreenScale( 6 ),
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking typo", {
		font = "Times New Roman",
		extended = false,
		size = ScreenScale( 6 ),
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking typo big", {
		font = "Times New Roman",
		extended = false,
		size = ScreenScale( 12 ),
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking info", {
		font = "Courier New",
		extended = false,
		size = ScreenScale( 7 ),
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
	surface.CreateFont( "Banking info smaller", {
		font = "Consolas",
		extended = false,
		size = ScreenScale( 6 ),
		antialias = true,
	})
	surface.CreateFont( "Banking id", {
		font = "Consolas",
		extended = false,
		size = ScreenScale( 7 ),
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
	})
end

ix.command.Add("setFunds", {
	description = "",
	adminOnly = true,
	OnRun = function(client, arguments)
			local value = tonumber(arguments[1]) or 0;

			PLUGIN.generalFund = value
			ix.util.Notify("The amount of general fund is set to: "..value .. nut.currency.symbol)
			PLUGIN:BankingLog("Global banking fund changed to "..value, client:Name(), 1)
	end
})

ix.command.Add("bank", {
	description = "",
	adminOnly = true,
	onCheckAccess = function(client)
			return client:GetCharacter():HasFlags("B")
	end,
	OnRun = function(client, arguments)
			if client:GetCharacter():HasFlags("B") then
				local data = pon.encode({PLUGIN.bankingAccounts, PLUGIN.generalFund})
				net.Start(client, "bank::openBanking", data)
				PLUGIN:BankingLog("Access to banking data", client:Name(), 1);
			else
				ix.util.Notify("You don't know the password to access to the banking database.")
			end
	end
})

ix.command.Add("bankLogs", {
	description = "",
	adminOnly = true,
	onCheckAccess = function(client)
			return client:GetCharacter():HasFlags("B")
	end,
	OnRun = function(client, arguments)
		if client:GetCharacter():HasFlags("B") then
			local data = pon.encode(PLUGIN.bankingLogs);
			net.Start(client, "bank::OpenLogsList", data)
		else
			ix.util.Notify("You don't know the password to access to the banking database.")
		end
	end
})