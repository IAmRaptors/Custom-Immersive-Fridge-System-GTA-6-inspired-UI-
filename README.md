Real fridges in FiveM.

Walk up to any fridge prop — apartments, houses, bar counters, shop coolers —
open it, and it becomes shared cold storage for food and drinks, shown through
a clean rail-style menu instead of a boring stash grid.

FEATURES
 Every fridge prop in the world is interactable (models + custom coord pins)
 Rail-list menu: scroll to browse, counts on the right, Cancel at the bottom
 Add Item view: flips the list to YOUR consumables, store anything edible
 Consumables only — phones, IDs, licenses, guns, tools get bounced
 Shared per-fridge storage: contents live in THAT fridge, anyone can take
 Persists across restarts (resource KVP)
 10 item types per fridge (configurable)
 Handout animation on open, walk-away auto-close

COMPATIBILITY — autodetects at startup, no dependencies
 Inventory: ox_inventory / qb-core (qb, ps, lj inventories) / es_extended
 Target: ox_target / qb-target / qtarget / built-in [E] prompt fallback

TRANSFERS ARE DUPE-SAFE
The server verifies item counts actually moved before touching fridge
contents — nothing dupes, nothing vanishes.

INSTALL
1. Drop ace_fridge/ into resources/
2. ensure ace_fridge
3. Edit config.lua — models, custom spots, consumable list

CONTROLS
Up/Down or wheel  — browse
E / Enter         — take / add / confirm
Backspace / Esc   — back / close
