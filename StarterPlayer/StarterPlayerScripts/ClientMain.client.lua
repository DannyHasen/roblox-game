local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local modules = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local Config = require(modules:WaitForChild("Config"))
local PlantData = require(modules:WaitForChild("PlantData"))
local Utility = require(modules:WaitForChild("Utility"))

local Remotes = {}
for remoteKey, remoteName in pairs(Config.RemoteNames) do
	Remotes[remoteKey] = remotesFolder:WaitForChild(remoteName)
end

local state = nil
local selectedSeedId = "BasicBean"
local activePanel = nil
local panelContent = nil
local panelTitle = nil
local tutorialStep = 1
local tutorialDismissed = false
local ui = {}

local function create(className, props, children)
	local instance = Instance.new(className)

	for key, value in pairs(props or {}) do
		instance[key] = value
	end

	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end

	return instance
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
		Parent = parent,
	})
end

local function addStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 1,
		Transparency = transparency or 0.65,
		Parent = parent,
	})
end

local function makeLabel(parent, text, size, color, font)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = font or Enum.Font.GothamBold,
		Text = text,
		TextColor3 = color or Config.Ui.Text,
		TextSize = size or 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})

	return label
end

local function makeButton(parent, text, color)
	local button = create("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color or Config.Ui.Primary,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15,
		TextWrapped = true,
		Parent = parent,
	})
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(255, 255, 255), 1, 0.82)

	return button
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))

	if seconds >= 60 then
		return tostring(math.floor(seconds / 60)) .. "m " .. tostring(seconds % 60) .. "s"
	end

	return tostring(seconds) .. "s"
end

local function getInventoryCount(seedId)
	if not state or not state.Inventory then
		return 0
	end

	return state.Inventory[seedId] or 0
end

local function pickBestOwnedSeed()
	if not state or not state.Inventory then
		return "BasicBean"
	end

	if (state.Inventory[selectedSeedId] or 0) > 0 then
		return selectedSeedId
	end

	for index = #PlantData.Order, 1, -1 do
		local seedId = PlantData.Order[index]

		if (state.Inventory[seedId] or 0) > 0 then
			return seedId
		end
	end

	return "BasicBean"
end

local function showToast(message, tone)
	local toast = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = tone == "Warning" and Config.Ui.Warning or tone == "Success" and Config.Ui.Primary or Config.Ui.Panel,
		Position = UDim2.new(1, -12, 0, 76 + (#ui.ToastContainer:GetChildren() * 50)),
		Size = UDim2.fromOffset(310, 42),
		Font = Enum.Font.GothamBold,
		Text = tostring(message),
		TextColor3 = tone == "Warning" and Color3.fromRGB(33, 28, 14) or Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextWrapped = true,
		Parent = ui.ToastContainer,
	})
	addCorner(toast, 8)
	addStroke(toast, Color3.fromRGB(255, 255, 255), 1, 0.76)

	task.delay(3, function()
		if not toast.Parent then
			return
		end

		local tween = TweenService:Create(toast, TweenInfo.new(0.28), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
end

local function clearContent()
	for _, child in ipairs(panelContent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function closePanel()
	activePanel = nil
	ui.Panel.Visible = false
end

local function openPanel(title)
	activePanel = title
	panelTitle.Text = title
	ui.Panel.Visible = true
	clearContent()
end

local function requestPlant(seedId)
	selectedSeedId = seedId or pickBestOwnedSeed()
	Remotes.RequestPlant:FireServer(selectedSeedId)

	if tutorialStep == 1 then
		tutorialStep = 2
	end
end

local function makeRow(parent, height)
	local row = create("Frame", {
		BackgroundColor3 = Config.Ui.PanelLight,
		Size = UDim2.new(1, 0, 0, height or 72),
		Parent = parent,
	})
	addCorner(row, 8)
	addStroke(row, Color3.fromRGB(255, 255, 255), 1, 0.86)

	return row
end

local function renderShop()
	openPanel("Seed Shop")

	local hint = makeLabel(panelContent, "Buy seeds, plant them, harvest cash, then chase rarer mutations.", 14, Config.Ui.Muted, Enum.Font.Gotham)
	hint.Size = UDim2.new(1, -8, 0, 34)

	for _, item in ipairs((state and state.Shop) or {}) do
		local row = makeRow(panelContent, 86)
		local rarityColor = item.Color or Config.RarityColors[item.Rarity] or Config.Ui.Primary

		local stripe = create("Frame", {
			BackgroundColor3 = rarityColor,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 7, 1, 0),
			Parent = row,
		})
		addCorner(stripe, 8)

		local name = makeLabel(row, item.DisplayName .. " [" .. item.Rarity .. "]", 16, Config.Ui.Text, Enum.Font.GothamBlack)
		name.Position = UDim2.fromOffset(16, 7)
		name.Size = UDim2.new(1, -132, 0, 24)

		local details = makeLabel(row, ("$%s | %s | pays $%s | owned %d"):format(
			Utility.FormatNumber(item.Cost),
			formatTime(item.GrowthTime),
			Utility.FormatNumber(item.HarvestValue),
			item.Owned
		), 13, Config.Ui.Muted, Enum.Font.Gotham)
		details.Position = UDim2.fromOffset(16, 36)
		details.Size = UDim2.new(1, -132, 0, 38)

		local buy = makeButton(row, item.Unlocked and "Buy" or ("R" .. tostring(item.RebirthRequired)), item.Unlocked and Config.Ui.Primary or Color3.fromRGB(91, 91, 91))
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -10, 0.5, 0)
		buy.Size = UDim2.fromOffset(92, 48)
		buy.Activated:Connect(function()
			if item.Unlocked then
				Remotes.RequestBuySeed:FireServer(item.Id, 1)
			else
				showToast("Unlocks after rebirth " .. item.RebirthRequired .. ".", "Warning")
			end
		end)
	end

	local boostHeader = makeLabel(panelContent, "Boosts", 18, Config.Ui.Text, Enum.Font.GothamBlack)
	boostHeader.Size = UDim2.new(1, 0, 0, 34)

	local boostRow = makeRow(panelContent, 160)
	local grid = create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.new(0.5, -8, 0, 44),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = boostRow,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = boostRow,
	})

	local doubleCash = makeButton(boostRow, "2x Cash", Color3.fromRGB(64, 164, 255))
	doubleCash.Activated:Connect(function()
		Remotes.RequestGamePassPurchase:FireServer("DoubleCash")
	end)

	local vip = makeButton(boostRow, "VIP Garden", Color3.fromRGB(255, 183, 66))
	vip.Activated:Connect(function()
		Remotes.RequestGamePassPurchase:FireServer("VipGarden")
	end)

	local luck = makeButton(boostRow, "Lucky Boost", Color3.fromRGB(192, 92, 255))
	luck.Activated:Connect(function()
		Remotes.RequestProductPurchase:FireServer("LuckyMutationBoost")
	end)

	local cashPack = makeButton(boostRow, "Cash Pack", Color3.fromRGB(60, 210, 128))
	cashPack.Activated:Connect(function()
		Remotes.RequestProductPurchase:FireServer("MediumCashPack")
	end)

	grid.Parent = boostRow

	if tutorialStep == 2 then
		tutorialStep = 3
	end
end

local function renderInventory()
	openPanel("Inventory")

	local plantHint = makeLabel(panelContent, "Selected seed: " .. (PlantData.Get(selectedSeedId) and PlantData.Get(selectedSeedId).DisplayName or "Basic Bean"), 15, Config.Ui.Muted, Enum.Font.Gotham)
	plantHint.Size = UDim2.new(1, 0, 0, 30)

	local shown = 0

	for _, seedId in ipairs(PlantData.Order) do
		local seed = PlantData.Get(seedId)
		local count = getInventoryCount(seedId)

		if count > 0 then
			shown += 1
			local row = makeRow(panelContent, 76)
			local name = makeLabel(row, seed.DisplayName, 16, Config.RarityColors[seed.Rarity] or Config.Ui.Text, Enum.Font.GothamBlack)
			name.Position = UDim2.fromOffset(14, 8)
			name.Size = UDim2.new(1, -128, 0, 26)

			local detail = makeLabel(row, ("Owned %d | %s | pays $%s"):format(count, formatTime(seed.GrowthTime), Utility.FormatNumber(seed.HarvestValue)), 13, Config.Ui.Muted, Enum.Font.Gotham)
			detail.Position = UDim2.fromOffset(14, 38)
			detail.Size = UDim2.new(1, -128, 0, 24)

			local plantButton = makeButton(row, selectedSeedId == seedId and "Planting" or "Plant", selectedSeedId == seedId and Config.Ui.PrimaryDark or Config.Ui.Primary)
			plantButton.AnchorPoint = Vector2.new(1, 0.5)
			plantButton.Position = UDim2.new(1, -10, 0.5, 0)
			plantButton.Size = UDim2.fromOffset(98, 46)
			plantButton.Activated:Connect(function()
				requestPlant(seedId)
			end)
		end
	end

	if shown == 0 then
		local empty = makeLabel(panelContent, "No seeds yet. Open the shop and buy Basic Bean seeds.", 16, Config.Ui.Muted, Enum.Font.Gotham)
		empty.Size = UDim2.new(1, 0, 0, 54)
	end
end

local function renderRebirth()
	openPanel("Rebirth")

	local cost = state and state.RebirthCost or Config.RebirthBaseCost
	local multiplier = state and state.CashMultiplier or 1

	local info = makeLabel(panelContent, ("Cost: $%s\nCurrent multiplier: %.2fx\nAfter rebirth: %.2fx\nCash and garden reset, permanent multiplier stays."):format(
		Utility.FormatNumber(cost),
		multiplier,
		multiplier + Config.RebirthCashMultiplierPerRebirth
	), 18, Config.Ui.Text, Enum.Font.GothamBold)
	info.Size = UDim2.new(1, -8, 0, 150)
	info.TextXAlignment = Enum.TextXAlignment.Center

	local rebirthButton = makeButton(panelContent, "Rebirth", Config.Ui.Warning)
	rebirthButton.Size = UDim2.new(1, 0, 0, 58)
	rebirthButton.TextColor3 = Color3.fromRGB(35, 25, 10)
	rebirthButton.Activated:Connect(function()
		Remotes.RequestRebirth:FireServer()
	end)
end

local function renderTrade()
	openPanel("Trade")

	local hint = makeLabel(panelContent, "Send a trade ping. Safe item escrow is stubbed for the next build.", 14, Config.Ui.Muted, Enum.Font.Gotham)
	hint.Size = UDim2.new(1, 0, 0, 42)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local row = makeRow(panelContent, 68)
			local name = makeLabel(row, otherPlayer.DisplayName, 17, Config.Ui.Text, Enum.Font.GothamBlack)
			name.Position = UDim2.fromOffset(14, 0)
			name.Size = UDim2.new(1, -132, 1, 0)

			local ping = makeButton(row, "Ping", Config.Ui.Primary)
			ping.AnchorPoint = Vector2.new(1, 0.5)
			ping.Position = UDim2.new(1, -10, 0.5, 0)
			ping.Size = UDim2.fromOffset(96, 44)
			ping.Activated:Connect(function()
				Remotes.RequestTrade:FireServer("Ping", {
					TargetUserId = otherPlayer.UserId,
				})
			end)
		end
	end
end

local function updateTutorial()
	if tutorialDismissed then
		ui.Tutorial.Visible = false
		return
	end

	ui.Tutorial.Visible = true

	if tutorialStep == 1 then
		ui.TutorialText.Text = "Tap Plant to start your first weird garden."
		ui.Tutorial.Position = UDim2.new(0.5, 0, 1, -214)
	elseif tutorialStep == 2 then
		ui.TutorialText.Text = "Nice. Plants grow on timers. Harvest prompts appear when ready."
		ui.Tutorial.Position = UDim2.new(0.5, 0, 1, -214)
	else
		ui.TutorialText.Text = "Open Shop for rarer seeds, boosts, and mutation flexing."
		ui.Tutorial.Position = UDim2.new(0.5, 0, 1, -214)
	end
end

local function updateUiFromState(refreshPanel)
	if not state then
		return
	end

	selectedSeedId = pickBestOwnedSeed()
	local selectedSeed = PlantData.Get(selectedSeedId)
	local plantCount = state.Plants and #state.Plants or 0

	ui.CashLabel.Text = "$" .. Utility.FormatNumber(state.Cash)
	ui.RebirthLabel.Text = "R " .. tostring(state.Rebirths)
	ui.MultiplierLabel.Text = string.format("%.2fx", state.CashMultiplier or 1)
	ui.PlantButton.Text = "Plant\n" .. (selectedSeed and selectedSeed.DisplayName or "Seed")
	ui.PlantCountLabel.Text = tostring(plantCount) .. "/" .. tostring(state.MaxPlants or Config.BaseMaxPlants)
	ui.DailyButton.BackgroundColor3 = state.CanClaimDaily and Config.Ui.Warning or Config.Ui.PanelLight
	ui.DailyButton.TextColor3 = state.CanClaimDaily and Color3.fromRGB(34, 26, 9) or Config.Ui.Text

	if state.LuckyBoostRemaining and state.LuckyBoostRemaining > 0 then
		ui.BoostLabel.Text = "Luck " .. formatTime(state.LuckyBoostRemaining)
	else
		ui.BoostLabel.Text = "Luck ready"
	end

	if refreshPanel and activePanel == "Seed Shop" then
		renderShop()
	elseif refreshPanel and activePanel == "Inventory" then
		renderInventory()
	elseif refreshPanel and activePanel == "Rebirth" then
		renderRebirth()
	end

	updateTutorial()
end

local function buildUi()
	local screenGui = playerGui:FindFirstChild("MainUI")

	if not screenGui then
		screenGui = create("ScreenGui", {
			Name = "MainUI",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 10,
			Parent = playerGui,
		})
	end

	for _, child in ipairs(screenGui:GetChildren()) do
		child:Destroy()
	end

	ui.ScreenGui = screenGui
	ui.ToastContainer = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = screenGui,
	})

	local topBar = create("Frame", {
		BackgroundColor3 = Config.Ui.Panel,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 58),
		Parent = screenGui,
	})
	addCorner(topBar, 8)
	addStroke(topBar, Color3.fromRGB(255, 255, 255), 1, 0.78)

	local title = makeLabel(topBar, "Mutation Garden Wars", 18, Config.Ui.Text, Enum.Font.GothamBlack)
	title.Position = UDim2.fromOffset(12, 0)
	title.Size = UDim2.new(0.36, 0, 1, 0)

	ui.CashLabel = makeLabel(topBar, "$100", 18, Color3.fromRGB(117, 255, 145), Enum.Font.GothamBlack)
	ui.CashLabel.Position = UDim2.new(0.38, 0, 0, 0)
	ui.CashLabel.Size = UDim2.new(0.24, 0, 1, 0)
	ui.CashLabel.TextXAlignment = Enum.TextXAlignment.Center

	ui.RebirthLabel = makeLabel(topBar, "R 0", 16, Config.Ui.Warning, Enum.Font.GothamBlack)
	ui.RebirthLabel.Position = UDim2.new(0.63, 0, 0, 0)
	ui.RebirthLabel.Size = UDim2.new(0.12, 0, 1, 0)
	ui.RebirthLabel.TextXAlignment = Enum.TextXAlignment.Center

	ui.MultiplierLabel = makeLabel(topBar, "1.00x", 16, Color3.fromRGB(116, 223, 255), Enum.Font.GothamBlack)
	ui.MultiplierLabel.Position = UDim2.new(0.76, 0, 0, 0)
	ui.MultiplierLabel.Size = UDim2.new(0.12, 0, 1, 0)
	ui.MultiplierLabel.TextXAlignment = Enum.TextXAlignment.Center

	ui.PlantCountLabel = makeLabel(topBar, "0/12", 16, Config.Ui.Muted, Enum.Font.GothamBlack)
	ui.PlantCountLabel.Position = UDim2.new(0.89, 0, 0, 0)
	ui.PlantCountLabel.Size = UDim2.new(0.1, -8, 1, 0)
	ui.PlantCountLabel.TextXAlignment = Enum.TextXAlignment.Center

	local actionBar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Config.Ui.Panel,
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 136),
		Parent = screenGui,
	})
	addCorner(actionBar, 8)
	addStroke(actionBar, Color3.fromRGB(255, 255, 255), 1, 0.78)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = actionBar,
	})
	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.new(0.25, -8, 0, 56),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = actionBar,
	})

	ui.PlantButton = makeButton(actionBar, "Plant", Config.Ui.Primary)
	ui.ShopButton = makeButton(actionBar, "Shop", Color3.fromRGB(64, 164, 255))
	ui.InventoryButton = makeButton(actionBar, "Inventory", Config.Ui.PanelLight)
	ui.RebirthButton = makeButton(actionBar, "Rebirth", Color3.fromRGB(128, 86, 255))
	ui.DailyButton = makeButton(actionBar, "Daily", Config.Ui.Warning)
	ui.TradeButton = makeButton(actionBar, "Trade", Color3.fromRGB(255, 118, 190))
	ui.SellAllButton = makeButton(actionBar, "Sell All", Color3.fromRGB(255, 123, 83))
	ui.PlotButton = makeButton(actionBar, "Plot", Color3.fromRGB(78, 208, 178))

	ui.BoostLabel = makeLabel(screenGui, "Luck ready", 14, Config.Ui.Text, Enum.Font.GothamBold)
	ui.BoostLabel.AnchorPoint = Vector2.new(1, 0)
	ui.BoostLabel.BackgroundColor3 = Config.Ui.Panel
	ui.BoostLabel.BackgroundTransparency = 0.08
	ui.BoostLabel.Position = UDim2.new(1, -12, 0, 72)
	ui.BoostLabel.Size = UDim2.fromOffset(140, 28)
	ui.BoostLabel.TextXAlignment = Enum.TextXAlignment.Center
	addCorner(ui.BoostLabel, 8)

	ui.Panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Config.Ui.Panel,
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.new(0.92, 0, 0.68, 0),
		Visible = false,
		Parent = screenGui,
	})
	addCorner(ui.Panel, 8)
	addStroke(ui.Panel, Color3.fromRGB(255, 255, 255), 1, 0.62)
	create("UISizeConstraint", {
		MaxSize = Vector2.new(760, 540),
		MinSize = Vector2.new(300, 320),
		Parent = ui.Panel,
	})

	local header = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 54),
		Parent = ui.Panel,
	})

	panelTitle = makeLabel(header, "Panel", 20, Config.Ui.Text, Enum.Font.GothamBlack)
	panelTitle.Position = UDim2.fromOffset(16, 0)
	panelTitle.Size = UDim2.new(1, -78, 1, 0)

	local close = makeButton(header, "X", Config.Ui.Danger)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -12, 0.5, 0)
	close.Size = UDim2.fromOffset(44, 40)
	close.Activated:Connect(closePanel)

	panelContent = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromOffset(12, 58),
		ScrollBarThickness = 6,
		Size = UDim2.new(1, -24, 1, -70),
		Parent = ui.Panel,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panelContent,
	})
	create("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
		Parent = panelContent,
	})

	ui.Tutorial = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.5, 0, 1, -214),
		Size = UDim2.fromOffset(330, 74),
		Visible = false,
		Parent = screenGui,
	})
	addCorner(ui.Tutorial, 8)
	addStroke(ui.Tutorial, Config.Ui.Primary, 2, 0.08)

	ui.TutorialText = makeLabel(ui.Tutorial, "", 15, Color3.fromRGB(27, 39, 32), Enum.Font.GothamBlack)
	ui.TutorialText.Position = UDim2.fromOffset(12, 8)
	ui.TutorialText.Size = UDim2.new(1, -62, 1, -16)

	ui.TutorialArrow = makeLabel(ui.Tutorial, "v", 22, Config.Ui.Primary, Enum.Font.GothamBlack)
	ui.TutorialArrow.AnchorPoint = Vector2.new(0.5, 0)
	ui.TutorialArrow.Position = UDim2.new(0.5, 0, 1, -7)
	ui.TutorialArrow.Size = UDim2.fromOffset(28, 24)
	ui.TutorialArrow.TextXAlignment = Enum.TextXAlignment.Center

	local tutorialClose = makeButton(ui.Tutorial, "OK", Config.Ui.Primary)
	tutorialClose.AnchorPoint = Vector2.new(1, 0.5)
	tutorialClose.Position = UDim2.new(1, -10, 0.5, 0)
	tutorialClose.Size = UDim2.fromOffset(44, 42)
	tutorialClose.Activated:Connect(function()
		tutorialDismissed = true
		updateTutorial()
	end)

	ui.PlantButton.Activated:Connect(function()
		requestPlant(pickBestOwnedSeed())
	end)

	ui.ShopButton.Activated:Connect(renderShop)
	ui.InventoryButton.Activated:Connect(renderInventory)
	ui.RebirthButton.Activated:Connect(renderRebirth)
	ui.TradeButton.Activated:Connect(renderTrade)

	ui.DailyButton.Activated:Connect(function()
		Remotes.RequestDailyReward:FireServer()
	end)

	ui.SellAllButton.Activated:Connect(function()
		Remotes.RequestSellAll:FireServer()
	end)

	ui.PlotButton.Activated:Connect(function()
		Remotes.RequestTeleportToPlot:FireServer()
	end)
end

local function showFloatingText(position, text, color)
	local anchor = create("Part", {
		Anchored = true,
		CanCollide = false,
		Transparency = 1,
		Size = Vector3.new(0.5, 0.5, 0.5),
		CFrame = CFrame.new(position),
		Parent = Workspace,
	})

	local billboard = create("BillboardGui", {
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(160, 44),
		StudsOffset = Vector3.new(0, 0, 0),
		Parent = anchor,
	})

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = tostring(text),
		TextColor3 = color or Color3.fromRGB(105, 255, 142),
		TextScaled = true,
		TextStrokeTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		Parent = billboard,
	})

	TweenService:Create(billboard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 4, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.8), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(0.9, function()
		anchor:Destroy()
	end)
end

buildUi()
updateTutorial()

Remotes.StateUpdate.OnClientEvent:Connect(function(newState)
	state = newState
	updateUiFromState(true)
end)

Remotes.Notify.OnClientEvent:Connect(function(message, tone)
	showToast(message, tone)
end)

Remotes.FloatingText.OnClientEvent:Connect(function(position, text, color)
	showFloatingText(position, text, color)
end)

Players.PlayerAdded:Connect(function()
	if activePanel == "Trade" then
		renderTrade()
	end
end)

Players.PlayerRemoving:Connect(function()
	if activePanel == "Trade" then
		renderTrade()
	end
end)

task.spawn(function()
	local success, snapshot = pcall(function()
		return Remotes.GetSnapshot:InvokeServer()
	end)

	if success and snapshot then
		state = snapshot
		updateUiFromState(true)
	else
		showToast("Waiting for garden data...", "Warning")
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		if state then
			if state.LuckyBoostRemaining and state.LuckyBoostRemaining > 0 then
				state.LuckyBoostRemaining -= 1
			end

			for _, plant in ipairs(state.Plants or {}) do
				if plant.Remaining and plant.Remaining > 0 then
					plant.Remaining -= 1
				end
			end

			updateUiFromState(false)
		end
	end
end)
