
local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'cultivator_sapling_picker_tool' ( tool )

function cultivator_sapling_picker_tool:__init()
    tool.__init(self,self)
end

function cultivator_sapling_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_cultivator_sapling_picker_tool", self.entity)
    self.popupShown = false
    
    self.scaleMap = {
        1,
    }

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.SelectedItemBlueprint = selectorDB:GetStringOrDefault( "cultivator_sapling_picker_tool.selecteditem", "" )

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then
            
        local blueprint = ResourceManager:GetBlueprint( self.SelectedItemBlueprint )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local saplingIcon = componentRef.icon
        local saplingName = componentRef.name

        local markerDB = EntityService:GetDatabase( self.childEntity )
        markerDB:SetString("sapling_icon", saplingIcon)
        markerDB:SetString("sapling_name", saplingName)
        markerDB:SetInt("sapling_visible", 1)
    else
        self.SelectedItemBlueprint = ""
        markerDB:SetInt("sapling_visible", 0)
    end
end

function cultivator_sapling_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function cultivator_sapling_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function cultivator_sapling_picker_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function cultivator_sapling_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function cultivator_sapling_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function cultivator_sapling_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for  entity in Iter(selectedEntities ) do

        local blueprint = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprint )

        if ( lowName ~= "flora_cultivator" ) then
            goto continue
        end

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem == nil ) then

            goto continue
        end

        local modItemBlueprint = EntityService:GetBlueprintName(modItem)

        if ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" and modItemBlueprint == self.SelectedItemBlueprint ) then

            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function cultivator_sapling_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil ) then

            local modItemBlueprint = EntityService:GetBlueprintName(modItem)

            local selectorDB = EntityService:GetDatabase( self.selector )

            selectorDB:SetString( "cultivator_sapling_picker_tool.selecteditem", modItemBlueprint or "" )



            local replacerToolBlueprintDesc = BuildingService:GetBuildingDesc( "buildings/tools/sapling_replacer" )

            QueueEvent( "ChangeSelectorRequest", self.selector, replacerToolBlueprintDesc.bp ,replacerToolBlueprintDesc.ghost_bp )



            local replacerToolBlueprintDescHelper = reflection_helper(replacerToolBlueprintDesc)

            local replacerToolBlueprint = replacerToolBlueprintDescHelper.bp

            local lowName = BuildingService:FindLowUpgrade( replacerToolBlueprint )
                
            if ( lowName == replacerToolBlueprint ) then
                lowName = replacerToolBlueprintDescHelper.name
            end
            
            BuildingService:SetBuildingLastLevel( lowName, replacerToolBlueprintDescHelper.name)

            QueueEvent("ChangeBuildingRequest", self.selector, lowName )

            return
        end
    end
end


return cultivator_sapling_picker_tool
 