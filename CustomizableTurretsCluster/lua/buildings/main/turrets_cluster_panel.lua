require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local building = require("lua/buildings/building.lua")
class 'turrets_cluster_panel' ( building )

function turrets_cluster_panel:__init()
    building.__init(self,self)
end

function turrets_cluster_panel:OnInit()

    if ( building.OnInit ) then
        building.OnInit(self)
    end

    self:RegisterEventHandlers()

    self.data:SetString("action_icon", "gui/menu/research/icons/consumable_sentry_gun" )
end

function turrets_cluster_panel:OnLoad()

    if ( building.OnLoad ) then
        building.OnLoad(self)
    end

    self:RegisterEventHandlers()

    self.data:SetString("action_icon", "gui/menu/research/icons/consumable_sentry_gun" )
end

function turrets_cluster_panel:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
end

function turrets_cluster_panel:OnItemEquippedEvent( evt )

    local slotName = evt:GetSlot()
    local item = evt:GetItem()

    local itemBlueprintName = ""

    if ( item ~= nil and item ~= INVALID_ID ) then
        itemBlueprintName = EntityService:GetBlueprintName(item)
    end

    LogService:Log("OnItemEquippedEvent itemBlueprintName " .. tostring(itemBlueprintName) .. " item " .. tostring(item))

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, "items/consumables/turrets_cluster_standard_item" )

    if ( turretsClusterItem == INVALID_ID ) then
        turretsClusterItem = ItemService:AddItemToInventory( player, "items/consumables/turrets_cluster_standard_item" )
    end

    LogService:Log("OnItemEquippedEvent turretsClusterItem " .. tostring(turretsClusterItem) )

    if ( turretsClusterItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( turretsClusterItem )

        database:SetString("turrets_cluster_" .. slotName, itemBlueprintName)
    end
end

function turrets_cluster_panel:OnItemUnequippedEvent( evt )

    local slotName = evt:GetSlot()

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, "items/consumables/turrets_cluster_standard_item" )

    if ( turretsClusterItem == INVALID_ID ) then
        turretsClusterItem = ItemService:AddItemToInventory( player, "items/consumables/turrets_cluster_standard_item" )
    end

    LogService:Log("OnItemEquippedEvent turretsClusterItem " .. tostring(turretsClusterItem) )

    if ( turretsClusterItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( turretsClusterItem )

        database:SetString("turrets_cluster_" .. slotName, "")
    end  
end

return turrets_cluster_panel
