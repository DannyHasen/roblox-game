local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))

local function getOrCreate(parent, className, name)
	local instance = parent:FindFirstChild(name)

	if instance and instance.ClassName ~= className then
		instance:Destroy()
		instance = nil
	end

	if not instance then
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = parent
	end

	return instance
end

local remotesFolder = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
local remotes = {}

for remoteKey, remoteName in pairs(Config.RemoteNames) do
	local className = remoteKey == "GetSnapshot" and "RemoteFunction" or "RemoteEvent"
	remotes[remoteKey] = getOrCreate(remotesFolder, className, remoteName)
end

local serviceNames = {
	"DataService",
	"GardenService",
	"PlantService",
	"ShopService",
	"RebirthService",
	"RewardService",
	"MonetizationService",
	"TradeService",
}

local services = {}

for _, serviceName in ipairs(serviceNames) do
	services[serviceName] = require(ServerScriptService:WaitForChild(serviceName))
end

local context = {
	Config = Config,
	Remotes = remotes,
	Services = services,
}

for _, serviceName in ipairs(serviceNames) do
	local service = services[serviceName]

	if service.Init then
		service:Init(context)
	end
end

for _, serviceName in ipairs(serviceNames) do
	local service = services[serviceName]

	if service.Start then
		service:Start()
	end
end

local function setupPlayer(player)
	services.DataService:LoadPlayer(player)
	services.GardenService:AssignPlot(player)
	services.PlantService:LoadPlayerPlants(player)
	services.DataService:Push(player)
end

local function cleanupPlayer(player)
	services.PlantService:HandlePlayerRemoving(player)
	services.GardenService:ReleasePlot(player)
	services.DataService:SavePlayer(player)
	services.DataService:ForgetPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		services.DataService:SavePlayer(player)
	end
end)

print("[Mutation Garden Wars] Server online.")
