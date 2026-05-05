local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))

local GardenService = {}

GardenService.Plots = {}
GardenService.CharacterConnections = {}

local function createPart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createBillboard(parent, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlotBillboard"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(220, 72)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(21, 30, 27)
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	return gui
end

local function computeSlotCFrame(plotCFrame, slotIndex)
	local columns = Config.SlotColumns
	local rows = math.ceil((Config.BaseMaxPlants + Config.VipExtraPlantSlots) / columns)
	local row = math.floor((slotIndex - 1) / columns)
	local column = (slotIndex - 1) % columns
	local x = (column - ((columns - 1) / 2)) * Config.SlotSpacing
	local z = (row - ((rows - 1) / 2)) * Config.SlotSpacing

	return plotCFrame * CFrame.new(x, 2.2, z)
end

function GardenService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function GardenService:Start()
	task.wait(0.25)
	self:BuildWorld()

	self.Remotes.RequestTeleportToPlot.OnServerEvent:Connect(function(player)
		self:TeleportToPlot(player)
	end)
end

function GardenService:IndexExistingWorld(root)
	local plotsFolder = root:FindFirstChild("Plots")

	if not plotsFolder then
		return false
	end

	self.Root = root
	self.Plots = {}

	for plotId = 1, Config.PlotCount do
		local model = plotsFolder:FindFirstChild(("Plot_%02d"):format(plotId))

		if model then
			local base = model:FindFirstChild("Base")
			local soil = model:FindFirstChild("Soil")
			local sign = model:FindFirstChild("Sign")
			local plants = model:FindFirstChild("Plants")

			if base and sign then
				if not plants then
					plants = Instance.new("Folder")
					plants.Name = "Plants"
					plants.Parent = model
				end

				model.PrimaryPart = base
				model:SetAttribute("PlotId", plotId)
				model:SetAttribute("OwnerUserId", 0)

				self.Plots[plotId] = {
					Id = plotId,
					Model = model,
					Base = base,
					Soil = soil,
					Sign = sign,
					PlantsFolder = plants,
					CFrame = base.CFrame,
					Owner = nil,
				}
			end
		end
	end

	return #self.Plots > 0
end

function GardenService:BuildWorld()
	local root = Workspace:FindFirstChild(Config.WorldFolderName)

	if root and root:GetAttribute("GeneratedBy") == "MapBuilder" and self:IndexExistingWorld(root) then
		return
	end

	if not root then
		root = Instance.new("Folder")
		root.Name = Config.WorldFolderName
		root.Parent = Workspace
	else
		root:ClearAllChildren()
	end

	root:SetAttribute("GeneratedBy", "MutationGardenWars")
	self.Root = root

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = root

	createPart(lobby, "LobbyBase", Vector3.new(70, 1, 70), CFrame.new(0, 0, 0), Color3.fromRGB(95, 219, 138), Enum.Material.Grass)
	createPart(lobby, "ShopKiosk", Vector3.new(14, 10, 8), CFrame.new(-18, 5.5, -14), Color3.fromRGB(255, 214, 89), Enum.Material.SmoothPlastic)
	createPart(lobby, "RebirthPortal", Vector3.new(8, 12, 2), CFrame.new(18, 6.5, -14), Color3.fromRGB(83, 233, 255), Enum.Material.Neon)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MutationSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 1, 10)
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Parent = lobby

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = root

	self.Plots = {}

	for plotId = 1, Config.PlotCount do
		local angle = ((plotId - 1) / Config.PlotCount) * math.pi * 2
		local radius = Config.PlotSpacing
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local cframe = CFrame.new(position, Vector3.new(0, 0, 0))
		local model = Instance.new("Model")
		model.Name = ("Plot_%02d"):format(plotId)
		model:SetAttribute("PlotId", plotId)
		model:SetAttribute("OwnerUserId", 0)
		model.Parent = plotsFolder

		local base = createPart(model, "Base", Config.PlotSize, cframe, Color3.fromRGB(79, 197, 108), Enum.Material.Grass)
		local soil = createPart(model, "Soil", Vector3.new(34, 0.35, 34), cframe * CFrame.new(0, 0.7, 0), Color3.fromRGB(116, 79, 48), Enum.Material.Ground)
		local sign = createPart(model, "Sign", Vector3.new(9, 5, 1), cframe * CFrame.new(0, 4, -24), Color3.fromRGB(34, 47, 56), Enum.Material.Wood)
		createBillboard(sign, "Open Garden")

		local slots = Instance.new("Folder")
		slots.Name = "Slots"
		slots.Parent = model

		local plants = Instance.new("Folder")
		plants.Name = "Plants"
		plants.Parent = model

		for slotIndex = 1, Config.BaseMaxPlants + Config.VipExtraPlantSlots do
			local marker = createPart(slots, ("Slot_%02d"):format(slotIndex), Vector3.new(4, 0.12, 4), computeSlotCFrame(cframe, slotIndex) * CFrame.new(0, -1.65, 0), Color3.fromRGB(92, 64, 42), Enum.Material.SmoothPlastic)
			marker.Transparency = slotIndex > Config.BaseMaxPlants and 0.72 or 0.45
			marker.CanCollide = false
		end

		model.PrimaryPart = base
		self.Plots[plotId] = {
			Id = plotId,
			Model = model,
			Base = base,
			Soil = soil,
			Sign = sign,
			PlantsFolder = plants,
			CFrame = cframe,
			Owner = nil,
		}
	end
end

function GardenService:AssignPlot(player)
	for _, plot in ipairs(self.Plots) do
		if not plot.Owner then
			plot.Owner = player
			plot.Model:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("PlotId", plot.Id)
			self:UpdatePlotSign(plot)

			if self.CharacterConnections[player] then
				self.CharacterConnections[player]:Disconnect()
			end

			self.CharacterConnections[player] = player.CharacterAdded:Connect(function()
				task.wait(0.25)
				self:TeleportToPlot(player)
			end)

			task.defer(function()
				self:TeleportToPlot(player)
			end)

			return plot
		end
	end

	self.Context.Services.DataService:Notify(player, "All gardens are full right now.", "Warning")
	return nil
end

function GardenService:ReleasePlot(player)
	local plot = self:GetPlot(player)

	if not plot then
		return
	end

	plot.Owner = nil
	plot.Model:SetAttribute("OwnerUserId", 0)
	player:SetAttribute("PlotId", nil)

	if self.CharacterConnections[player] then
		self.CharacterConnections[player]:Disconnect()
		self.CharacterConnections[player] = nil
	end

	self:UpdatePlotSign(plot)
end

function GardenService:UpdatePlotSign(plot)
	local billboard = plot.Sign:FindFirstChild("PlotBillboard") or plot.Sign:FindFirstChild("BillboardLabel")
	local label = billboard and (billboard:FindFirstChild("Label") or billboard:FindFirstChildWhichIsA("TextLabel", true))

	if label and plot.Owner then
		label.Text = plot.Owner.DisplayName .. "'s Garden"
		label.BackgroundColor3 = Color3.fromRGB(29, 79, 49)
		plot.Base.Color = Color3.fromRGB(91, 217, 126)
	elseif label then
		label.Text = "Open Garden"
		label.BackgroundColor3 = Color3.fromRGB(21, 30, 27)
		plot.Base.Color = Color3.fromRGB(79, 197, 108)
	end
end

function GardenService:GetPlot(player)
	local plotId = player:GetAttribute("PlotId")

	if not plotId then
		return nil
	end

	return self.Plots[plotId]
end

function GardenService:GetPlotByUserId(userId)
	for _, plot in ipairs(self.Plots) do
		if plot.Owner and plot.Owner.UserId == userId then
			return plot
		end
	end

	return nil
end

function GardenService:GetSlotCFrameFromPlot(plotModel, slotIndex)
	local plotId = plotModel:GetAttribute("PlotId")
	local plot = self.Plots[plotId]
	local cframe = plot and plot.CFrame or plotModel:GetPivot()

	return computeSlotCFrame(cframe, slotIndex)
end

function GardenService:GetSlotCFrame(player, slotIndex)
	local plot = self:GetPlot(player)

	if not plot then
		return nil
	end

	return self:GetSlotCFrameFromPlot(plot.Model, slotIndex)
end

function GardenService:GetFreeSlot(player, plants, maxPlants)
	local used = {}

	for _, plant in ipairs(plants) do
		if plant.SlotIndex and plant.SlotIndex > 0 then
			used[plant.SlotIndex] = true
		end
	end

	for slotIndex = 1, maxPlants do
		if not used[slotIndex] then
			return slotIndex
		end
	end

	return nil
end

function GardenService:TeleportToPlot(player)
	local plot = self:GetPlot(player)

	if not plot then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		root.CFrame = plot.CFrame * CFrame.new(0, 6, 25)
	end
end

function GardenService:GetPlayersNearPlayer(player, maxDistance)
	local plot = self:GetPlot(player)
	local nearby = {}

	if not plot then
		return nearby
	end

	maxDistance = maxDistance or 80

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local otherPlot = self:GetPlot(otherPlayer)

			if otherPlot and (otherPlot.CFrame.Position - plot.CFrame.Position).Magnitude <= maxDistance then
				table.insert(nearby, otherPlayer)
			end
		end
	end

	return nearby
end

return GardenService
