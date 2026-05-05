local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("Config"))
local Utility = require(Modules:WaitForChild("Utility"))

local RewardService = {}

function RewardService:Init(context)
	self.Context = context
	self.Remotes = context.Remotes
end

function RewardService:Start()
	self.Remotes.RequestDailyReward.OnServerEvent:Connect(function(player)
		self:Claim(player)
	end)
end

function RewardService:GetNextStreak(player)
	local data = self.Context.Services.DataService:GetData(player)

	if not data then
		return 1
	end

	local today = Utility.GetUnixDay(os.time())
	local lastClaimDay = data.Daily.LastClaimDay or 0

	if lastClaimDay == today - 1 then
		return math.clamp((data.Daily.Streak or 0) + 1, 1, Config.DailyRewardMaxStreak)
	end

	if lastClaimDay == today then
		return math.clamp(data.Daily.Streak or 1, 1, Config.DailyRewardMaxStreak)
	end

	return 1
end

function RewardService:GetRewardAmount(player)
	local streak = self:GetNextStreak(player)

	return Config.DailyRewardBase + ((streak - 1) * Config.DailyRewardStreakBonus)
end

function RewardService:CanClaim(player)
	local data = self.Context.Services.DataService:GetData(player)

	if not data then
		return false
	end

	return data.Daily.LastClaimDay ~= Utility.GetUnixDay(os.time())
end

function RewardService:Claim(player)
	local dataService = self.Context.Services.DataService
	local data = dataService:GetData(player)

	if not data then
		return
	end

	if not self:CanClaim(player) then
		dataService:Notify(player, "Daily reward already claimed today.", "Warning")
		return
	end

	local today = Utility.GetUnixDay(os.time())
	local streak = self:GetNextStreak(player)
	local reward = self:GetRewardAmount(player)

	data.Daily.LastClaimDay = today
	data.Daily.Streak = streak
	dataService:AddCash(player, reward, "Daily")
	dataService:MarkDirty(player)
	dataService:Notify(player, ("Daily claimed: $%s. Streak %d."):format(Utility.FormatNumber(reward), streak), "Success")
	dataService:Push(player)
end

return RewardService
