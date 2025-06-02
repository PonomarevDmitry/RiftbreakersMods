local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'cultivator_sapling_replacer_all_tool' ( tool )

function cultivator_sapling_replacer_all_tool:__init()
    tool.__init(self,self)
end

function cultivator_sapling_replacer_all_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function cultivator_sapling_replacer_all_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function cultivator_sapling_replacer_all_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_cultivator_sapling_replacer_all_tool", self.entity)
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
    markerDB:SetInt("menu_visible", 1)
end

function cultivator_sapling_replacer_all_tool:GetSaplingItem()

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

function cultivator_sapling_replacer_all_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function cultivator_sapling_replacer_all_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function cultivator_sapling_replacer_all_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function cultivator_sapling_replacer_all_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}
    local hashResult = {}

    local entitiesBuildings = {}

    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/flora_cultivator" ) )
    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/flora_cultivator_lvl_2" ) )
    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/flora_cultivator_lvl_3" ) )

    for entity in Iter( entitiesBuildings ) do

        if ( not EntityService:IsAlive(entity) ) then
            goto labelContinue
        end

        if ( hashResult[entity] == true ) then
            goto labelContinue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto labelContinue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName ~= "flora_cultivator" ) then
            goto labelContinue
        end

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil ) then

            local modItemBlueprint = EntityService:GetBlueprintName(modItem)

            if ( modItemBlueprint == self.SelectedItemBlueprint ) then

                goto labelContinue
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function cultivator_sapling_replacer_all_tool:OnRotate()
end

function cultivator_sapling_replacer_all_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/cultivator_sapling_tools/replace_all_cultivators")
        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end

function cultivator_sapling_replacer_all_tool:OnGuiPopupResultEvent( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:IsAlive( entity ) ) then

            local item = ItemService:GetFirstItemForBlueprint( entity, self.SelectedItemBlueprint )

            if item == INVALID_ID then

                item = ItemService:AddItemToInventory( entity, self.SelectedItemBlueprint )
            end

            ItemService:EquipItemInSlot( entity, item, "MOD_1" )

            BuildingService:BlinkBuilding(entity)
        end
    end
end

return cultivator_sapling_replacer_all_tool
 