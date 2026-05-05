local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local PlantData = require(Modules:WaitForChild("PlantData"))
local Utility = require(Modules:WaitForChild("Utility"))

local ShopService = {}

function ShopService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function ShopService:Start()
	self.Remotes.RequestBuySeed.OnServerEvent:Connect(function(player, seedId, quantity)
		self:BuySeed(player, seedId, quantity)
	end)
end

function ShopService:BuySeed(player, seedId, quantity)
	if type(seedId) ~= "string" then
		return
	end

	local seed = PlantData.Get(seedId)
	local dataService = self.Context.Services.DataService
	local data = dataService:GetData(player)

	if not seed or not data then
		return
	end

	quantity = math.floor(tonumber(quantity) or 1)
	quantity = math.clamp(quantity, 1, 25)

	if seed.RebirthRequired > data.Rebirths then
		dataService:Notify(player, seed.DisplayName .. " unlocks after rebirth " .. seed.RebirthRequired .. ".", "Warning")
		return
	end

	local cost = seed.Cost * quantity

	if not dataService:SpendCash(player, cost) then
		dataService:Notify(player, "Need $" .. Utility.FormatNumber(cost) .. " for that seed.", "Warning")
		return
	end

	dataService:AddSeed(player, seedId, quantity)
	dataService:Notify(player, ("Bought %dx %s."):format(quantity, seed.DisplayName), "Success")
	dataService:Push(player)
end

function ShopService:GetShopForPlayer(player)
	local data = self.Context.Services.DataService:GetData(player)
	local shop = {}

	if not data then
		return shop
	end

	for _, seed in ipairs(PlantData.GetOrderedSeeds()) do
		table.insert(shop, {
			Id = seed.Id,
			DisplayName = seed.DisplayName,
			Rarity = seed.Rarity,
			Cost = seed.Cost,
			GrowthTime = seed.GrowthTime,
			HarvestValue = seed.HarvestValue,
			RebirthRequired = seed.RebirthRequired,
			Owned = data.Inventory[seed.Id] or 0,
			Unlocked = data.Rebirths >= seed.RebirthRequired,
			Color = Config.RarityColors[seed.Rarity] or Color3.new(1, 1, 1),
		})
	end

	return shop
end

return ShopService
