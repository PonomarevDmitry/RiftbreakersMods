local sell_by_type_base = require("lua/misc/sell_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_picker_tool' ( sell_by_type_base )

function sell_by_type_picker_tool:__init()
    sell_by_type_base.__init(self,self)
end

function sell_by_type_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetString("message_text", "")

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetInt("building_visible", 1)
        else

            markerDB:SetInt("building_visible", 0)
        end
    else
        markerDB:SetInt("building_visible", 0)
    end
end

function sell_by_type_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function sell_by_type_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function sell_by_type_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_by_type_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingComponentRef = reflection_helper(buildingComponent)
        if ( buildingComponentRef.m_isSellable == false ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        if ( self:IsBlueprintInList(blueprintName) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_by_type_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if (baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        blueprintName = buildingDescHelper.bp

        local selectorDB = EntityService:GetDatabase( self.selector )

        selectorDB:SetString( self.template_name, blueprintName or "" )




        if ( self.next_tool ~= "" ) then

            local nextToolBuildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( self.next_tool ) )

            QueueEvent( "ChangeSelectorRequest", self.selector, nextToolBuildingDescRef.bp, nextToolBuildingDescRef.ghost_bp )

            local nextToolBlueprintName = nextToolBuildingDescRef.bp

            local lowName = BuildingService:FindLowUpgrade( nextToolBlueprintName )

            if ( lowName == nextToolBlueprintName ) then
                lowName = nextToolBuildingDescRef.name
            end

            BuildingService:SetBuildingLastLevel( lowName, nextToolBuildingDescRef.name )

            QueueEvent( "ChangeBuildingRequest", self.selector, lowName )
        end

        do
            return
        end

        ::continue::
    end
end

return sell_by_type_picker_tool
 