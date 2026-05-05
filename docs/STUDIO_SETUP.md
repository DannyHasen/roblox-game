# Studio Setup Quick Reference

## Instance Tree

```text
ReplicatedStorage
  Remotes
  Modules
    Config
    PlantData
    MutationData
    Utility

ServerScriptService
  Main
  DataService
  GardenService
  PlantService
  ShopService
  RebirthService
  RewardService
  MonetizationService
  TradeService

StarterPlayer
  StarterPlayerScripts
    ClientMain

StarterGui
  MainUI
```

## Script Types

- Files ending in `.server.lua` are normal `Script` instances.
- Files ending in `.client.lua` are `LocalScript` instances.
- Shared files are `ModuleScript` instances.
- `StarterGui/MainUI` is a `ScreenGui`.

## Monetization IDs

All IDs are `0` by default so the game runs without real purchases. Replace them in `Config.lua` after creating the passes/products in Roblox Creator Dashboard.

## DataStore

DataStore calls are wrapped in `pcall`. In Studio, enable API access or the game will use fresh session data and warn the player.
