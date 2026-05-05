local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local Utility = require(Modules:WaitForChild("Utility"))

local RebirthService = {}

function RebirthService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function RebirthService:Start()
	self.Remotes.RequestRebirth.OnServerEvent:Connect(function(player)
		self:TryRebirth(player)
	end)
end

function RebirthService:TryRebirth(player)
	local dataService = self.Context.Services.DataService
	local plantService = self.Context.Services.PlantService
	local data = dataService:GetData(player)

	if not data then
		return
	end

	local cost = dataService:GetRebirthCost(player)

	if data.Cash < cost then
		dataService:Notify(player, "Rebirth needs $" .. Utility.FormatNumber(cost) .. ".", "Warning")
		return
	end

	plantService:ClearPlayerPlants(player)

	data.Rebirths += 1
	data.Stats.TotalRebirths = data.Rebirths
	data.Cash = Config.StartingCash
	data.Inventory = Utility.DeepCopy(Config.StartingSeeds)
	data.ShieldUntil = math.max(data.ShieldUntil, os.time() + 30)

	dataService:MarkDirty(player)
	dataService:UpdateLeaderstats(player)
	dataService:Notify(player, "Rebirth complete. Permanent cash multiplier increased!", "Success")
	dataService:Push(player)
end

return RebirthService
