local PlantData = {}

PlantData.Order = {
	"BasicBean",
	"MemeMoss",
	"SideEyeSprout",
	"ChonkyCarrot",
	"SusSunflower",
	"DramaGourd",
	"BrainrotBloom",
	"CosmicCactus",
}

PlantData.Seeds = {
	BasicBean = {
		Id = "BasicBean",
		DisplayName = "Basic Bean",
		Rarity = "Common",
		Cost = 25,
		GrowthTime = 30,
		HarvestValue = 50,
		RebirthRequired = 0,
		Color = Color3.fromRGB(106, 210, 92),
		Shape = "Bean",
	},
	MemeMoss = {
		Id = "MemeMoss",
		DisplayName = "Meme Moss",
		Rarity = "Uncommon",
		Cost = 125,
		GrowthTime = 55,
		HarvestValue = 210,
		RebirthRequired = 0,
		Color = Color3.fromRGB(82, 222, 174),
		Shape = "Blob",
	},
	SideEyeSprout = {
		Id = "SideEyeSprout",
		DisplayName = "Side-Eye Sprout",
		Rarity = "Rare",
		Cost = 650,
		GrowthTime = 95,
		HarvestValue = 1200,
		RebirthRequired = 0,
		Color = Color3.fromRGB(75, 142, 255),
		Shape = "Sprout",
	},
	ChonkyCarrot = {
		Id = "ChonkyCarrot",
		DisplayName = "Chonky Carrot",
		Rarity = "Epic",
		Cost = 2500,
		GrowthTime = 150,
		HarvestValue = 5200,
		RebirthRequired = 0,
		Color = Color3.fromRGB(255, 137, 63),
		Shape = "Root",
	},
	SusSunflower = {
		Id = "SusSunflower",
		DisplayName = "Sus Sunflower",
		Rarity = "Legendary",
		Cost = 9500,
		GrowthTime = 240,
		HarvestValue = 24000,
		RebirthRequired = 1,
		Color = Color3.fromRGB(255, 210, 66),
		Shape = "Flower",
	},
	DramaGourd = {
		Id = "DramaGourd",
		DisplayName = "Drama Gourd",
		Rarity = "Legendary",
		Cost = 22000,
		GrowthTime = 360,
		HarvestValue = 62000,
		RebirthRequired = 2,
		Color = Color3.fromRGB(255, 94, 116),
		Shape = "Gourd",
	},
	BrainrotBloom = {
		Id = "BrainrotBloom",
		DisplayName = "Brainrot Bloom",
		Rarity = "Mythic",
		Cost = 90000,
		GrowthTime = 600,
		HarvestValue = 290000,
		RebirthRequired = 3,
		Color = Color3.fromRGB(214, 90, 255),
		Shape = "Flower",
	},
	CosmicCactus = {
		Id = "CosmicCactus",
		DisplayName = "Cosmic Cactus",
		Rarity = "Cosmic",
		Cost = 400000,
		GrowthTime = 900,
		HarvestValue = 1500000,
		RebirthRequired = 5,
		Color = Color3.fromRGB(70, 255, 224),
		Shape = "Cactus",
	},
}

function PlantData.Get(seedId)
	return PlantData.Seeds[seedId]
end

function PlantData.GetOrderedSeeds()
	local seeds = {}

	for _, seedId in ipairs(PlantData.Order) do
		table.insert(seeds, PlantData.Seeds[seedId])
	end

	return seeds
end

return PlantData
