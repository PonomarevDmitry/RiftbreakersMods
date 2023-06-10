local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'upgrade_all_map_cat_picker_tool' ( tool )

function upgrade_all_map_cat_picker_tool:__init()
    tool.__init(self,self)
end

function upgrade_all_map_cat_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function upgrade_all_map_cat_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function upgrade_all_map_cat_picker_tool:OnInit()

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

    -- List of buildings highlighted for upgrade
    self.previousMarkedBuildings = {}
    -- Radius from player to highlight buildings for upgrade
    self.radiusShowBuildingsToUpgrade = 100.0
end

function upgrade_all_map_cat_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function upgrade_all_map_cat_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function upgrade_all_map_cat_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function upgrade_all_map_cat_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

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

function upgrade_all_map_cat_picker_tool:OnUpdate()

    self:HighlightBuildingsToUpgrade()
end

function upgrade_all_map_cat_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

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

            local transform = EntityService:GetWorldTransform( entity )
            EntityService:SetEntityWorldTransform( entity, transform )

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

function upgrade_all_map_cat_picker_tool:HighlightBuildingsToUpgrade()

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = self:FindUpgradableBuildings()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    -- Remove highlighting from previous buildings
    for entity in Iter( self.previousMarkedBuildings ) do

        -- If the building is not included in the new list
        if ( IndexOf( buildings, entity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        self:RemovedFromSelection( entity )

        ::continue::
    end

    for entity in Iter( buildings ) do

        -- Highlight building if it can be upgraded
        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end
    end

    self.previousMarkedBuildings = buildings
end

function upgrade_all_map_cat_picker_tool:FindUpgradableBuildings()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildingsToUpgrade )

    local result = {}

    for entity in Iter( buildings ) do

        -- Skip buildins from result
        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        -- Skip buildins from self.selectedEntities
        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        -- Highlight building if it can be upgraded
        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function upgrade_all_map_cat_picker_tool:OnRelease()

    -- Remove highlighting from buildings
    if ( self.previousMarkedBuildings ~= nil ) then
        for ent in Iter( self.previousMarkedBuildings ) do

            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return upgrade_all_map_cat_picker_tool
 