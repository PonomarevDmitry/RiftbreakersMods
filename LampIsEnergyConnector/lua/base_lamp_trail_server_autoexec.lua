require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local itemList = {

    "items/skills/base_lamp_trail",
    "items/skills/crystal_lamp_trail"
}

for itemName in Iter( itemList ) do

    if ( IndexOf( mod_autoadding_player_inventory_list, itemName ) == nil ) then

        Insert(mod_autoadding_player_inventory_list, itemName)
    end
end
