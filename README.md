# Mutation Garden Wars

A Roblox Luau MVP for a cozy idle garden simulator with rarity, mutations, rebirths, light garden raiding, daily rewards, trading hooks, and monetization hooks.

## What Is Built

- Server-owned player data with `DataStoreService`
- Autosave every 60 seconds and save on leave
- Generated lobby and 8 garden plots
- Plot assignment and teleport-to-plot
- Seed inventory, seed shop, planting, timed growth, harvest prompts
- Seed rarities and mutation rolls
- Rebirth reset with permanent cash multiplier
- Daily reward and streak bonus
- Light stealing/raiding from fully grown plants
- Shield placeholder after a steal
- Mobile-first dynamic UI
- Tutorial popup
- Floating money text
- Game pass hooks for 2x Cash and VIP Garden
- Developer product hooks for lucky mutation boost and cash packs
- Trade ping placeholder

## Studio Placement

Paste or sync these files into Roblox Studio:

- `ReplicatedStorage/Modules/Config.lua`
- `ReplicatedStorage/Modules/PlantData.lua`
- `ReplicatedStorage/Modules/MutationData.lua`
- `ReplicatedStorage/Modules/Utility.lua`
- `ServerScriptService/Main.server.lua`
- `ServerScriptService/DataService.lua`
- `ServerScriptService/GardenService.lua`
- `ServerScriptService/PlantService.lua`
- `ServerScriptService/ShopService.lua`
- `ServerScriptService/RebirthService.lua`
- `ServerScriptService/RewardService.lua`
- `ServerScriptService/MonetizationService.lua`
- `ServerScriptService/TradeService.lua`
- `StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`
- `StarterGui/MainUI` as a `ScreenGui` with `ResetOnSpawn = false` and `IgnoreGuiInset = true`

The server creates `ReplicatedStorage/Remotes` at runtime, so missed RemoteEvents will not break setup.

## Setup

1. Create a new Roblox baseplate place.
2. Add the modules and scripts to the locations above.
3. In Studio, enable **Game Settings > Security > Enable Studio Access to API Services** for DataStore testing.
4. Press Play. The server will generate the lobby, shop kiosk, rebirth portal, and plot ring.
5. Replace placeholder monetization IDs in `ReplicatedStorage/Modules/Config.lua`:
   - `GamePasses.DoubleCash.Id`
   - `GamePasses.VipGarden.Id`
   - `DeveloperProducts.LuckyMutationBoost.Id`
   - `DeveloperProducts.SmallCashPack.Id`
   - `DeveloperProducts.MediumCashPack.Id`
   - `DeveloperProducts.LargeCashPack.Id`
6. Publish the place before testing real purchases.

## Run With Rojo

Install Rokit if needed, then from this repo:

```powershell
rokit install
rokit run rojo serve default.project.json
```

In Roblox Studio, install/open the Rojo plugin and connect to the shown localhost server.

To create a Studio place file:

```powershell
rokit run rojo build default.project.json -o build/MutationGardenWars.rbxlx
```

You can also open the committed `build/MutationGardenWars.rbxlx` directly in Studio.

## Balance Entry Points

Tune these first:

- Starting cash and seed: `Config.StartingCash`, `Config.StartingSeeds`
- Plot capacity: `Config.BaseMaxPlants`, `Config.VipExtraPlantSlots`
- Mutation odds: `Config.BaseMutationChance`, `MutationData.Mutations`
- Seed economy: `PlantData.Seeds`
- Rebirth curve: `Config.RebirthBaseCost`, `Config.RebirthCostGrowth`
- Stealing pressure: `Config.StealCooldown`, `Config.StealRewardPercent`, `Config.OwnerInsurancePercent`
- Daily rewards: `Config.DailyRewardBase`, `Config.DailyRewardStreakBonus`

## Test Checklist

- New player starts with 100 cash and 1 Basic Bean.
- Player can plant Basic Bean and inventory decreases.
- Plant grows over 30 seconds and enables a ProximityPrompt when ready.
- Owner can harvest and receives cash.
- Shop buys seeds only when player has enough cash.
- Locked seeds require the configured rebirth count.
- Mutation labels and payout multipliers appear on mutated plants.
- Sell All only sells fully grown plants.
- Rebirth at 10,000 cash resets cash, inventory, and plants, then increases multiplier.
- Daily reward claims once per UTC day and updates streak.
- Two-player test: Player B can steal Player A's fully grown plant only after cooldown.
- Owner receives warning and insurance after a steal.
- Shield blocks follow-up steals temporarily.
- Teleport to Plot button moves the player to their garden.
- Trade button sends another player a trade ping.
- Studio output has no red errors during a 5-minute session.
- Leave and rejoin after planting; saved cash, inventory, rebirths, daily, and plants restore.

## Next Virality Upgrades

- Add limited-time weather mutations like Meteor Shower, Disco Rain, and Admin Sun.
- Add garden rating boards and a server-wide rare mutation announcement.
- Add safe two-sided trading escrow with accept/confirm stages.
- Add gifting and friend boost multipliers.
- Add weekly seed crates with animated opening.
- Add UGC-style title tags for mutation collectors.
- Add short-form moments: giant mutation reveal, steal alert, and rebirth burst effects.
