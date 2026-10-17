# ace_fridge

> Real fridges in FiveM. Walk up to any fridge prop — apartments, houses,
> bar counters, shop coolers — open it, and it becomes shared cold storage
> for food and drinks, shown through a clean rail-style menu instead of a
> boring stash grid.

**One-line:** consumable-only fridge storage with a vending-machine-style UI — works on Qbox, QB-Core, and ESX.

---

## What it does

Fridges stop being furniture. Every fridge prop in the world (plus any custom
spots you pin by coordinates) becomes an interactable storage point:

- **Browse** what's inside through a rail list menu — scroll or arrow keys,
  item counts on the right, `Cancel` at the bottom
- **Take** items out — select a row, one unit moves to your pockets
- **Add Item** — flips the list to *your* consumables; store drinks, snacks,
  groceries, anything edible
- **Consumables only** — phones, IDs, licenses, guns, tools all get bounced.
  It's a fridge, not a locker.
- **Shared per-fridge storage** — contents live in *that* fridge. Stock the
  24/7 cooler and a customer can buy it empty. Persist across restarts.
- **10 item types** per fridge (configurable)

## Framework support

Zero hard dependencies. Everything autodetects at startup:

| Layer | Supported |
|---|---|
| Inventory | `ox_inventory` · `qb-core` (qb/ps/lj inventories) · `es_extended` |
| Target | `ox_target` · `qb-target` · `qtarget` · built-in `[E]` prompt fallback |

Transfers are dupe-safe: item counts are verified before the fridge store
is touched, so nothing ever dupes or vanishes.

## Install

1. Drop `ace_fridge/` into your `resources/` folder
2. `ensure ace_fridge` in `server.cfg`
3. Edit `config.lua` — add models, pin spots, extend the consumable list

## Config

```lua
Config.Models        -- fridge prop models that auto-register
Config.CustomSpots   -- vector3 pins for fridges the model list misses
Config.Consumables   -- item names always allowed
Config.ExtraItems    -- your additions
Config.Blocklist     -- always reject, even if a catalog lists it
Config.MaxItems      -- distinct item types per fridge (default 10)
Config.MenuScale     -- menu size (default 0.5)
```

On top of the config list, any ox_inventory item carrying a
hunger/thirst/drunk status counts as a consumable automatically.

## Controls

| Input | Action |
|---|---|
| ↑ / ↓ or scroll | browse the list |
| `E` / `Enter` | take item / add item / confirm |
| `Backspace` / `Esc` | back / close |

## Credits

Menu UI style inspired by rail-list supplement shops. Built for StarCity RP.
