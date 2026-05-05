local MutationData = {}

MutationData.NormalId = "Normal"

MutationData.Order = {
	"Normal",
	"Big",
	"Golden",
	"Rainbow",
	"Cursed",
	"Brainrot",
	"Cosmic",
}

MutationData.Mutations = {
	Normal = {
		Id = "Normal",
		DisplayName = "Normal",
		Multiplier = 1,
		Weight = 0,
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic,
		Scale = 1,
	},
	Big = {
		Id = "Big",
		DisplayName = "Big",
		Multiplier = 2,
		Weight = 55,
		Color = Color3.fromRGB(137, 255, 123),
		Material = Enum.Material.SmoothPlastic,
		Scale = 1.25,
	},
	Golden = {
		Id = "Golden",
		DisplayName = "Golden",
		Multiplier = 5,
		Weight = 24,
		Color = Color3.fromRGB(255, 203, 56),
		Material = Enum.Material.Metal,
		Scale = 1.1,
	},
	Rainbow = {
		Id = "Rainbow",
		DisplayName = "Rainbow",
		Multiplier = 10,
		Weight = 12,
		Color = Color3.fromRGB(255, 110, 216),
		Material = Enum.Material.Neon,
		Scale = 1.15,
	},
	Cursed = {
		Id = "Cursed",
		DisplayName = "Cursed",
		Multiplier = 15,
		Weight = 5,
		Color = Color3.fromRGB(121, 60, 166),
		Material = Enum.Material.Neon,
		Scale = 1.05,
	},
	Brainrot = {
		Id = "Brainrot",
		DisplayName = "Brainrot",
		Multiplier = 25,
		Weight = 3,
		Color = Color3.fromRGB(84, 255, 114),
		Material = Enum.Material.Neon,
		Scale = 1.2,
	},
	Cosmic = {
		Id = "Cosmic",
		DisplayName = "Cosmic",
		Multiplier = 50,
		Weight = 1,
		Color = Color3.fromRGB(74, 237, 255),
		Material = Enum.Material.Neon,
		Scale = 1.3,
	},
}

function MutationData.Get(mutationId)
	return MutationData.Mutations[mutationId] or MutationData.Mutations.Normal
end

function MutationData.GetMutationPool()
	local pool = {}

	for _, mutationId in ipairs(MutationData.Order) do
		local mutation = MutationData.Mutations[mutationId]

		if mutation.Weight > 0 then
			table.insert(pool, mutation)
		end
	end

	return pool
end

return MutationData
