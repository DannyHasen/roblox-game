-- Mutation Garden Wars map generator
-- Place this Script in ServerScriptService. It creates a complete low-lag map from Roblox parts.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local MAP_FOLDER_NAME = "MutationGardenWars"
local PLOT_COUNT = 12
local PLOT_RADIUS = 118
local PLOT_SIZE = Vector3.new(44, 1, 44)
local SLOT_COUNT = 18
local SLOT_COLUMNS = 6
local SLOT_SPACING = 6.2

local COLORS = {
	Grass = Color3.fromRGB(95, 220, 122),
	GrassDark = Color3.fromRGB(66, 179, 91),
	Soil = Color3.fromRGB(116, 78, 47),
	Path = Color3.fromRGB(248, 217, 139),
	PathEdge = Color3.fromRGB(219, 177, 102),
	Wood = Color3.fromRGB(139, 88, 48),
	WoodDark = Color3.fromRGB(95, 60, 38),
	Stone = Color3.fromRGB(144, 154, 160),
	StoneDark = Color3.fromRGB(97, 109, 116),
	Water = Color3.fromRGB(68, 183, 255),
	Shop = Color3.fromRGB(255, 216, 88),
	Mutation = Color3.fromRGB(156, 86, 255),
	Trade = Color3.fromRGB(89, 205, 255),
	Rebirth = Color3.fromRGB(96, 247, 222),
	Daily = Color3.fromRGB(255, 174, 66),
	TextDark = Color3.fromRGB(25, 34, 32),
	White = Color3.fromRGB(255, 255, 255),
	Boundary = Color3.fromRGB(255, 255, 255),
}

local function clearExisting()
	local existing = Workspace:FindFirstChild(MAP_FOLDER_NAME)

	if existing then
		existing:Destroy()
	end
end

local function part(parent, name, size, cframe, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function wedge(parent, name, size, cframe, color, material)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(parent, name, size, cframe, color, material)
	local p = part(parent, name, size, cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function sphere(parent, name, size, cframe, color, material)
	local p = part(parent, name, size, cframe, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function neon(parent, name, size, cframe, color, transparency)
	return part(parent, name, size, cframe, color, Enum.Material.Neon, transparency)
end

local function labelOn(parentPart, text, face, textColor, bgColor, size)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 48
	gui.Parent = parentPart

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundColor3 = bgColor or Color3.fromRGB(24, 35, 34)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = textColor or COLORS.White
	label.TextScaled = true
	label.TextWrapped = true
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = label

	return gui
end

local function billboard(parentPart, text, offset, size, textColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BillboardLabel"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = size or UDim2.fromOffset(260, 72)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.Parent = parentPart

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(25, 35, 34)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = textColor or COLORS.White
	label.TextScaled = true
	label.TextWrapped = true
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function makeTree(parent, position, scale)
	scale = scale or 1
	local m = model(parent, "CartoonTree")
	local trunk = cylinder(m, "Trunk", Vector3.new(2.2 * scale, 7 * scale, 2.2 * scale), CFrame.new(position + Vector3.new(0, 3.5 * scale, 0)), COLORS.Wood, Enum.Material.Wood)
	local crown = sphere(m, "Crown", Vector3.new(9 * scale, 9 * scale, 9 * scale), CFrame.new(position + Vector3.new(0, 9 * scale, 0)), Color3.fromRGB(42, 190, 95), Enum.Material.SmoothPlastic)
	local crown2 = sphere(m, "CrownPop", Vector3.new(6.5 * scale, 6.5 * scale, 6.5 * scale), CFrame.new(position + Vector3.new(2.8 * scale, 11.5 * scale, -1.2 * scale)), Color3.fromRGB(84, 224, 111), Enum.Material.SmoothPlastic)
	m.PrimaryPart = trunk
	return m
end

local function makeRock(parent, position, scale)
	scale = scale or 1
	local m = model(parent, "SoftRock")
	sphere(m, "RockA", Vector3.new(5 * scale, 3 * scale, 4 * scale), CFrame.new(position + Vector3.new(0, 1.5 * scale, 0)), COLORS.Stone, Enum.Material.Slate)
	sphere(m, "RockB", Vector3.new(3.5 * scale, 2.2 * scale, 3.5 * scale), CFrame.new(position + Vector3.new(2 * scale, 1.1 * scale, 1 * scale)), COLORS.StoneDark, Enum.Material.Slate)
	return m
end

local function makeFlower(parent, position, color)
	local m = model(parent, "Flower")
	cylinder(m, "Stem", Vector3.new(0.18, 1.4, 0.18), CFrame.new(position + Vector3.new(0, 0.7, 0)), Color3.fromRGB(45, 157, 72), Enum.Material.SmoothPlastic)
	sphere(m, "Bloom", Vector3.new(1.1, 1.1, 1.1), CFrame.new(position + Vector3.new(0, 1.55, 0)), color, Enum.Material.SmoothPlastic)
	return m
end

local function makeLamp(parent, position)
	local m = model(parent, "GardenLamp")
	cylinder(m, "Post", Vector3.new(0.5, 7, 0.5), CFrame.new(position + Vector3.new(0, 3.5, 0)), Color3.fromRGB(48, 64, 68), Enum.Material.Metal)
	local head = sphere(m, "Glow", Vector3.new(2.3, 2.3, 2.3), CFrame.new(position + Vector3.new(0, 7.4, 0)), Color3.fromRGB(255, 241, 142), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Name = "SoftGlow"
	light.Brightness = 0.8
	light.Range = 18
	light.Color = Color3.fromRGB(255, 244, 174)
	light.Parent = head
	return m
end

local function makeFence(parent, center, length, horizontal)
	local count = math.floor(length / 7)
	for i = 0, count do
		local offset = (i - count / 2) * 7
		local pos = horizontal and center + Vector3.new(offset, 0, 0) or center + Vector3.new(0, 0, offset)
		part(parent, "FencePost", Vector3.new(1, 4, 1), CFrame.new(pos + Vector3.new(0, 2, 0)), COLORS.Wood, Enum.Material.Wood)
	end

	local railSize = horizontal and Vector3.new(length, 0.7, 0.8) or Vector3.new(0.8, 0.7, length)
	part(parent, "FenceRailTop", railSize, CFrame.new(center + Vector3.new(0, 3.2, 0)), COLORS.WoodDark, Enum.Material.Wood)
	part(parent, "FenceRailMid", railSize, CFrame.new(center + Vector3.new(0, 1.7, 0)), COLORS.WoodDark, Enum.Material.Wood)
end

local function makeSign(parent, name, cframe, text, color)
	local m = model(parent, name)
	part(m, "PostA", Vector3.new(0.6, 5, 0.6), cframe * CFrame.new(-3, 2.5, 0), COLORS.WoodDark, Enum.Material.Wood)
	part(m, "PostB", Vector3.new(0.6, 5, 0.6), cframe * CFrame.new(3, 2.5, 0), COLORS.WoodDark, Enum.Material.Wood)
	local face = part(m, "Face", Vector3.new(8, 4.2, 0.6), cframe * CFrame.new(0, 5.5, 0), color or Color3.fromRGB(33, 48, 42), Enum.Material.SmoothPlastic)
	labelOn(face, text, Enum.NormalId.Front)
	return m
end

local function setupLighting()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(130, 170, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(185, 220, 205)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 207)
	Lighting.ColorShift_Bottom = Color3.fromRGB(122, 205, 167)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.25

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "CozyGardenAtmosphere"
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(213, 245, 255)
	atmosphere.Decay = Color3.fromRGB(255, 228, 184)
	atmosphere.Glare = 0.1
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Name = "CartoonBloom"
	bloom.Intensity = 0.15
	bloom.Size = 32
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "BrightCartoonColor"
	colorCorrection.Brightness = 0.05
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = 0.18
	colorCorrection.TintColor = Color3.fromRGB(255, 252, 236)
	colorCorrection.Parent = Lighting
end

local function makeSpawnPlaza(root)
	local plaza = model(root, "SpawnPlaza")
	part(plaza, "MainIsland", Vector3.new(96, 1, 96), CFrame.new(0, 0, 0), COLORS.Grass, Enum.Material.Grass)
	cylinder(plaza, "RoundPlaza", Vector3.new(70, 2, 70), CFrame.new(0, 1.05, 0), COLORS.Path, Enum.Material.SmoothPlastic)
	cylinder(plaza, "CenterBadge", Vector3.new(24, 2.3, 24), CFrame.new(0, 2.2, 0), Color3.fromRGB(255, 126, 183), Enum.Material.Neon)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MutationGardenSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(13, 1, 13)
	spawn.CFrame = CFrame.new(0, 3, 10)
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = plaza
	billboard(spawn, "SPAWN\nStart here!", Vector3.new(0, 5, 0), UDim2.fromOffset(220, 72))

	makeSign(plaza, "WelcomeSign", CFrame.new(0, 1, -33), "MUTATION\nGARDEN WARS", Color3.fromRGB(43, 70, 60))
	makeLamp(plaza, Vector3.new(-28, 1, -26))
	makeLamp(plaza, Vector3.new(28, 1, -26))
	makeLamp(plaza, Vector3.new(-28, 1, 26))
	makeLamp(plaza, Vector3.new(28, 1, 26))

	return plaza
end

local function makeRoads(root)
	local roads = model(root, "Paths")
	local roadColor = COLORS.Path
	part(roads, "NorthPath", Vector3.new(16, 0.4, 130), CFrame.new(0, 1.4, -75), roadColor, Enum.Material.SmoothPlastic)
	part(roads, "SouthPath", Vector3.new(16, 0.4, 130), CFrame.new(0, 1.4, 75), roadColor, Enum.Material.SmoothPlastic)
	part(roads, "EastPath", Vector3.new(130, 0.4, 16), CFrame.new(75, 1.4, 0), roadColor, Enum.Material.SmoothPlastic)
	part(roads, "WestPath", Vector3.new(130, 0.4, 16), CFrame.new(-75, 1.4, 0), roadColor, Enum.Material.SmoothPlastic)
	cylinder(roads, "PlotRingPath", Vector3.new(230, 0.45, 230), CFrame.new(0, 1.35, 0), COLORS.PathEdge, Enum.Material.SmoothPlastic)
	cylinder(roads, "PlotRingGrassCutout", Vector3.new(205, 0.5, 205), CFrame.new(0, 1.42, 0), COLORS.Grass, Enum.Material.Grass)
end

local function makeShop(root)
	local shop = model(root, "SeedShop")
	local base = part(shop, "ShopBase", Vector3.new(34, 1, 28), CFrame.new(-42, 1.6, -34), COLORS.Shop, Enum.Material.SmoothPlastic)
	part(shop, "Counter", Vector3.new(28, 5, 4), CFrame.new(-42, 4.5, -43), Color3.fromRGB(255, 184, 74), Enum.Material.SmoothPlastic)
	part(shop, "BackWall", Vector3.new(32, 15, 2), CFrame.new(-42, 9, -48), Color3.fromRGB(255, 232, 130), Enum.Material.SmoothPlastic)
	local roof = wedge(shop, "TiltedAwning", Vector3.new(38, 8, 10), CFrame.new(-42, 16, -45) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(255, 113, 105), Enum.Material.SmoothPlastic)
	labelOn(base, "SEED SHOP\nBuy silly seeds", Enum.NormalId.Top, COLORS.TextDark, Color3.fromRGB(255, 242, 159))
	billboard(roof, "SEED SHOP", Vector3.new(0, 5, 0), UDim2.fromOffset(260, 64), Color3.fromRGB(255, 244, 174))

	local seeds = {
		{"Bean", Color3.fromRGB(98, 214, 97), -54},
		{"Moss", Color3.fromRGB(65, 228, 176), -46},
		{"Cosmic", Color3.fromRGB(99, 239, 255), -38},
		{"Brainrot", Color3.fromRGB(211, 100, 255), -30},
	}

	for _, seed in ipairs(seeds) do
		sphere(shop, seed[1] .. "Display", Vector3.new(3, 3, 3), CFrame.new(seed[3], 7.3, -41.5), seed[2], Enum.Material.Neon)
	end

	return shop
end

local function makeMutationMachine(root)
	local lab = model(root, "MutationMachineArea")
	part(lab, "LabFloor", Vector3.new(34, 1, 30), CFrame.new(42, 1.6, -34), Color3.fromRGB(223, 214, 255), Enum.Material.SmoothPlastic)
	local vat = cylinder(lab, "MutationVat", Vector3.new(10, 12, 10), CFrame.new(42, 8, -36), COLORS.Mutation, Enum.Material.Neon)
	vat.Transparency = 0.18
	cylinder(lab, "VatRimTop", Vector3.new(13, 1, 13), CFrame.new(42, 14.2, -36), Color3.fromRGB(84, 60, 120), Enum.Material.Metal)
	cylinder(lab, "VatRimBottom", Vector3.new(13, 1, 13), CFrame.new(42, 1.9, -36), Color3.fromRGB(84, 60, 120), Enum.Material.Metal)
	part(lab, "ButtonPanel", Vector3.new(10, 6, 2), CFrame.new(28, 5.5, -36), Color3.fromRGB(48, 55, 72), Enum.Material.Metal)
	neon(lab, "BigRedButton", Vector3.new(4, 1.2, 4), CFrame.new(28, 9.2, -36), Color3.fromRGB(255, 66, 66))
	sphere(lab, "BubbleA", Vector3.new(2, 2, 2), CFrame.new(39, 15, -33), Color3.fromRGB(113, 255, 169), Enum.Material.Neon)
	sphere(lab, "BubbleB", Vector3.new(1.5, 1.5, 1.5), CFrame.new(46, 16.5, -38), Color3.fromRGB(255, 119, 233), Enum.Material.Neon)
	sphere(lab, "BubbleC", Vector3.new(1.8, 1.8, 1.8), CFrame.new(42, 18, -36), Color3.fromRGB(105, 229, 255), Enum.Material.Neon)
	billboard(vat, "MUTATION\nMACHINE", Vector3.new(0, 10, 0), UDim2.fromOffset(270, 76), Color3.fromRGB(236, 217, 255))
	return lab
end

local function makeTradingPlaza(root)
	local trade = model(root, "TradingPlaza")
	part(trade, "TradeFloor", Vector3.new(54, 1, 44), CFrame.new(0, 1.4, 66), Color3.fromRGB(191, 239, 255), Enum.Material.SmoothPlastic)
	cylinder(trade, "TradeCircle", Vector3.new(36, 1, 36), CFrame.new(0, 2.2, 66), COLORS.Trade, Enum.Material.Neon)
	part(trade, "LeftBooth", Vector3.new(16, 8, 10), CFrame.new(-16, 5.6, 66), Color3.fromRGB(255, 137, 189), Enum.Material.SmoothPlastic)
	part(trade, "RightBooth", Vector3.new(16, 8, 10), CFrame.new(16, 5.6, 66), Color3.fromRGB(105, 225, 151), Enum.Material.SmoothPlastic)
	part(trade, "HandshakeBridge", Vector3.new(10, 2, 7), CFrame.new(0, 7.8, 66), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	makeSign(trade, "TradeSign", CFrame.new(0, 1, 41), "TRADING\nPLAZA", Color3.fromRGB(41, 87, 103))
	return trade
end

local function makeRebirthShrine(root)
	local shrine = model(root, "RebirthShrine")
	part(shrine, "ShrineIsland", Vector3.new(46, 1, 34), CFrame.new(0, 1.5, -82), Color3.fromRGB(204, 255, 247), Enum.Material.SmoothPlastic)
	cylinder(shrine, "ShrineBase", Vector3.new(22, 4, 22), CFrame.new(0, 4.5, -82), Color3.fromRGB(91, 224, 210), Enum.Material.Neon)
	cylinder(shrine, "PortalRing", Vector3.new(20, 3, 20), CFrame.new(0, 14, -82) * CFrame.Angles(math.rad(90), 0, 0), COLORS.Rebirth, Enum.Material.Neon)
	part(shrine, "PortalCore", Vector3.new(16, 16, 1.5), CFrame.new(0, 14, -82), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, 0.28)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 16, 2, -82 + math.sin(angle) * 16)
		local pillar = cylinder(shrine, "GlowPillar", Vector3.new(2, 10, 2), CFrame.new(pos + Vector3.new(0, 5, 0)), Color3.fromRGB(145, 119, 255), Enum.Material.Neon)
		sphere(shrine, "PillarOrb", Vector3.new(3.5, 3.5, 3.5), CFrame.new(pillar.CFrame.Position + Vector3.new(0, 6, 0)), Color3.fromRGB(255, 242, 139), Enum.Material.Neon)
	end
	billboard(shrine.PortalRing, "REBIRTH\nSHRINE", Vector3.new(0, 13, 0), UDim2.fromOffset(260, 72), Color3.fromRGB(210, 255, 249))
	return shrine
end

local function makeDailyChest(root)
	local daily = model(root, "DailyRewardChest")
	part(daily, "Base", Vector3.new(18, 1, 18), CFrame.new(-35, 1.5, 28), Color3.fromRGB(255, 232, 153), Enum.Material.SmoothPlastic)
	part(daily, "ChestBody", Vector3.new(12, 7, 8), CFrame.new(-35, 5.4, 28), COLORS.Daily, Enum.Material.Wood)
	cylinder(daily, "ChestLid", Vector3.new(8, 12, 12), CFrame.new(-35, 9.2, 28) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 196, 76), Enum.Material.Wood)
	neon(daily, "LockGlow", Vector3.new(2, 2, 1), CFrame.new(-35, 5.5, 23.7), Color3.fromRGB(255, 255, 255))
	billboard(daily.ChestBody, "DAILY\nREWARD", Vector3.new(0, 8, 0), UDim2.fromOffset(230, 68), Color3.fromRGB(255, 237, 169))
	return daily
end

local function makeLeaderboard(root)
	local board = model(root, "LeaderboardWall")
	part(board, "Wall", Vector3.new(34, 22, 2), CFrame.new(35, 12, 30), Color3.fromRGB(35, 48, 56), Enum.Material.SmoothPlastic)
	labelOn(board.Wall, "LEADERBOARDS\n\nTop Cash\nTop Rebirths\nRarest Mutations\nMost Stolen Plants", Enum.NormalId.Front, Color3.fromRGB(255, 255, 255), Color3.fromRGB(27, 38, 44))
	part(board, "TrimTop", Vector3.new(38, 2, 3), CFrame.new(35, 24, 30), Color3.fromRGB(255, 216, 88), Enum.Material.Neon)
	part(board, "TrimBottom", Vector3.new(38, 2, 3), CFrame.new(35, 1, 30), Color3.fromRGB(255, 216, 88), Enum.Material.Neon)
	return board
end

local function makeTutorialSigns(root)
	local signs = model(root, "TutorialSigns")
	makeSign(signs, "TutorialPlant", CFrame.new(-18, 1, 18) * CFrame.Angles(0, math.rad(35), 0), "1. PLANT\nTap Plant", Color3.fromRGB(43, 88, 58))
	makeSign(signs, "TutorialGrow", CFrame.new(-10, 1, 32) * CFrame.Angles(0, math.rad(15), 0), "2. WAIT\nPlants grow", Color3.fromRGB(43, 73, 88))
	makeSign(signs, "TutorialHarvest", CFrame.new(10, 1, 32) * CFrame.Angles(0, math.rad(-15), 0), "3. HARVEST\nGet cash", Color3.fromRGB(88, 65, 43))
	makeSign(signs, "TutorialRaid", CFrame.new(18, 1, 18) * CFrame.Angles(0, math.rad(-35), 0), "4. RAID\nOnly grown plants", Color3.fromRGB(88, 43, 66))
	return signs
end

local function plotSlotCFrame(plotCFrame, slotIndex)
	local row = math.floor((slotIndex - 1) / SLOT_COLUMNS)
	local column = (slotIndex - 1) % SLOT_COLUMNS
	local rows = math.ceil(SLOT_COUNT / SLOT_COLUMNS)
	local x = (column - ((SLOT_COLUMNS - 1) / 2)) * SLOT_SPACING
	local z = (row - ((rows - 1) / 2)) * SLOT_SPACING
	return plotCFrame * CFrame.new(x, 2.15, z)
end

local function makePlot(parent, index)
	local angle = ((index - 1) / PLOT_COUNT) * math.pi * 2
	local position = Vector3.new(math.cos(angle) * PLOT_RADIUS, 1, math.sin(angle) * PLOT_RADIUS)
	local plotCFrame = CFrame.new(position, Vector3.new(0, 1, 0))

	local plot = model(parent, ("Plot_%02d"):format(index))
	plot:SetAttribute("PlotId", index)
	plot:SetAttribute("OwnerUserId", 0)

	local base = part(plot, "Base", PLOT_SIZE, plotCFrame, index % 2 == 0 and COLORS.Grass or COLORS.GrassDark, Enum.Material.Grass)
	local soil = part(plot, "Soil", Vector3.new(36, 0.45, 34), plotCFrame * CFrame.new(0, 0.75, 0), COLORS.Soil, Enum.Material.Ground)
	local trim = part(plot, "PlotTrim", Vector3.new(48, 1.2, 48), plotCFrame * CFrame.new(0, -0.1, 0), COLORS.Wood, Enum.Material.Wood)
	trim.Transparency = 0.35
	local sign = part(plot, "Sign", Vector3.new(11, 5, 1), plotCFrame * CFrame.new(0, 4.2, -25), Color3.fromRGB(30, 46, 42), Enum.Material.Wood)
	billboard(sign, "OPEN GARDEN\nPlot " .. index, Vector3.new(0, 5.2, 0), UDim2.fromOffset(220, 72))

	local slots = Instance.new("Folder")
	slots.Name = "Slots"
	slots.Parent = plot

	local plants = Instance.new("Folder")
	plants.Name = "Plants"
	plants.Parent = plot

	for slotIndex = 1, SLOT_COUNT do
		local marker = part(slots, ("Slot_%02d"):format(slotIndex), Vector3.new(3.8, 0.16, 3.8), plotSlotCFrame(plotCFrame, slotIndex) * CFrame.new(0, -1.55, 0), Color3.fromRGB(91, 61, 40), Enum.Material.SmoothPlastic, slotIndex > 12 and 0.65 or 0.38)
		marker.CanCollide = false
	end

	makeFence(plot, (plotCFrame * CFrame.new(0, 0, -23)).Position, 40, true)
	makeFence(plot, (plotCFrame * CFrame.new(-23, 0, 0)).Position, 40, false)
	makeFence(plot, (plotCFrame * CFrame.new(23, 0, 0)).Position, 40, false)

	plot.PrimaryPart = base
	return plot
end

local function makePlots(root)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = root

	for index = 1, PLOT_COUNT do
		makePlot(plots, index)
	end
end

local function makeWaterAndDecor(root)
	local decor = model(root, "Decorations")
	cylinder(decor, "Pond", Vector3.new(34, 0.8, 24), CFrame.new(-72, 1.25, 34), COLORS.Water, Enum.Material.SmoothPlastic)
	neon(decor, "PondSparkleA", Vector3.new(4, 0.2, 4), CFrame.new(-78, 1.9, 31), Color3.fromRGB(210, 250, 255), 0.15)
	neon(decor, "PondSparkleB", Vector3.new(3, 0.2, 3), CFrame.new(-66, 1.9, 39), Color3.fromRGB(210, 250, 255), 0.15)

	local flowerColors = {
		Color3.fromRGB(255, 102, 158),
		Color3.fromRGB(255, 225, 94),
		Color3.fromRGB(112, 232, 255),
		Color3.fromRGB(174, 113, 255),
		Color3.fromRGB(255, 140, 80),
	}

	for i = 1, 24 do
		local angle = (i / 24) * math.pi * 2
		local radius = 48 + ((i % 3) * 10)
		local pos = Vector3.new(math.cos(angle) * radius, 1.2, math.sin(angle) * radius)
		makeFlower(decor, pos, flowerColors[(i % #flowerColors) + 1])
	end

	for i = 1, 18 do
		local angle = (i / 18) * math.pi * 2
		local radius = 155 + ((i % 2) * 12)
		makeTree(decor, Vector3.new(math.cos(angle) * radius, 1, math.sin(angle) * radius), 0.85 + ((i % 3) * 0.12))
	end

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2 + 0.22
		makeRock(decor, Vector3.new(math.cos(angle) * 142, 1, math.sin(angle) * 142), 0.8 + ((i % 2) * 0.25))
	end

	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		makeLamp(decor, Vector3.new(math.cos(angle) * 82, 1, math.sin(angle) * 82))
	end
end

local function makeBoundaries(root)
	local safety = model(root, "Safety")
	local floor = part(safety, "AntiFallSafetyFloor", Vector3.new(420, 1, 420), CFrame.new(0, -18, 0), Color3.fromRGB(74, 202, 126), Enum.Material.SmoothPlastic, 0.65)
	floor.CanCollide = true

	local wallHeight = 80
	local half = 205
	local walls = {
		{"NorthInvisibleBoundary", Vector3.new(420, wallHeight, 2), CFrame.new(0, wallHeight / 2, -half)},
		{"SouthInvisibleBoundary", Vector3.new(420, wallHeight, 2), CFrame.new(0, wallHeight / 2, half)},
		{"EastInvisibleBoundary", Vector3.new(2, wallHeight, 420), CFrame.new(half, wallHeight / 2, 0)},
		{"WestInvisibleBoundary", Vector3.new(2, wallHeight, 420), CFrame.new(-half, wallHeight / 2, 0)},
	}

	for _, wall in ipairs(walls) do
		local boundary = part(safety, wall[1], wall[2], wall[3], COLORS.Boundary, Enum.Material.SmoothPlastic, 1)
		boundary.CanCollide = true
	end
end

local function makeBaseTerrain(root)
	local base = model(root, "BaseTerrain")
	part(base, "MainGrassField", Vector3.new(390, 1, 390), CFrame.new(0, -0.6, 0), COLORS.Grass, Enum.Material.Grass)
	part(base, "OuterGrassBlend", Vector3.new(430, 1, 430), CFrame.new(0, -1.2, 0), Color3.fromRGB(74, 198, 116), Enum.Material.Grass)
end

clearExisting()
setupLighting()

local root = Instance.new("Folder")
root.Name = MAP_FOLDER_NAME
root:SetAttribute("GeneratedBy", "MapBuilder")
root:SetAttribute("PlotCount", PLOT_COUNT)
root.Parent = Workspace

makeBaseTerrain(root)
makeRoads(root)
makeSpawnPlaza(root)
makeShop(root)
makeMutationMachine(root)
makeTradingPlaza(root)
makeRebirthShrine(root)
makeDailyChest(root)
makeLeaderboard(root)
makeTutorialSigns(root)
makePlots(root)
makeWaterAndDecor(root)
makeBoundaries(root)

print("[Mutation Garden Wars] MapBuilder generated " .. PLOT_COUNT .. " plots and full plaza map.")
