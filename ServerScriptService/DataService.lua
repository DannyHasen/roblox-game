local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local PlantData = require(Modules:WaitForChild("PlantData"))
local MutationData = require(Modules:WaitForChild("MutationData"))
local Utility = require(Modules:WaitForChild("Utility"))

local DataService = {}

DataService.PlayerData = {}
DataService.Dirty = {}
DataService.SaveLocks = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)

local function makeDefaultData()
	return {
		Version = 1,
		Cash = Config.StartingCash,
		Rebirths = 0,
		Inventory = Utility.DeepCopy(Config.StartingSeeds),
		Plants = {},
		Daily = {
			LastClaimDay = 0,
			Streak = 0,
		},
		LuckBoostUntil = 0,
		ShieldUntil = 0,
		Stats = {
			TotalHarvested = 0,
			TotalStolen = 0,
			TotalSpent = 0,
			TotalRebirths = 0,
		},
		LastSeen = os.time(),
	}
end

local function sanitizeInventory(inventory)
	local sanitized = {}

	if type(inventory) ~= "table" then
		inventory = {}
	end

	for seedId, amount in pairs(inventory) do
		if PlantData.Get(seedId) then
			sanitized[seedId] = Utility.ClampNumber(math.floor(tonumber(amount) or 0), 0, 999999, 0)
		end
	end

	for seedId, amount in pairs(Config.StartingSeeds) do
		if sanitized[seedId] == nil then
			sanitized[seedId] = amount
		end
	end

	return sanitized
end

local function sanitizePlants(plants)
	local sanitized = {}
	local usedIds = {}
	local usedSlots = {}

	if type(plants) ~= "table" then
		return sanitized
	end

	for _, plant in ipairs(plants) do
		if type(plant) == "table" and PlantData.Get(plant.SeedId) then
			local mutationId = plant.MutationId

			if not MutationData.Mutations[mutationId] then
				mutationId = MutationData.NormalId
			end

			local plantId = tostring(plant.Id or "")
			if plantId == "" or usedIds[plantId] then
				plantId = tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))
			end

			local slotIndex = math.floor(tonumber(plant.SlotIndex) or 0)
			if slotIndex < 1 or usedSlots[slotIndex] then
				slotIndex = 0
			end

			usedIds[plantId] = true
			if slotIndex > 0 then
				usedSlots[slotIndex] = true
			end

			table.insert(sanitized, {
				Id = plantId,
				SeedId = plant.SeedId,
				MutationId = mutationId,
				PlantedAt = Utility.ClampNumber(math.floor(tonumber(plant.PlantedAt) or os.time()), 0, os.time(), os.time()),
				SlotIndex = slotIndex,
			})
		end
	end

	return sanitized
end

local function sanitizeData(rawData)
	local data = makeDefaultData()

	if type(rawData) ~= "table" then
		return data
	end

	data.Version = 1
	data.Cash = Utility.ClampNumber(math.floor(tonumber(rawData.Cash) or Config.StartingCash), 0, 999999999999, Config.StartingCash)
	data.Rebirths = Utility.ClampNumber(math.floor(tonumber(rawData.Rebirths) or 0), 0, 100000, 0)
	data.Inventory = sanitizeInventory(rawData.Inventory)
	data.Plants = sanitizePlants(rawData.Plants)

	if type(rawData.Daily) == "table" then
		data.Daily.LastClaimDay = Utility.ClampNumber(math.floor(tonumber(rawData.Daily.LastClaimDay) or 0), 0, 999999, 0)
		data.Daily.Streak = Utility.ClampNumber(math.floor(tonumber(rawData.Daily.Streak) or 0), 0, Config.DailyRewardMaxStreak, 0)
	end

	data.LuckBoostUntil = Utility.ClampNumber(math.floor(tonumber(rawData.LuckBoostUntil) or 0), 0, 9999999999, 0)
	data.ShieldUntil = Utility.ClampNumber(math.floor(tonumber(rawData.ShieldUntil) or 0), 0, 9999999999, 0)

	if type(rawData.Stats) == "table" then
		for key, value in pairs(data.Stats) do
			data.Stats[key] = Utility.ClampNumber(math.floor(tonumber(rawData.Stats[key]) or value), 0, 999999999999, value)
		end
	end

	data.LastSeen = Utility.ClampNumber(math.floor(tonumber(rawData.LastSeen) or os.time()), 0, 9999999999, os.time())

	return data
end

function DataService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function DataService:Start()
	self.Remotes.GetSnapshot.OnServerInvoke = function(player)
		return self:BuildSnapshot(player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)

			for _, player in ipairs(Players:GetPlayers()) do
				self:SavePlayer(player)
			end
		end
	end)
end

function DataService:LoadPlayer(player)
	local key = "Player_" .. player.UserId
	local loadedData
	local success = false

	for attempt = 1, Config.MaxSaveRetries do
		success, loadedData = pcall(function()
			return store:GetAsync(key)
		end)

		if success then
			break
		end

		warn(("[DataService] Load failed for %s attempt %d: %s"):format(player.Name, attempt, tostring(loadedData)))
		task.wait(attempt)
	end

	if not success then
		self:Notify(player, "DataStore unavailable. Playing with fresh session data.")
	end

	self.PlayerData[player.UserId] = sanitizeData(loadedData)
	self.Dirty[player.UserId] = false
	self:SetupLeaderstats(player)
end

function DataService:SavePlayer(player)
	local data = self:GetData(player)

	if not data or self.SaveLocks[player.UserId] then
		return false
	end

	self.SaveLocks[player.UserId] = true
	data.LastSeen = os.time()

	local key = "Player_" .. player.UserId
	local dataToSave = Utility.DeepCopy(data)
	local success = false
	local err

	for attempt = 1, Config.MaxSaveRetries do
		success, err = pcall(function()
			store:SetAsync(key, dataToSave)
		end)

		if success then
			break
		end

		warn(("[DataService] Save failed for %s attempt %d: %s"):format(player.Name, attempt, tostring(err)))
		task.wait(attempt)
	end

	if success then
		self.Dirty[player.UserId] = false
	else
		self:Notify(player, "Save is retrying in the background.")
	end

	self.SaveLocks[player.UserId] = nil
	return success
end

function DataService:ForgetPlayer(player)
	self.PlayerData[player.UserId] = nil
	self.Dirty[player.UserId] = nil
	self.SaveLocks[player.UserId] = nil
end

function DataService:GetData(player)
	return self.PlayerData[player.UserId]
end

function DataService:GetDataByUserId(userId)
	return self.PlayerData[userId]
end

function DataService:GetAllData()
	return self.PlayerData
end

function DataService:MarkDirty(player)
	self.Dirty[player.UserId] = true
end

function DataService:SetupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cash = leaderstats:FindFirstChild("Cash") or Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats

	local rebirths = leaderstats:FindFirstChild("Rebirths") or Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats

	self:UpdateLeaderstats(player)
end

function DataService:UpdateLeaderstats(player)
	local data = self:GetData(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not data or not leaderstats then
		return
	end

	local cash = leaderstats:FindFirstChild("Cash")
	local rebirths = leaderstats:FindFirstChild("Rebirths")

	if cash then
		cash.Value = math.clamp(math.floor(data.Cash), 0, 2147483647)
	end

	if rebirths then
		rebirths.Value = data.Rebirths
	end
end

function DataService:GetRebirthCashMultiplier(player)
	local data = self:GetData(player)
	local rebirths = data and data.Rebirths or 0

	return 1 + (rebirths * Config.RebirthCashMultiplierPerRebirth)
end

function DataService:GetRebirthCost(player)
	local data = self:GetData(player)
	local rebirths = data and data.Rebirths or 0

	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths))
end

function DataService:AddCash(player, amount, reason)
	local data = self:GetData(player)

	if not data then
		return false
	end

	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 then
		return false
	end

	data.Cash = math.clamp(data.Cash + amount, 0, 999999999999)

	if reason == "Harvest" then
		data.Stats.TotalHarvested += amount
	elseif reason == "Steal" then
		data.Stats.TotalStolen += amount
	end

	self:MarkDirty(player)
	self:UpdateLeaderstats(player)
	self:Push(player)

	return true
end

function DataService:SpendCash(player, amount)
	local data = self:GetData(player)

	if not data then
		return false
	end

	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 or data.Cash < amount then
		return false
	end

	data.Cash -= amount
	data.Stats.TotalSpent += amount

	self:MarkDirty(player)
	self:UpdateLeaderstats(player)
	self:Push(player)

	return true
end

function DataService:AddSeed(player, seedId, amount)
	local data = self:GetData(player)

	if not data or not PlantData.Get(seedId) then
		return false
	end

	amount = math.floor(tonumber(amount) or 1)

	if amount <= 0 then
		return false
	end

	data.Inventory[seedId] = math.clamp((data.Inventory[seedId] or 0) + amount, 0, 999999)

	self:MarkDirty(player)
	self:Push(player)

	return true
end

function DataService:RemoveSeed(player, seedId, amount)
	local data = self:GetData(player)

	if not data or not PlantData.Get(seedId) then
		return false
	end

	amount = math.floor(tonumber(amount) or 1)

	if amount <= 0 or (data.Inventory[seedId] or 0) < amount then
		return false
	end

	data.Inventory[seedId] -= amount

	self:MarkDirty(player)
	self:Push(player)

	return true
end

function DataService:Notify(player, message, tone)
	if self.Remotes and self.Remotes.Notify then
		self.Remotes.Notify:FireClient(player, tostring(message), tone or "Info")
	end
end

function DataService:Push(player)
	if not self.Remotes or not self.Remotes.StateUpdate then
		return
	end

	self.Remotes.StateUpdate:FireClient(player, self:BuildSnapshot(player))
end

function DataService:BuildSnapshot(player)
	local data = self:GetData(player)

	if not data then
		return nil
	end

	local services = self.Context.Services
	local plantSummaries = {}
	local shop = {}
	local canClaimDaily = false
	local dailyReward = Config.DailyRewardBase
	local totalMultiplier = self:GetRebirthCashMultiplier(player)
	local maxPlants = Config.BaseMaxPlants

	if services.PlantService then
		plantSummaries = services.PlantService:GetPlantSummaries(player)
	end

	if services.ShopService then
		shop = services.ShopService:GetShopForPlayer(player)
	end

	if services.RewardService then
		canClaimDaily = services.RewardService:CanClaim(player)
		dailyReward = services.RewardService:GetRewardAmount(player)
	end

	if services.MonetizationService then
		totalMultiplier = services.MonetizationService:GetTotalCashMultiplier(player)
		maxPlants = services.MonetizationService:GetMaxPlants(player)
	end

	return {
		GameName = Config.GameName,
		Cash = data.Cash,
		Rebirths = data.Rebirths,
		RebirthCost = self:GetRebirthCost(player),
		CashMultiplier = totalMultiplier,
		Inventory = Utility.DeepCopy(data.Inventory),
		Plants = plantSummaries,
		MaxPlants = maxPlants,
		CanClaimDaily = canClaimDaily,
		DailyReward = dailyReward,
		DailyStreak = data.Daily.Streak,
		Shop = shop,
		LuckyBoostRemaining = math.max(0, data.LuckBoostUntil - os.time()),
		ShieldRemaining = math.max(0, data.ShieldUntil - os.time()),
	}
end

return DataService
