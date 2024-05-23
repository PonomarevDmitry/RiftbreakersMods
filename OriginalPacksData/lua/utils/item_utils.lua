require("lua/utils/reflection.lua")

function TryEquipItemOnSlot( player,  item )
    local slots = {
        "LEFT_HAND",
        "RIGHT_HAND",
    }
    local subSlotsCount = 2

    if ( ItemService:GetItemType( item ) == "upgrade") then
        slots = { 
            "UPGRADE_1",    
            "UPGRADE_2",
            "UPGRADE_3",
            "UPGRADE_4",
        }
        subSlotsCount = 0
    end

    for subslot=0,subSlotsCount do
        for slot in Iter(slots) do
            if ( PlayerService:TryEquipItemInSlot( player, item, slot, subslot) ) then
                return
            end
        end
    end
end