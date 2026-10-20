# ars_ambulancejob

An ambulance job with an integrated death system for ESX, QBCore and QBox, built on `ox_lib`, `ox_inventory` and `ox_target`. Any other framework can be connected through a small bridge file.

This is a heavily reworked fork of [Arius-Development/ars_ambulancejob](https://github.com/Arius-Development/ars_ambulancejob) (Apache-2.0). Every item and revive action is now validated on the server, and there is no hard dependency on any logging, phone, radio or keys resource.

## Features

- Death system with respawn timer, hospital beds and a death screen
- Per-bone injury system (cause, severity and the matching treatment item)
- Defibrillator revive with synchronized CPR animations
- Injury treatment with durability-consuming items
- NPC paramedic at the hospital that only appears while nobody is on duty (checked every minute)
- Emergency calls: random incidents (injured, burned, cardiac arrest, overdose) with a blip, step-by-step treatment, payment and a streak bonus
- Distress calls (`/911`) that medics read with `/emscalls`
- Stretchers, loading patients into ambulances
- Placeable medical bag with a personal stash
- Hospital stashes with job and grade restrictions enforced by `ox_inventory`
- Service garages with grade-locked vehicles
- Admin commands: revive, heal, area variants and revive all
- txAdmin heal integration
- Pluggable logging and client hooks (see below)

## Requirements

- One framework: [es_extended](https://github.com/esx-framework/esx_core), [qb-core](https://github.com/qbcore-framework/qb-core) or [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)
- OneSync enabled

The framework is detected automatically (`qbx_core`, then `qb-core`, then `es_extended`). Force one with `Config.framework = 'esx' | 'qbcore' | 'qbx' | 'custom'`.

## Installation

1. Put the folder in your resources directory and `ensure ars_ambulancejob` after its dependencies.
2. Add the items from `install/items.lua` to `ox_inventory/data/items.lua` and copy the icons from `install/images` to `ox_inventory/web/images`.
3. Admins need to be in the ace group set by `Config.adminGroup` (`group.admin` by default).
4. ESX: the `is_dead` column is added to the `users` table automatically on first start. QBCore and QBox store the dead state in the `isdead` player metadata.
5. QBCore and QBox: `Config.rewards.account` and `Config.paramedic.account` use `money`, which is mapped to `cash`.

Items that lose durability when used (`bandage`, `icepack`, `suturekit`, `tweezers`, `burncream`, `defibrillator`) should be non-stackable so every unit keeps its own durability.

## Emergency calls

While at least `minMedicsOnDuty` medics are on duty, the server creates random incidents every few minutes (`config/calls.lua`). On-duty medics get a notification, a blip and a route. When they arrive the patient appears, and the medic works through the scenario steps with ox_target: examine, then treat with the right items (bandage, burn cream, CPR and defibrillator, medkit). The server checks distance, time spent and items, takes the items and pays `reward.min` to `reward.max`, plus a bonus for a fast response and a streak bonus for back-to-back calls. Set `Config.emergencyCalls.enabled = false` to turn it off, or `reward.max = 0` to disable payment. Add your own scenarios and locations in the same file.

Medics count as on duty when they have an EMS job and, on QBCore and QBox, `onduty` is true. ESX uses `job.onDuty` when it exists.

The hospital paramedic NPC only appears while `Config.paramedic.maxMedicsOnDuty` or fewer medics are on duty. The count is refreshed every `Config.paramedic.pollSeconds` seconds (60 by default).

## Configuration

| File | Purpose |
| --- | --- |
| `config/config.lua` | Jobs, commands, items, timers, rewards, paramedic, dispatch, stretcher, hooks |
| `config/hospitals.lua` | Hospitals: zones, blips, beds, stashes, garages, paramedic NPC |
| `config/injuries.lua` | Body part ids and labels |
| `config/weapons.lua` | Weapon to cause-of-injury mapping |
| `locales/*.json` | Translations. Missing keys fall back to English |

Rewards (`Config.rewards`) and the paramedic price (`Config.paramedic.price`) are `0` by default, which disables them.

## Framework bridge

Everything framework specific lives in `bridge/`:

```
bridge/
├── shared.lua          framework detection and Config.framework
├── client/
│   ├── common.lua      events any framework can trigger
│   ├── esx.lua
│   ├── qb.lua          QBCore and QBox
│   └── custom.lua      template for your own framework
└── server/
    ├── esx.lua
    ├── qb.lua
    └── custom.lua
```

To support another framework, set `Config.framework = 'custom'` and fill in `bridge/client/custom.lua` and `bridge/server/custom.lua`. Each function below must exist.

Client:

| Function | Purpose |
| --- | --- |
| `Framework.hasJob(Jobs)` | Local player has one of the jobs |
| `Framework.getJobGrade()` | Local player job grade as a number |
| `Framework.healStatus()` | Restore hunger and thirst |
| `Framework.playerSpawned()` | Tell other scripts the player is alive again |

Server:

| Function | Purpose |
| --- | --- |
| `Framework.hasJob(Source, Jobs)` | Player has one of the jobs |
| `Framework.getName(Source)` | Character name |
| `Framework.getMoney(Source, Account)` | Balance of an account |
| `Framework.addMoney(Source, Account, Amount)` | Returns `true` when paid |
| `Framework.removeMoney(Source, Account, Amount)` | Returns `true` when charged |
| `Framework.setDead(Source, IsDead)` | Persist the dead state |
| `Framework.wasDead(Source)` | Read the persisted dead state |
| `Framework.registerUsableItem(Name, Handler)` | Call `Handler(Source)` when the item is used |

Your framework should trigger `ars_ambulancejob:playerLoaded` (client, local) when the character has loaded and `ars_ambulancejob:playerUnloaded` when it logs out. The custom bridge fires `ars_ambulancejob:statusRestored` (client, and server with the source) when hunger and thirst should be restored.

The custom bridge reads the job from the `job` and `jobGrade` player state bags, keeps the dead state in memory and uses `ox_inventory` items as money. Replace those with your own calls.

For the custom bridge, items must be usable through `ox_inventory` (add `consume = 0` to the item definition), because use is detected from `ox_inventory:usedItem`.

## Logging

Logs are posted straight to Discord webhooks from `server/logs.lua`, with no dependency on another resource. Set the `Webhook` local for regular logs and the `AntiCheatWebhook` local for anticheat logs. An empty string skips that webhook.

Categories: `death`, `revive`, `treatment`, `respawn`, `command`, `dispatch`, `item`, `suspicious`.

`suspicious` is raised when a client sends a request the server rejects (out of range, no permission, revive without being revived, and so on) and is sent to the anticheat webhook. Set `Config.logging.console = true` to also print every log to the server console.

## Client hooks

Use `Config.hooks` to connect phones, radios, handcuffs or key systems without editing the resource:

```lua
Config.hooks = {
    onDeath = function()
        exports['your-phone']:ToggleDisabled(true)
    end,
    onRevive = function()
        exports['your-phone']:ToggleDisabled(false)
    end,
    onRespawn = function() end,
    onVehicleSpawned = function(vehicle, plate)
        exports['your-keys']:GiveKeys(plate)
    end,
}
```

## Server events and exports

Server hooks are configured in `Config.serverHooks` and run in protected mode, so a broken hook never breaks the resource:

```lua
Config.serverHooks = {
    onPlayerDied = function(source, weapon) end,
    onPlayerRevived = function(source) end,
    onPlayerRespawned = function(source) end,
    onDistressCall = function(source, call)
        exports['your-dispatch']:Send(call.name, call.msg, call.gps)
    end,
    onInjuryTreated = function(source, target, bone) end,
    onEmergencyCallCompleted = function(source, call, reward) end,
}
```

`Config.hooks.notify` replaces the notification used by the whole client side, for example to use your own notify resource.

Server events fired for other resources (these are local-only, clients cannot trigger them):

- `ars_ambulancejob:playerDied (source, weapon)`
- `ars_ambulancejob:playerRevived (source)`

Exports:

- `exports.ars_ambulancejob:isPlayerDead(serverId)` (server)
- `exports.ars_ambulancejob:isMedic(serverId)` (server)
- `exports.ars_ambulancejob:getMedicsOnline()` (server)
- `exports.ars_ambulancejob:revivePlayer(serverId)` (server)
- `exports.ars_ambulancejob:healPlayer(serverId)` (server)
- `exports.ars_ambulancejob:isDead()` (client)
- `exports.ars_ambulancejob:createDistressCall()` (client)
- `exports.ars_ambulancejob:openDistressCalls()` (client)

## Security model

Clients can only ask; the server decides.

- Items are only ever added, removed or consumed by the server. There is no client event that grants an item.
- The medical bag is removed on use and returned only when the server finds the registered bag entity next to the player.
- Reviving requires a medic, a defibrillator, proximity and a dead target. The server consumes the item and performs the revive itself after the animation time.
- A dead player cannot leave the dead state unless the server authorised it (medic revive, admin command, paramedic, or respawn after the timer). Unauthorised attempts are logged as `suspicious` and the player is put back into the dead state.
- Respawn is validated against a server-side timer.
- Distress calls are validated, rate limited, capped and use the server-side position of the caller. Only medics can read or close them.
- Hospital stashes use `ox_inventory` group and distance checks.

## Commands

| Command | Description |
| --- | --- |
| `/revive [id]` | Revive a player |
| `/heal [id]` | Heal a player |
| `/revivearea <radius>` | Revive everyone within the radius |
| `/healarea <radius>` | Heal everyone within the radius |
| `/reviveall` | Revive everyone |
| `/911` | Send a distress call to online medics |
| `/emscalls` | Medics: list distress calls |

Command names are configurable in `Config.commands`.

## Structure

```
ars_ambulancejob
├── bridge/        framework support (ESX, QBCore, QBox, custom)
├── client/        client modules (death, patient, stretcher, garage, ...)
├── server/        server modules (death, treatment, inventory, dispatch, ...)
├── config/        shared configuration
├── locales/       translations
├── install/       items and icons to add to ox_inventory
├── stream/        stretcher prop
├── web/           death screen UI (Svelte), build output in web/build
└── fxmanifest.lua
```

To rebuild the UI: `cd web && npm install && npm run build`.

## Development

Opening the folder in VS Code suggests two extensions: [GTA V Asset Preview](https://marketplace.visualstudio.com/items?itemName=ncss-ltd.gta-v-asset-preview) (3D preview of `.ydr` files such as `stream/prop_ld_binbag_01.ydr`) and the Lua language server.

## License

Apache-2.0, see `LICENSE`. Original work by Arius Scripts.
