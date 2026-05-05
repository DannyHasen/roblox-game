local Config = {}

Config.GameName = "Mutation Garden Wars"
Config.DataStoreName = "MutationGardenWars_v1"

Config.StartingCash = 100
Config.StartingSeeds = {
	BasicBean = 1,
}

Config.AutoSaveInterval = 60
Config.MaxSaveRetries = 3

Config.PlotCount = 12
Config.BaseMaxPlants = 12
Config.VipExtraPlantSlots = 6
Config.PlotSpacing = 64
Config.PlotSize = Vector3.new(44, 1, 44)
Config.SlotColumns = 6
Config.SlotSpacing = 9
Config.WorldFolderName = "MutationGardenWars"

Config.BaseMutationChance = 0.10
Config.LuckyMutationBoostChance = 0.25
Config.LuckyMutationBoostSeconds = 10 * 60

Config.PlantRequestCooldown = 0.45
Config.HarvestRequestCooldown = 0.25
Config.SellAllCooldown = 3
Config.StealCooldown = 120
Config.StealRewardPercent = 0.4
Config.OwnerInsurancePercent = 0.2
Config.ShieldSecondsAfterSteal = 90

Config.RebirthBaseCost = 10000
Config.RebirthCostGrowth = 2.2
Config.RebirthCashMultiplierPerRebirth = 0.25

Config.DailyRewardBase = 250
Config.DailyRewardStreakBonus = 100
Config.DailyRewardMaxStreak = 7

Config.RemoteNames = {
	GetSnapshot = "GetSnapshot",
	StateUpdate = "StateUpdate",
	Notify = "Notify",
	FloatingText = "FloatingText",
	RequestPlant = "RequestPlant",
	RequestBuySeed = "RequestBuySeed",
	RequestSellAll = "RequestSellAll",
	RequestRebirth = "RequestRebirth",
	RequestDailyReward = "RequestDailyReward",
	RequestTeleportToPlot = "RequestTeleportToPlot",
	RequestTrade = "RequestTrade",
	RequestProductPurchase = "RequestProductPurchase",
	RequestGamePassPurchase = "RequestGamePassPurchase",
}

Config.GamePasses = {
	DoubleCash = {
		Id = 0,
		DisplayName = "2x Cash",
	},
	VipGarden = {
		Id = 0,
		DisplayName = "VIP Garden",
	},
}

Config.DeveloperProducts = {
	LuckyMutationBoost = {
		Id = 0,
		DisplayName = "Lucky Mutation Boost",
	},
	SmallCashPack = {
		Id = 0,
		DisplayName = "Small Cash Pack",
		Cash = 2500,
	},
	MediumCashPack = {
		Id = 0,
		DisplayName = "Medium Cash Pack",
		Cash = 12500,
	},
	LargeCashPack = {
		Id = 0,
		DisplayName = "Large Cash Pack",
		Cash = 60000,
	},
}

Config.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Cosmic = 7,
}

Config.RarityColors = {
	Common = Color3.fromRGB(152, 224, 129),
	Uncommon = Color3.fromRGB(88, 206, 255),
	Rare = Color3.fromRGB(87, 111, 255),
	Epic = Color3.fromRGB(193, 92, 255),
	Legendary = Color3.fromRGB(255, 193, 69),
	Mythic = Color3.fromRGB(255, 74, 137),
	Cosmic = Color3.fromRGB(82, 246, 219),
}

Config.Ui = {
	Primary = Color3.fromRGB(42, 197, 98),
	PrimaryDark = Color3.fromRGB(26, 134, 72),
	Panel = Color3.fromRGB(24, 32, 38),
	PanelLight = Color3.fromRGB(37, 48, 57),
	Text = Color3.fromRGB(245, 250, 246),
	Muted = Color3.fromRGB(188, 205, 196),
	Warning = Color3.fromRGB(255, 202, 77),
	Danger = Color3.fromRGB(255, 87, 87),
}

return Config
