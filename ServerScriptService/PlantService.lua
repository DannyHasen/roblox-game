local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local PlantData = require(Modules:WaitForChild("PlantData"))
local MutationData = require(Modules:WaitForChild("MutationData"))
local Utility = require(Modules:WaitForChild("Utility"))

local PlantService = {}

PlantService.PlantModels = {}
PlantService.RequestCooldowns = {}
PlantService.HarvestCooldowns = {}
PlantService.SellAllCooldowns = {}
PlantService.StealCooldowns = {}

local function createPlantPart(parent, name, shape, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function makeBillboard(parent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlantBillboard"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(180, 78)
	gui.StudsOffset = Vector3.new(0, 3.3, 0)
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 0.16
	label.BackgroundColor3 = Color3.fromRGB(18, 24, 28)
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	return gui, label
end

function PlantService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
	self.Random = Random.new()
end

function PlantService:Start()
	self.Remotes.RequestPlant.OnServerEvent:Connect(function(player, seedId)
		self:PlantSeed(player, seedId)
	end)

	self.Remotes.RequestSellAll.OnServerEvent:Connect(function(player)
		self:SellAll(player)
	end)

	task.spawn(function()
		while true do
			task.wait(2)
			self:UpdateAllPlantVisuals()
		end
	end)
end

function PlantService:GetNow()
	return os.time()
end

function PlantService:IsGrown(plant)
	local seed = PlantData.Get(plant.SeedId)

	if not seed then
		return false
	end

	return self:GetNow() - plant.PlantedAt >= seed.GrowthTime
end

function PlantService:GetGrowthPercent(plant)
	local seed = PlantData.Get(plant.SeedId)

	if not seed then
		return 0
	end

	return math.clamp((self:GetNow() - plant.PlantedAt) / seed.GrowthTime, 0.05, 1)
end

function PlantService:PlantSeed(player, seedId)
	if type(seedId) ~= "string" then
		return
	end

	local now = os.clock()
	local lastRequest = self.RequestCooldowns[player.UserId] or 0

	if now - lastRequest < Config.PlantRequestCooldown then
		return
	end

	self.RequestCooldowns[player.UserId] = now

	local seed = PlantData.Get(seedId)
	local dataService = self.Context.Services.DataService
	local gardenService = self.Context.Services.GardenService
	local monetizationService = self.Context.Services.MonetizationService
	local data = dataService:GetData(player)

	if not seed or not data then
		return
	end

	if (data.Inventory[seedId] or 0) <= 0 then
		dataService:Notify(player, "You need a " .. seed.DisplayName .. " seed first.", "Warning")
		return
	end

	if seed.RebirthRequired > data.Rebirths then
		dataService:Notify(player, seed.DisplayName .. " unlocks after rebirth " .. seed.RebirthRequired .. ".", "Warning")
		return
	end

	local maxPlants = monetizationService:GetMaxPlants(player)

	if #data.Plants >= maxPlants then
		dataService:Notify(player, "Your garden is full. Harvest or rebirth to free space.", "Warning")
		return
	end

	local slotIndex = gardenService:GetFreeSlot(player, data.Plants, maxPlants)

	if not slotIndex then
		dataService:Notify(player, "No open garden slots found.", "Warning")
		return
	end

	if not dataService:RemoveSeed(player, seedId, 1) then
		return
	end

	local plant = {
		Id = HttpService:GenerateGUID(false),
		SeedId = seedId,
		MutationId = self:RollMutation(player),
		PlantedAt = self:GetNow(),
		SlotIndex = slotIndex,
	}

	table.insert(data.Plants, plant)
	dataService:MarkDirty(player)
	self:CreatePlantModel(player, plant)

	local mutation = MutationData.Get(plant.MutationId)
	if mutation.Id == MutationData.NormalId then
		dataService:Notify(player, "Planted " .. seed.DisplayName .. ".", "Success")
	else
		dataService:Notify(player, "Mutation hit: " .. mutation.DisplayName .. " " .. seed.DisplayName .. "!", "Success")
	end

	dataService:Push(player)
end

function PlantService:RollMutation(player)
	local data = self.Context.Services.DataService:GetData(player)
	local chance = Config.BaseMutationChance

	if data and data.LuckBoostUntil > self:GetNow() then
		chance += Config.LuckyMutationBoostChance
	end

	chance = math.clamp(chance, 0, 0.95)

	if self.Random:NextNumber() > chance then
		return MutationData.NormalId
	end

	local mutation = Utility.WeightedChoice(MutationData.GetMutationPool(), self.Random)

	return mutation and mutation.Id or MutationData.NormalId
end

function PlantService:CreatePlantModel(player, plant)
	local gardenService = self.Context.Services.GardenService
	local plot = gardenService:GetPlot(player)

	if not plot then
		return nil
	end

	self:DestroyPlantModel(plant.Id)

	local seed = PlantData.Get(plant.SeedId)
	local mutation = MutationData.Get(plant.MutationId)

	if not seed or not mutation then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = mutation.DisplayName .. " " .. seed.DisplayName
	model:SetAttribute("PlantId", plant.Id)
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = plot.PlantsFolder

	local slotCFrame = gardenService:GetSlotCFrame(player, plant.SlotIndex)
	local stem = createPlantPart(model, "Stem", Enum.PartType.Cylinder, Vector3.new(0.55, 1, 0.55), slotCFrame, Color3.fromRGB(78, 168, 74), Enum.Material.SmoothPlastic)
	local fruitShape = Enum.PartType.Ball

	if seed.Shape == "Root" or seed.Shape == "Cactus" then
		fruitShape = Enum.PartType.Cylinder
	elseif seed.Shape == "Gourd" or seed.Shape == "Blob" then
		fruitShape = Enum.PartType.Ball
	end

	local fruitColor = seed.Color:Lerp(mutation.Color, mutation.Id == MutationData.NormalId and 0 or 0.42)
	local fruit = createPlantPart(model, "Fruit", fruitShape, Vector3.new(2, 2, 2), slotCFrame, fruitColor, mutation.Material)
	local billboard, label = makeBillboard(fruit)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HarvestPrompt"
	prompt.ActionText = "Harvest / Steal"
	prompt.ObjectText = seed.DisplayName
	prompt.HoldDuration = 0.55
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = fruit

	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer.UserId == player.UserId then
			self:Harvest(triggeringPlayer, plant.Id)
		else
			self:Steal(triggeringPlayer, plant.Id)
		end
	end)

	model.PrimaryPart = fruit

	self.PlantModels[plant.Id] = {
		Model = model,
		Stem = stem,
		Fruit = fruit,
		Billboard = billboard,
		Label = label,
		Prompt = prompt,
		OwnerUserId = player.UserId,
	}

	self:UpdatePlantVisual(plant)
	return model
end

function PlantService:UpdateAllPlantVisuals()
	for plantId in pairs(self.PlantModels) do
		local _, plant = self:FindPlantById(plantId)

		if plant then
			self:UpdatePlantVisual(plant)
		else
			self:DestroyPlantModel(plantId)
		end
	end
end

function PlantService:UpdatePlantVisual(plant)
	local entry = self.PlantModels[plant.Id]
	local seed = PlantData.Get(plant.SeedId)
	local mutation = MutationData.Get(plant.MutationId)

	if not entry or not seed or not mutation then
		return
	end

	local owner = Players:GetPlayerByUserId(entry.OwnerUserId)
	local gardenService = self.Context.Services.GardenService
	local slotCFrame = owner and gardenService:GetSlotCFrame(owner, plant.SlotIndex)

	if not slotCFrame then
		return
	end

	local growth = self:GetGrowthPercent(plant)
	local scale = mutation.Scale
	local stemHeight = math.max(0.35, 4.2 * growth * scale)
	local fruitSize = math.max(0.7, 2.4 * growth * scale)

	entry.Stem.Size = Vector3.new(0.55 * scale, stemHeight, 0.55 * scale)
	entry.Stem.CFrame = slotCFrame * CFrame.new(0, stemHeight / 2, 0)
	entry.Fruit.Size = Vector3.new(fruitSize, fruitSize, fruitSize)
	entry.Fruit.CFrame = slotCFrame * CFrame.new(0, stemHeight + (fruitSize / 2), 0)

	local remaining = math.max(0, seed.GrowthTime - (self:GetNow() - plant.PlantedAt))
	local grown = remaining <= 0
	local mutationPrefix = mutation.Id == MutationData.NormalId and "" or (mutation.DisplayName .. " ")
	local value = self:GetBasePlantValue(plant)

	if grown then
		entry.Label.Text = mutationPrefix .. seed.DisplayName .. "\nReady $" .. Utility.FormatNumber(value)
	else
		entry.Label.Text = mutationPrefix .. seed.DisplayName .. "\n" .. tostring(remaining) .. "s"
	end

	entry.Label.TextColor3 = Config.RarityColors[seed.Rarity] or Color3.new(1, 1, 1)
	entry.Prompt.Enabled = grown
end

function PlantService:DestroyPlantModel(plantId)
	local entry = self.PlantModels[plantId]

	if entry then
		entry.Model:Destroy()
		self.PlantModels[plantId] = nil
	end
end

function PlantService:LoadPlayerPlants(player)
	local data = self.Context.Services.DataService:GetData(player)
	local gardenService = self.Context.Services.GardenService

	if not data then
		return
	end

	local maxPlants = Config.BaseMaxPlants + Config.VipExtraPlantSlots
	local used = {}
	local sanitizedPlants = {}

	for _, plant in ipairs(data.Plants) do
		if PlantData.Get(plant.SeedId) and #sanitizedPlants < maxPlants then
			if plant.SlotIndex < 1 or plant.SlotIndex > maxPlants or used[plant.SlotIndex] then
				plant.SlotIndex = gardenService:GetFreeSlot(player, sanitizedPlants, maxPlants) or 1
			end

			used[plant.SlotIndex] = true
			table.insert(sanitizedPlants, plant)
			self:CreatePlantModel(player, plant)
		end
	end

	data.Plants = sanitizedPlants
end

function PlantService:HandlePlayerRemoving(player)
	local data = self.Context.Services.DataService:GetData(player)

	if not data then
		return
	end

	for _, plant in ipairs(data.Plants) do
		self:DestroyPlantModel(plant.Id)
	end
end

function PlantService:FindPlantById(plantId)
	for ownerUserId, data in pairs(self.Context.Services.DataService:GetAllData()) do
		for index, plant in ipairs(data.Plants) do
			if plant.Id == plantId then
				return ownerUserId, plant, index, data
			end
		end
	end

	return nil
end

function PlantService:GetBasePlantValue(plant)
	local seed = PlantData.Get(plant.SeedId)
	local mutation = MutationData.Get(plant.MutationId)

	if not seed then
		return 0
	end

	return math.floor(seed.HarvestValue * mutation.Multiplier)
end

function PlantService:GetHarvestValue(player, plant)
	local monetizationService = self.Context.Services.MonetizationService

	return math.floor(self:GetBasePlantValue(plant) * monetizationService:GetTotalCashMultiplier(player))
end

function PlantService:Harvest(player, plantId)
	local now = os.clock()
	local lastRequest = self.HarvestCooldowns[player.UserId] or 0

	if now - lastRequest < Config.HarvestRequestCooldown then
		return
	end

	self.HarvestCooldowns[player.UserId] = now

	local ownerUserId, plant, index, data = self:FindPlantById(plantId)
	local dataService = self.Context.Services.DataService

	if not plant or ownerUserId ~= player.UserId then
		return
	end

	if not self:IsGrown(plant) then
		dataService:Notify(player, "That plant is still cooking.", "Warning")
		return
	end

	local amount = self:GetHarvestValue(player, plant)
	local entry = self.PlantModels[plant.Id]
	local position = entry and entry.Fruit.Position

	table.remove(data.Plants, index)
	self:DestroyPlantModel(plant.Id)
	dataService:AddCash(player, amount, "Harvest")
	dataService:MarkDirty(player)
	dataService:Notify(player, "+$" .. Utility.FormatNumber(amount) .. " harvested.", "Success")
	self:FireFloatingText(player, position, "+$" .. Utility.FormatNumber(amount), Color3.fromRGB(99, 255, 129))
	dataService:Push(player)
end

function PlantService:SellAll(player)
	local now = os.clock()
	local lastRequest = self.SellAllCooldowns[player.UserId] or 0

	if now - lastRequest < Config.SellAllCooldown then
		return
	end

	self.SellAllCooldowns[player.UserId] = now

	local dataService = self.Context.Services.DataService
	local data = dataService:GetData(player)

	if not data then
		return
	end

	local total = 0
	local count = 0

	for index = #data.Plants, 1, -1 do
		local plant = data.Plants[index]

		if self:IsGrown(plant) then
			total += self:GetHarvestValue(player, plant)
			count += 1
			self:DestroyPlantModel(plant.Id)
			table.remove(data.Plants, index)
		end
	end

	if count <= 0 then
		dataService:Notify(player, "No fully grown plants to sell yet.", "Warning")
		return
	end

	dataService:AddCash(player, total, "Harvest")
	dataService:MarkDirty(player)
	dataService:Notify(player, ("Sold %d plants for $%s."):format(count, Utility.FormatNumber(total)), "Success")
	dataService:Push(player)
end

function PlantService:Steal(thief, plantId)
	local dataService = self.Context.Services.DataService
	local now = self:GetNow()
	local cooldownUntil = self.StealCooldowns[thief.UserId] or 0

	if cooldownUntil > now then
		dataService:Notify(thief, "Steal cooldown: " .. tostring(cooldownUntil - now) .. "s.", "Warning")
		return
	end

	local ownerUserId, plant, index, ownerData = self:FindPlantById(plantId)
	local owner = ownerUserId and Players:GetPlayerByUserId(ownerUserId)

	if not plant or not owner or owner == thief then
		return
	end

	if ownerData.ShieldUntil > now then
		dataService:Notify(thief, "That garden is shielded for " .. tostring(ownerData.ShieldUntil - now) .. "s.", "Warning")
		return
	end

	if not self:IsGrown(plant) then
		return
	end

	local baseValue = self:GetBasePlantValue(plant)
	local thiefReward = math.floor(baseValue * Config.StealRewardPercent * self.Context.Services.MonetizationService:GetTotalCashMultiplier(thief))
	local ownerInsurance = math.floor(baseValue * Config.OwnerInsurancePercent * self.Context.Services.MonetizationService:GetTotalCashMultiplier(owner))
	local entry = self.PlantModels[plant.Id]
	local position = entry and entry.Fruit.Position
	local seed = PlantData.Get(plant.SeedId)

	self.StealCooldowns[thief.UserId] = now + Config.StealCooldown
	ownerData.ShieldUntil = now + Config.ShieldSecondsAfterSteal
	table.remove(ownerData.Plants, index)
	self:DestroyPlantModel(plant.Id)

	dataService:AddCash(thief, thiefReward, "Steal")
	dataService:AddCash(owner, ownerInsurance, "Harvest")
	dataService:MarkDirty(owner)
	dataService:Notify(thief, "You raided " .. owner.DisplayName .. "'s " .. seed.DisplayName .. " for $" .. Utility.FormatNumber(thiefReward) .. ".", "Success")
	dataService:Notify(owner, thief.DisplayName .. " stole a " .. seed.DisplayName .. ". Shield active, insurance paid.", "Warning")
	self:FireFloatingText(thief, position, "+$" .. Utility.FormatNumber(thiefReward), Color3.fromRGB(255, 221, 83))
	dataService:Push(thief)
	dataService:Push(owner)
end

function PlantService:FireFloatingText(player, position, text, color)
	if not position or not self.Remotes.FloatingText then
		return
	end

	self.Remotes.FloatingText:FireClient(player, position, text, color)
end

function PlantService:ClearPlayerPlants(player)
	local data = self.Context.Services.DataService:GetData(player)

	if not data then
		return
	end

	for _, plant in ipairs(data.Plants) do
		self:DestroyPlantModel(plant.Id)
	end

	data.Plants = {}
	self.Context.Services.DataService:MarkDirty(player)
end

function PlantService:GetPlantSummaries(player)
	local data = self.Context.Services.DataService:GetData(player)
	local summaries = {}

	if not data then
		return summaries
	end

	for _, plant in ipairs(data.Plants) do
		local seed = PlantData.Get(plant.SeedId)
		local mutation = MutationData.Get(plant.MutationId)

		if seed and mutation then
			table.insert(summaries, {
				Id = plant.Id,
				SeedId = plant.SeedId,
				SeedName = seed.DisplayName,
				Rarity = seed.Rarity,
				MutationId = mutation.Id,
				MutationName = mutation.DisplayName,
				Multiplier = mutation.Multiplier,
				Remaining = math.max(0, seed.GrowthTime - (self:GetNow() - plant.PlantedAt)),
				Ready = self:IsGrown(plant),
				Value = self:GetHarvestValue(player, plant),
			})
		end
	end

	return summaries
end

return PlantService
