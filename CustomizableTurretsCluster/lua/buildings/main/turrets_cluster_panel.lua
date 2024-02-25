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

    self.skillName = self.data:GetStringOrDefault("skill_name", "items/skills/turrets_cluster_1_item")
end

function turrets_cluster_panel:OnLoad()

    if ( building.OnLoad ) then
        building.OnLoad(self)
    end

    self:RegisterEventHandlers()

    self.data:SetString("action_icon", "gui/menu/research/icons/consumable_sentry_gun" )

    self.skillName = self.data:GetStringOrDefault("skill_name", "items/skills/turrets_cluster_1_item")
end

function turrets_cluster_panel:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
end

function turrets_cluster_panel:OnBuildingEnd()

    if ( building.OnBuildingEnd ) then
        building.OnBuildingEnd(self)
    end

    self:OnOperateActionMenuEvent()
end

function turrets_cluster_panel:OnOperateActionMenuEvent()

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if ( player == INVALID_ID or player == nil ) then
        return
    end

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, self.skillName )
    if ( turretsClusterItem == INVALID_ID ) then
        turretsClusterItem = ItemService:AddItemToInventory( player, self.skillName )
    end

    if ( turretsClusterItem == INVALID_ID ) then
        return
    end

    local database = EntityService:GetDatabase( turretsClusterItem )
    if ( database == nil ) then
        return
    end

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ~= nil ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local keyName = "turrets_cluster_" .. slot.name

            local itemBlueprintName = ""

            if ( database:HasString(keyName) ) then
                itemBlueprintName = database:GetStringOrDefault(keyName, "") or ""
            end

            if ( itemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", itemBlueprintName ) ) then

                local item = ItemService:GetFirstItemForBlueprint( self.entity, itemBlueprintName )

                if ( item == INVALID_ID ) then
                    item = ItemService:AddItemToInventory( self.entity, itemBlueprintName )
                end

                if ( item ~= INVALID_ID ) then

                    QueueEvent( "EquipmentChangeRequest", self.entity, slot.name, 0, item )
                else

                    QueueEvent( "EquipmentChangeRequest", self.entity, slot.name, 0, INVALID_ID )
                end
            else

                QueueEvent( "EquipmentChangeRequest", self.entity, slot.name, 0, INVALID_ID )
            end
        end
    end    
end

function turrets_cluster_panel:OnItemEquippedEvent( evt )

    local slotName = evt:GetSlot()
    local item = evt:GetItem()

    local itemBlueprintName = ""

    if ( item ~= nil and item ~= INVALID_ID ) then
        itemBlueprintName = EntityService:GetBlueprintName(item)
    end

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if ( player == INVALID_ID or player == nil ) then
        return
    end

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, self.skillName )
    if ( turretsClusterItem == INVALID_ID ) then
        turretsClusterItem = ItemService:AddItemToInventory( player, self.skillName )
    end

    if ( turretsClusterItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( turretsClusterItem )

        database:SetString("turrets_cluster_" .. slotName, itemBlueprintName)
    end
end

function turrets_cluster_panel:OnItemUnequippedEvent( evt )

    local slotName = evt:GetSlot()

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if ( player == INVALID_ID or player == nil ) then
        return
    end

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, self.skillName )

    if ( turretsClusterItem == INVALID_ID ) then
        turretsClusterItem = ItemService:AddItemToInventory( player, self.skillName )
    end

    if ( turretsClusterItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( turretsClusterItem )

        database:SetString("turrets_cluster_" .. slotName, "")
    end  
end

return turrets_cluster_panel
