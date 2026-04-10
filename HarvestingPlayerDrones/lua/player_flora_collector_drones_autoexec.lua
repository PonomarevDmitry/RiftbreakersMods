require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local itemList = {

    "items/upgrades/player_flora_collector_equipment_standard_item",
    "items/upgrades/player_flora_collector_equipment_advanced_item",
    "items/upgrades/player_flora_collector_equipment_superior_item",
    "items/upgrades/player_flora_collector_equipment_extreme_item"
}

for itemName in Iter( itemList ) do

    if ( IndexOf( mod_autoadding_player_inventory_list, itemName ) == nil ) then

        Insert(mod_autoadding_player_inventory_list, itemName)
    end
end
