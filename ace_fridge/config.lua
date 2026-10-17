-- █ ace_fridge · world fridges
-- Consumable-only storage on real fridge props (and custom pinned spots),
-- with the rail-style vending menu UI. Works standalone on Qbox, QB-Core and
-- ESX: the inventory adapter autodetects ox_inventory, qb-inventory family,
-- or ESX at startup. No dependencies.

Config = {}

Config.MaxItems   = 10    -- distinct item types per fridge
Config.Distance   = 1.8   -- how close you have to stand to the prop / spot
Config.MenuScale  = 0.5   -- menu size, 1.0 = full screen
Config.Label      = 'Open Fridge'
Config.Icon       = 'fa-solid fa-snowflake'

-- Prop models that get the fridge interaction automatically.
Config.Models = {
    'prop_fridge_01',
    'prop_fridge_02',
    'prop_fridge_03',
    'prop_vend_fridge01',
    'prop_bar_fridge_01',
    'prop_bar_fridge_02',
    'prop_bar_fridge_03',
    'prop_bar_fridge_04',
    'v_ilev_mm_fridge_r',
    'v_ilev_mm_fridge_l',
    'v_res_fridgemoda',
    'v_res_fridgemodsml',
}

-- Pinned spots for interiors/props the model list does not cover.
-- One vector3 per spot, at the fridge's center.
Config.CustomSpots = {
    -- vector3(0.0, 0.0, 0.0),
}

-- What counts as a fridge item. The list below is always allowed; on top of
-- that the resource merges consumable catalogs it finds on the server:
--   * vms_needs        -> config/config.items.lua (Config.Items)
--   * fs-shops         -> config/shops.lua        (Config.Shops, sans 'tools')
--   * prompt_anim_core -> config/config_s.lua     (supplement shop)
--   * ox_inventory     -> any item whose def has hunger/thirst/drunk status
-- Add your own item names here for anything those miss.
Config.Consumables = {
    'sandwich', 'burger', 'chicken_burger', 'hotdog', 'taco', 'burrito',
    'pizza_slice', 'fries', 'noodles', 'donut', 'cupcake', 'chocolate',
    'apple', 'banana', 'orange', 'pear', 'water', 'water_bottle',
    'ecola', 'ecola_can', 'sprunk', 'can_sprunk', 'bottle_sprunk',
    'kurkakola', 'coffee', 'beer', 'whiskey', 'vodka', 'wine',
    'twerks_candy', 'snikkel_candy',
}

-- Extra item names to always allow (merged with Config.Consumables).
Config.ExtraItems = {}

-- Always reject, even if a catalog lists it.
Config.Blocklist = {}
