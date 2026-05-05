local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))

local TradeService = {}

function TradeService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function TradeService:Start()
	self.Remotes.RequestTrade.OnServerEvent:Connect(function(player, action, payload)
		self:HandleRequest(player, action, payload)
	end)
end

function TradeService:HandleRequest(player, action, payload)
	local dataService = self.Context.Services.DataService

	if action == "Ping" and type(payload) == "table" then
		local targetUserId = tonumber(payload.TargetUserId)
		local target = targetUserId and Players:GetPlayerByUserId(targetUserId)

		if not target or target == player then
			dataService:Notify(player, "Pick another player to trade with.", "Warning")
			return
		end

		dataService:Notify(player, "Trade ping sent to " .. target.DisplayName .. ".", "Success")
		dataService:Notify(target, player.DisplayName .. " wants to trade. Full trading is the next upgrade.", "Info")
		return
	end

	dataService:Notify(player, "Trading placeholder is online. Trade ping works; item escrow comes next.", "Info")
end

function TradeService:GetTradeStatus(_player)
	return {
		Enabled = true,
		Mode = "Placeholder",
		Message = "Trade pings are enabled. Safe item escrow is planned next.",
	}
end

return TradeService
