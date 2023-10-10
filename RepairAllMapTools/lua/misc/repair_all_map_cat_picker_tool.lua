local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'repair_all_map_cat_picker_tool' ( tool )

function repair_all_map_cat_picker_tool:__init()
    tool.__init(self,self)
end

function repair_all_map_cat_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_cat_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_cat_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }



    self.category_name = self.data:GetString("category_name")

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedCategory = selectorDB:GetStringOrDefault( self.category_name, "" ) or ""



    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetString("message_text", "")

    if ( self.selectedCategory ~= "" ) then

        local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

        markerDB:SetString("building_icon", menuIcon)
        markerDB:SetInt("building_visible", 1)
    else
        markerDB:SetInt("building_visible", 0)
    end

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function repair_all_map_cat_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function repair_all_map_cat_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function repair_all_map_cat_picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins)

    return selectedItems
end

function repair_all_map_cat_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local blueprintName = self:GetBlueprintName(entity)
        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        if ( self.selectedCategory ~= "" ) then
            if ( buildingDescRef.category == self.selectedCategory ) then
                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function repair_all_map_cat_picker_tool:GetBlueprintName( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function repair_all_map_cat_picker_tool:OnUpdate()
    self:HighlightRuins()
end

function repair_all_map_cat_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = self:GetBlueprintName(entity)
        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if ( baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescRef = reflection_helper(buildingDesc)

        local selectorDB = EntityService:GetDatabase( self.selector )

        selectorDB:SetString( self.category_name, buildingDescRef.category )


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

function repair_all_map_cat_picker_tool:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        EntityService:RemoveMaterial( ruinEntity, "selected" )

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        local skinned = EntityService:IsSkinned( ruinEntity )
        if ( skinned ) then
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey_skinned", "selected")
        else
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey", "selected")
        end
    end

    self.previousMarkedRuins = ruinsList
end

function repair_all_map_cat_picker_tool:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local ruinsList = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetDatabase( ruinEntity )
        if ( database == nil ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        Insert( result, ruinEntity )

        ::continue::
    end

    return result
end

function repair_all_map_cat_picker_tool:OnRelease()

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do
            EntityService:RemoveMaterial( ruinEntity, "selected" )
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return repair_all_map_cat_picker_tool
 