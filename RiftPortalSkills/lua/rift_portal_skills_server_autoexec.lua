require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local itemList = {

    "items/skills/rift_portal_temporary",
    "items/skills/rift_portal_personal",
    "items/skills/rift_jump_to_hq",
    "items/skills/rift_jump_to_nearest_portal"
}

for itemName in Iter( itemList ) do

    if ( IndexOf( mod_autoadding_player_inventory_list, itemName ) == nil ) then

        Insert(mod_autoadding_player_inventory_list, itemName)
    end
end
