local Utility = {}

function Utility.DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}

	for key, child in pairs(value) do
		copy[Utility.DeepCopy(key)] = Utility.DeepCopy(child)
	end

	return copy
end

function Utility.ClampNumber(value, minValue, maxValue, fallback)
	if type(value) ~= "number" or value ~= value then
		return fallback or minValue
	end

	return math.clamp(value, minValue, maxValue)
end

function Utility.GetUnixDay(timestamp)
	return math.floor((timestamp or os.time()) / 86400)
end

function Utility.FormatNumber(value)
	value = math.floor(tonumber(value) or 0)

	if value >= 1000000000 then
		return string.format("%.1fB", value / 1000000000)
	end

	if value >= 1000000 then
		return string.format("%.1fM", value / 1000000)
	end

	if value >= 1000 then
		return string.format("%.1fK", value / 1000)
	end

	return tostring(value)
end

function Utility.WeightedChoice(items, randomObject)
	local totalWeight = 0

	for _, item in ipairs(items) do
		totalWeight += math.max(0, item.Weight or 0)
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = (randomObject or Random.new()):NextNumber(0, totalWeight)
	local cursor = 0

	for _, item in ipairs(items) do
		cursor += math.max(0, item.Weight or 0)

		if roll <= cursor then
			return item
		end
	end

	return items[#items]
end

function Utility.MakeDictionaryFromArray(array)
	local dictionary = {}

	for _, value in ipairs(array) do
		dictionary[value] = true
	end

	return dictionary
end

function Utility.RoundTo(value, places)
	local multiplier = 10 ^ (places or 0)

	return math.floor((value * multiplier) + 0.5) / multiplier
end

return Utility
