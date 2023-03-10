
local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'tower_mods_remover_tool' ( tool )

function tower_mods_remover_tool:__init()
    tool.__init(self,self)
end

function tower_mods_remover_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_tower_mods_remover_tool", self.entity)
    self.popupShown = false
end

function tower_mods_remover_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function tower_mods_remover_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function tower_mods_remover_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function tower_mods_remover_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function tower_mods_remover_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for  ent in Iter(selectedEntities ) do

        local blueprint = EntityService:GetBlueprintName(ent)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local towerComponent = EntityService:GetComponent( ent, "TowerComponent")
        if ( towerComponent == nil ) then
            goto continue
        end
            
        if ( not EntityService:CompareType( ent, "tower" ) ) then
            goto continue
        end

        local equipmentComponent = EntityService:GetComponent( ent, "EquipmentComponent")
        if ( equipmentComponent == nil ) then
            goto continue
        end

        if ( not self:HasTowerMods( ent ) ) then
            goto continue
        end

        Insert(entities, ent)

        ::continue::
    end

    return entities
end

function tower_mods_remover_tool:HasTowerMods( entity )

    local blueprintMod = ""

    local modItem1 = ItemService:GetEquippedItem( entity, "MOD_1" )

    if ( modItem1 ~= nil and modItem1 ~= INVALID_ID ) then
        return true
    end

    local buildingLevel = BuildingService:GetBuildingLevel( entity )

    if ( buildingLevel > 1) then
        local modItem2 = ItemService:GetEquippedItem( entity, "MOD_2" )

        if ( modItem2 ~= nil and modItem2 ~= INVALID_ID ) then
            return true
        end
    end

    if ( buildingLevel > 2) then
        local modItem3 = ItemService:GetEquippedItem( entity, "MOD_3" )

        if ( modItem3 ~= nil and modItem3 ~= INVALID_ID ) then
            return true
        end
    end

    return false
end

function tower_mods_remover_tool:OnActivateEntity( entity )

    BuildingService:BlinkBuilding(entity)

    --local selectorDB = EntityService:GetDatabase( self.selector )
    --selectorDB:SetString( "tower_mods_remover_tool.selecteditem", modItemBlueprint or "" )

    local buildingLevel = BuildingService:GetBuildingLevel( entity )

    local player = PlayerService:GetPlayerControlledEnt(0)

    local modItem1 = ItemService:GetEquippedItem( entity, "MOD_1" )

    if ( modItem1 ~= nil and modItem1 ~= INVALID_ID ) then
        blueprintMod = EntityService:GetBlueprintName(modItem1)
        LogService:Log( "OnActivateEntity modItem1 " .. tostring(blueprintMod) )

        QueueEvent("UnequipItemRequest", entity, modItem1, "MOD_1" )

        QueueEvent("RemoveItemFromInventoryRequest", entity, modItem1 )

        QueueEvent("AddItemToInventoryRequest", player, modItem1 )
    end

    if ( buildingLevel > 1) then
        local modItem2 = ItemService:GetEquippedItem( entity, "MOD_2" )

        if ( modItem2 ~= nil and modItem2 ~= INVALID_ID ) then

            blueprintMod = EntityService:GetBlueprintName(modItem2)
            LogService:Log( "OnActivateEntity modItem2 " .. tostring(blueprintMod) )

            QueueEvent("UnequipItemRequest", entity, modItem2, "MOD_2" )

            QueueEvent("RemoveItemFromInventoryRequest", entity, modItem2 )

            QueueEvent("AddItemToInventoryRequest", player, modItem2 )
        end
    end

    if ( buildingLevel > 2) then
        local modItem3 = ItemService:GetEquippedItem( entity, "MOD_3" )

        if ( modItem3 ~= nil and modItem3 ~= INVALID_ID ) then

            blueprintMod = EntityService:GetBlueprintName(modItem3)
            LogService:Log( "OnActivateEntity modItem3 " .. tostring(blueprintMod) )

            QueueEvent("UnequipItemRequest", entity, modItem3, "MOD_3" )

            QueueEvent("RemoveItemFromInventoryRequest", entity, modItem3 )

            QueueEvent("AddItemToInventoryRequest", player, modItem3 )
        end
    end

    --ItemService:EquipItemInSlot( entity, item, "MOD_1" )
end

return tower_mods_remover_tool
 