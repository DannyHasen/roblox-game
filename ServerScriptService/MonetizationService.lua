local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local Utility = require(Modules:WaitForChild("Utility"))

local MonetizationService = {}

MonetizationService.GamePassCache = {}
MonetizationService.ProductIdToKey = {}

function MonetizationService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes

	for productKey, product in pairs(Config.DeveloperProducts) do
		if product.Id and product.Id > 0 then
			self.ProductIdToKey[product.Id] = productKey
		end
	end
end

function MonetizationService:Start()
	self.Remotes.RequestProductPurchase.OnServerEvent:Connect(function(player, productKey)
		self:PromptProduct(player, productKey)
	end)

	self.Remotes.RequestGamePassPurchase.OnServerEvent:Connect(function(player, gamePassKey)
		self:PromptGamePass(player, gamePassKey)
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		for gamePassKey, gamePass in pairs(Config.GamePasses) do
			if gamePass.Id == gamePassId then
				self.GamePassCache[player.UserId .. ":" .. gamePassKey] = true
				self.Context.Services.DataService:Notify(player, gamePass.DisplayName .. " unlocked.", "Success")
				self.Context.Services.DataService:Push(player)
				break
			end
		end
	end)
end

function MonetizationService:PromptProduct(player, productKey)
	local product = Config.DeveloperProducts[productKey]
	local dataService = self.Context.Services.DataService

	if not product then
		return
	end

	if not product.Id or product.Id <= 0 then
		dataService:Notify(player, product.DisplayName .. " is wired. Add the real product ID in Config.lua.", "Warning")
		return
	end

	MarketplaceService:PromptProductPurchase(player, product.Id)
end

function MonetizationService:PromptGamePass(player, gamePassKey)
	local gamePass = Config.GamePasses[gamePassKey]
	local dataService = self.Context.Services.DataService

	if not gamePass then
		return
	end

	if not gamePass.Id or gamePass.Id <= 0 then
		dataService:Notify(player, gamePass.DisplayName .. " is wired. Add the real game pass ID in Config.lua.", "Warning")
		return
	end

	MarketplaceService:PromptGamePassPurchase(player, gamePass.Id)
end

function MonetizationService:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productKey = self.ProductIdToKey[receiptInfo.ProductId]

	if not productKey then
		warn("[MonetizationService] Unknown developer product id: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local granted = self:GrantProduct(player, productKey)

	if granted then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService:GrantProduct(player, productKey)
	local product = Config.DeveloperProducts[productKey]
	local dataService = self.Context.Services.DataService
	local data = dataService:GetData(player)

	if not product or not data then
		return false
	end

	if productKey == "LuckyMutationBoost" then
		local now = os.time()
		data.LuckBoostUntil = math.max(data.LuckBoostUntil, now) + Config.LuckyMutationBoostSeconds
		dataService:MarkDirty(player)
		dataService:Notify(player, "Lucky mutation boost activated.", "Success")
		dataService:Push(player)
		return true
	end

	if product.Cash and product.Cash > 0 then
		dataService:AddCash(player, product.Cash, "Product")
		dataService:Notify(player, "+" .. Utility.FormatNumber(product.Cash) .. " cash delivered.", "Success")
		return true
	end

	return false
end

function MonetizationService:HasGamePass(player, gamePassKey)
	local gamePass = Config.GamePasses[gamePassKey]

	if not gamePass or not gamePass.Id or gamePass.Id <= 0 then
		return false
	end

	local cacheKey = player.UserId .. ":" .. gamePassKey

	if self.GamePassCache[cacheKey] ~= nil then
		return self.GamePassCache[cacheKey]
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePass.Id)
	end)

	if not success then
		warn("[MonetizationService] Game pass check failed: " .. tostring(owns))
		owns = false
	end

	self.GamePassCache[cacheKey] = owns
	return owns
end

function MonetizationService:GetTotalCashMultiplier(player)
	local multiplier = self.Context.Services.DataService:GetRebirthCashMultiplier(player)

	if self:HasGamePass(player, "DoubleCash") then
		multiplier *= 2
	end

	return multiplier
end

function MonetizationService:GetMaxPlants(player)
	local maxPlants = Config.BaseMaxPlants

	if self:HasGamePass(player, "VipGarden") then
		maxPlants += Config.VipExtraPlantSlots
	end

	return maxPlants
end

return MonetizationService
