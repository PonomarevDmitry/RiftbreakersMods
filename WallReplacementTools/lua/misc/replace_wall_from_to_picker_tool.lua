local replace_wall_from_to_base = require("lua/misc/replace_wall_from_to_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_wall_from_to_picker_tool' ( replace_wall_from_to_base )

function replace_wall_from_to_picker_tool:__init()
    replace_wall_from_to_base.__init(self,self)
end

function replace_wall_from_to_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function replace_wall_from_to_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function replace_wall_from_to_picker_tool:OnInit()

    self.marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(self.marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.template_name = self.data:GetString("template_name")

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.selectedBlueprints = {}

    self.cacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.selectedBuildingBlueprint, self.selectedBlueprints, self.cacheBlueprintsLowNames)

    self:SetBuildingIcon()
end

function replace_wall_from_to_picker_tool:SetBuildingIcon()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("wall_name", buildingDescRef.localization_id)

            markerDB:SetString("wall_icon", menuIcon)
            markerDB:SetInt("wall_icon_visible", 1)
        else
        
            markerDB:SetString("wall_name", "")
            markerDB:SetInt("wall_icon_visible", 0)
        end
    else
        markerDB:SetString("wall_name", "")
        markerDB:SetInt("wall_icon_visible", 0)
    end
end

function replace_wall_from_to_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function replace_wall_from_to_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function replace_wall_from_to_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function replace_wall_from_to_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName == "wall_small_floor" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingRef = reflection_helper(buildingDesc)

        if ( buildingRef.type ~= "wall" or buildingRef.category == "decorations" ) then
            goto continue
        end

        if ( self:IsBlueprintInList( self.selectedBlueprints, self.cacheBlueprintsLowNames, blueprintName) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_wall_from_to_picker_tool:OnActivateSelectorRequest()

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

        blueprintName = buildingDescHelper.bp or "" 

        local selectorDB = EntityService:GetDatabase( self.selector )

        selectorDB:SetString( self.template_name, blueprintName )

        self.selectedBuildingBlueprint = blueprintName

        self.selectedBlueprints = {}

        self.cacheBlueprintsLowNames = {}

        self:InitBlueprintList(self.selectedBuildingBlueprint, self.selectedBlueprints, self.cacheBlueprintsLowNames)

        self:SetBuildingIcon()

        do
            return;
        end

        ::continue::
    end
end

return replace_wall_from_to_picker_tool