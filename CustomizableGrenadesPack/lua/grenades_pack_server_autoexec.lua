require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local itemList = {

    "items/skills/grenades_pack_1_item",
    "items/skills/grenades_pack_2_item",
    "items/skills/grenades_pack_3_item"
}

for itemName in Iter( itemList ) do

    if ( IndexOf( mod_autoadding_player_inventory_list, itemName ) == nil ) then

        Insert(mod_autoadding_player_inventory_list, itemName)
    end
end
