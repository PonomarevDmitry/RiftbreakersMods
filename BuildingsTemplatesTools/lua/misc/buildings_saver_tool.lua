local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'buildings_saver_tool' ( tool )

function buildings_saver_tool:__init()
    tool.__init(self,self)
end

function buildings_saver_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_buildings_saver_tool", self.entity)
    self.popupShown = false

    self.SelectedItemBlueprint = self:GetSaplingItem()

    local blueprint = ResourceManager:GetBlueprint( self.SelectedItemBlueprint )

    local component = blueprint:GetComponent("InventoryItemComponent")

    local componentRef = reflection_helper(component)

    local saplingIcon = componentRef.icon
    local saplingName = componentRef.name

    local markerDB = EntityService:GetDatabase( self.childEntity )
    markerDB:SetString("sapling_icon", saplingIcon)
    markerDB:SetString("sapling_name", saplingName)
    markerDB:SetInt("sapling_visible", 1)
end

function buildings_saver_tool:GetSaplingItem()

    local DEFAULT_SAPLING_BLUEPRINT = "items/loot/saplings/biomas_sapling_item"

    local selectorDB = EntityService:GetDatabase( self.selector )

    if selectorDB:HasString("cultivator_sapling_picker_tool.selecteditem") then

        local sapling_item = selectorDB:GetStringOrDefault( "cultivator_sapling_picker_tool.selecteditem", "" )

        if ( sapling_item ~= nil and sapling_item ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", sapling_item ) ) then
            return sapling_item
        end
    end

    local biome_default_item = "items/loot/saplings/biomas_sapling_" .. MissionService:GetCurrentBiomeName() .. "_item"

    if ( ResourceManager:ResourceExists( "EntityBlueprint", biome_default_item ) ) then
        return biome_default_item
    end

    return DEFAULT_SAPLING_BLUEPRINT
end

function buildings_saver_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function buildings_saver_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function buildings_saver_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function buildings_saver_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function buildings_saver_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    
    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName ~= "flora_cultivator" ) then
            goto continue
        end

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil ) then

            local modItemBlueprint = EntityService:GetBlueprintName(modItem)

            if ( modItemBlueprint == self.SelectedItemBlueprint ) then

                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function buildings_saver_tool:OnActivateEntity( entity )

    local item = ItemService:GetFirstItemForBlueprint( entity, self.SelectedItemBlueprint )

    if item == INVALID_ID then

        item = ItemService:AddItemToInventory( entity, self.SelectedItemBlueprint )
    end

    ItemService:EquipItemInSlot( entity, item, "MOD_1" )

    BuildingService:BlinkBuilding(entity)
end

return buildings_saver_tool
 