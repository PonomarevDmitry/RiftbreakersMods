local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'picker_tool' ( tool )

function picker_tool:__init()
    tool.__init(self,self)
end

function picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_picker", self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.selectedResourceComponents = {}

    self:FillSelectedBlueprints()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function picker_tool:FillSelectedBlueprints()

    self.resourceBluprintsNames = {

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "liquid_pump",

        "geothermal_powerplant",
    }

    self.resourceVolumeBluprintsNames = {

        "geothermal_powerplant",
    }

    local isCampaignBiome = MissionService:IsCampaignBiome()

    if ( isCampaignBiome ) then
        self:AddExpanedArsenalCampaignEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalCampaignEntities( self.resourceVolumeBluprintsNames )

        self:AddExpanedArsenalSurvivalEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalSurvivalEntities( self.resourceVolumeBluprintsNames )
    else
        self:AddExpanedArsenalSurvivalEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalSurvivalEntities( self.resourceVolumeBluprintsNames )

        self:AddExpanedArsenalCampaignEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalCampaignEntities( self.resourceVolumeBluprintsNames )
    end

    self.selectedBluprintsHash = {

        ["wind_turbine"] = "buildings/energy/wind_turbine",
        ["solar_panels"] = "buildings/energy/solar_panels",

        ["floor_desert_1x1"] = "buildings/decorations/floor_desert_1x1",

        ["floor_acid_1x1"] = "buildings/decorations/floor_acid_1x1",

        ["cryo_station"] = "buildings/main/cryo_station",

        ["carbonium_factory"] = "buildings/resources/carbonium_factory",
        ["steel_factory"] = "buildings/resources/steel_factory",
        ["rare_element_mine"] = "buildings/resources/rare_element_mine",

        ["liquid_pump"] = "buildings/resources/liquid_pump",

        ["geothermal_powerplant"] = "buildings/energy/geothermal_powerplant",

        -- Expaned Arsenal Entities
        ["acid_refinery"] = "buildings/resources/acid_refinery",
        ["magma_lifter"] = "buildings/resources/magma_lifter",
        ["supercoolant_siphon"] = "buildings/resources/supercoolant_siphon",

        ["morphium_extractor"] = "buildings/resources/morphium_extractor",

        ["survival_acid_refinery"] = "buildings/resources/survival_acid_refinery",
        ["survival_magma_lifter"] = "buildings/resources/survival_magma_lifter",
        ["survival_supercoolant_siphon"] = "buildings/resources/survival_supercoolant_siphon",
    }
end

function picker_tool:AddExpanedArsenalCampaignEntities( list )

    Insert( list, "acid_refinery" )
    Insert( list, "magma_lifter" )
    Insert( list, "supercoolant_siphon" )

    Insert( list, "morphium_extractor" )
end

function picker_tool:AddExpanedArsenalSurvivalEntities( list )

    Insert( list, "survival_acid_refinery" )
    Insert( list, "survival_magma_lifter" )
    Insert( list, "survival_supercoolant_siphon" )
end

function picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function picker_tool:AddedToSelection( entity )

    self:MarkEntity( entity )
end

function picker_tool:MarkEntity( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        self.selectedResourceComponents = self.selectedResourceComponents or {}

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                goto continue
            end

            if ( IndexOf( self.selectedResourceComponents, childResource ) == nil ) then
                Insert( self.selectedResourceComponents, childResource )
            end

            QueueEvent( "SelectEntityRequest", childResource )

            ::continue::
        end

    elseif ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "SelectEntityRequest", entity )
        end
    else

        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
        end
    end
end

function picker_tool:RemovedFromSelection( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        self.selectedResourceComponents = self.selectedResourceComponents or {}

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                goto continue
            end

            if ( IndexOf( self.selectedResourceComponents, childResource ) ~= nil ) then
                Remove( self.selectedResourceComponents, childResource )
            end

            QueueEvent( "DeselectEntityRequest", childResource )

            ::continue::
        end

    elseif ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "DeselectEntityRequest", entity )
        end
    else

        EntityService:RemoveMaterial( entity, "selected" )
    end
end

function picker_tool:OnUpdate()

    self:HighlightRuins()

    for entity in Iter( self.selectedEntities ) do

        self:MarkEntity( entity )
    end
end

function picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local selectorPosition = selectorComponent.position

    self:AddRuins( selectedItems, selectorPosition )

    self:AddResourceVolumes( selectedItems, selectorPosition )

    self:AddResourceComponents( selectedItems, selectorPosition )

    return selectedItems
end

function picker_tool:AddRuins( selectedItems, selectorPosition )

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(selectorPosition, scaleVector)
    local max = VectorAdd(selectorPosition, scaleVector)

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins )
end

function picker_tool:AddResourceVolumes( selectedItems, selectorPosition )

    local resourceVolumeEntities = {}

    local predicate = {

        signature="ResourceVolumeComponent"
    }

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(selectorPosition, scaleVector)
    local max = VectorAdd(selectorPosition, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( resourceVolumeEntities, entity ) ~= nil ) then
            goto continue
        end

        Insert( resourceVolumeEntities, entity )

        ::continue::
    end

    local sorter = function( lhs, rhs )
        local position1 = EntityService:GetPosition( lhs )
        local position2 = EntityService:GetPosition( rhs )
        local distance1 = Distance( selectorPosition, position1 )
        local distance2 = Distance( selectorPosition, position2 )
        return distance1 < distance2
    end

    table.sort(resourceVolumeEntities, sorter)

    ConcatUnique( selectedItems, resourceVolumeEntities )
end

function picker_tool:AddResourceComponents( selectedItems, selectorPosition )

    local resourceComponents = {}

    local predicate = {

        signature="ResourceComponent"
    }

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(selectorPosition, scaleVector)
    local max = VectorAdd(selectorPosition, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( resourceComponents, entity ) ~= nil ) then
            goto continue
        end

        Insert( resourceComponents, entity )

        ::continue::
    end

    local sorter = function( lhs, rhs )
        local position1 = EntityService:GetPosition( lhs )
        local position2 = EntityService:GetPosition( rhs )
        local distance1 = Distance( selectorPosition, position1 )
        local distance2 = Distance( selectorPosition, position2 )
        return distance1 < distance2
    end

    table.sort(resourceComponents, sorter)

    ConcatUnique( selectedItems, resourceComponents )
end

function picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) == false ) then
            goto continue
        end

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )

        if ( #list == 0 ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function picker_tool:OnActivateSelectorRequest()

    local isBuilding = function( entity )
        if( EntityService:GetGroup( entity ) == "##ruins##" ) then

            return false
        end

        if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

            return false
        end

        if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

            return false
        end

        return true
    end

    local isRuins = function ( entity )

        if( EntityService:GetGroup( entity ) == "##ruins##" ) then

            return true
        end

        return false
    end

    local isResource = function ( entity )

        if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

            return true
        end

        return false
    end

    local isResourceVolume = function ( entity )

        if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

            return true
        end

        return false
    end

    if ( self:ChangeSelectorToEntityByFilter( isBuilding ) ) then
        return
    end

    if ( self:ChangeSelectorToEntityByFilter( isRuins ) ) then
        return
    end

    if ( self:ChangeSelectorToEntityByFilter( isResource ) ) then
        return
    end

    if ( self:ChangeSelectorToEntityByFilter( isResourceVolume ) ) then
        return
    end






    local currentBiome = MissionService:GetCurrentBiomeName()

    local currentEntityPosition = EntityService:GetPosition( self.entity )

    local terrainType, overrideTerrains = self:GetTerrainTypes( currentEntityPosition )

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        local lowName = "floor_desert_1x1"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end

    local isCreeperArea = (IndexOf( overrideTerrains, "creeper_area" ) ~= nil)
    if ( isCreeperArea ) then

        local lowName = "floor_acid_1x1"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end

    local isCryoGround = ( IndexOf( overrideTerrains, "cryo_ground" ) )
    local isHotGround = ( terrainType == "magma_hot_ground" or terrainType == "magma_very_hot_ground" or IndexOf( overrideTerrains, "magma_hot_ground" ) ~= nil or IndexOf( overrideTerrains, "magma_very_hot_ground" ) ~= nil )

    local isFloor = false
    for overrideTerrainType in Iter( overrideTerrains ) do

        if ( string.find(overrideTerrainType, "floor") ~= nil ) then

            isFloor = true
        end
    end

    if ( isHotGround and not isCryoGround and not isFloor ) then

        local lowName = "cryo_station"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end



    if ( currentBiome == "caverns" ) then

        local minModificator = 0.05

        local windModificator = BuildingService:GetWindPowerModificator( self.entity )
        if ( windModificator >= minModificator ) then

            local lowName = "wind_turbine"
            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return
            end
        end

        local solarModificator = BuildingService:GetSolarPowerModificator( self.entity )
        if ( solarModificator >= minModificator ) then

            local lowName = "solar_panels"
            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return
            end
        end
    end
end

function picker_tool:GetTerrainTypes( position )

    local terrainType = ""
    local overrideTerrains = {}

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(position)

    if ( terrainCellEntityId ~= nil and terrainCellEntityId ~= INVALID_ID ) then

        local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

        if ( terrainTypeLayerComponent ~= nil ) then

            local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

            if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

                terrainType = terrainTypeLayerComponentRef.terrain_type.resource.name
            end
        end

        local overrideTerrainComponent = EntityService:GetComponent( terrainCellEntityId, "OverrideTerrainComponent" )

        if ( overrideTerrainComponent ~= nil ) then

            local overrideTerrainComponentRef = reflection_helper(overrideTerrainComponent)

            if ( overrideTerrainComponentRef.terrain_overrides ) then

                for i=1,overrideTerrainComponentRef.terrain_overrides.count do

                    local terrainTypeHolder = overrideTerrainComponentRef.terrain_overrides[i]

                    if ( terrainTypeHolder and terrainTypeHolder.resource and terrainTypeHolder.resource.name ) then

                        if ( IndexOf( overrideTerrains, terrainTypeHolder.resource.name ) == nil ) then
                            Insert( overrideTerrains, terrainTypeHolder.resource.name )
                        end
                    end
                end
            end
        end
    end

    --LogService:Log("terrainCellEntityId " .. tostring(terrainCellEntityId) .. " terrainType " .. tostring(terrainType) .. " overrideTerrains " .. table.concat( overrideTerrains, "," ))

    return terrainType, overrideTerrains
end

function picker_tool:ChangeSelectorToEntityByFilter( filterFunc )

    for entity in Iter( self.selectedEntities ) do

        if ( filterFunc(entity) ) then

            local blueprintName = self:GetLinkedEntityBlueprint( entity ) or ""

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return true
            end
        end
    end

    return false
end

function picker_tool:GetLinkedEntityBlueprint( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            return database:GetString("blueprint") or ""
        end
    end

    if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        local blueprintName = self:GetMineBlueprintName( entity, self.resourceBluprintsNames ) or ""

        return blueprintName
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        local blueprintName = self:GetMineBlueprintName( entity, self.resourceVolumeBluprintsNames ) or ""

        return blueprintName
    end

    return EntityService:GetBlueprintName(entity)
end

function picker_tool:ChangeSelectorToBlueprint( blueprintName )

    if ( blueprintName == "" ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local baseDesc = BuildingService:FindBaseBuilding( blueprintName )
    if  (baseDesc ~= nil ) then
        buildingDesc = baseDesc
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return false
    end

    local buildingDescHelper = reflection_helper(buildingDesc)

    blueprintName = buildingDescHelper.bp

    QueueEvent( "ChangeSelectorRequest", self.selector, buildingDescHelper.bp, buildingDescHelper.ghost_bp )

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName == blueprintName ) then
        lowName = buildingDescHelper.name
    end

    BuildingService:SetBuildingLastLevel( lowName, buildingDescHelper.name )

    QueueEvent("ChangeBuildingRequest", self.selector, lowName )

    return true
end

function picker_tool:GetMineBlueprintName( entity, selectedBluprintsNames )

    local resourceId = self:GetLinkedResource(entity)

    if ( resourceId ~= "" ) then

        for lowName in Iter( selectedBluprintsNames ) do

            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            if ( not ResourceManager:ResourceExists( "EntityBlueprint", defaultBlueprintName ) ) then
                goto continue
            end

            local buildingDesc = BuildingService:GetBuildingDesc( defaultBlueprintName )
            if ( buildingDesc == nil ) then
                goto continue
            end

            local buildingDescRef = reflection_helper( buildingDesc )

            local resourceRequirement = buildingDescRef.resource_requirement
            if ( resourceRequirement == nil or resourceRequirement.count <= 0 ) then
                goto continue
            end

            local isResourceRequired = self:IsResourceRequired( resourceRequirement, resourceId )
            if ( not isResourceRequired ) then
                goto continue
            end

            do
                return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
            end

            ::continue::
        end
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) and EntityService:CompareType( entity, "water" ) ) then

        local lowName = "liquid_pump"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
    end

    return ""
end

function picker_tool:GetLinkedResource( entity )

    local resourceComponent = EntityService:GetComponent( entity, "ResourceComponent" )
    if ( resourceComponent ~= nil ) then

        local resourceComponentRef = reflection_helper( resourceComponent )

        if ( resourceComponentRef.type ~= nil and resourceComponentRef.type.resource ~= nil and resourceComponentRef.type.resource.id ~= nil ) then

            local resourceId = resourceComponentRef.type.resource.id or ""

            if ( resourceId ~= "" ) then
                return resourceId
            end
        end
    end

    local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
    if ( resourceVolumeComponent ~= nil ) then

        local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

        if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then

            local resourceId = resourceVolumeComponentRef.type.resource.id or ""

            if ( resourceId ~= "" ) then
                return resourceId
            end
        end
    end

    return ""
end

function picker_tool:IsResourceRequired( resourceRequirement, resourceId )

    for i = 1,resourceRequirement.count do

        local resource = resourceRequirement[i]

        if ( resource ~= nil and resource ~= "" ) then

            if ( resource == resourceId ) then

                return true
            end
        end
    end

    return false
end

function picker_tool:GetSelectorBlueprintName( lowName, defaultBlueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", defaultBlueprintName ) ) then
        return ""
    end

    return self:GetMaxAvailableLevel( defaultBlueprintName )
end

function picker_tool:GetMaxAvailableLevel( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return ""
    end

    if ( buildingRef.upgrade ~= nil and buildingRef.upgrade ~= "" ) then

        if ( self:IsBlueprintAvailable( buildingRef.upgrade ) ) then

            return self:GetMaxAvailableLevel( buildingRef.upgrade )
        end
    end

    return blueprintName
end

function picker_tool:IsBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self:GetResearchForUpgrade( blueprintName ) or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function picker_tool:GetResearchForUpgrade( blueprintName )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function picker_tool:HighlightRuins()

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

function picker_tool:FindBuildingRuins()

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

function picker_tool:OnRelease()

    if ( self.selectedResourceComponents ~= nil) then

        for childResource in Iter( self.selectedResourceComponents ) do
            QueueEvent( "DeselectEntityRequest", childResource )
        end
    end
    self.selectedResourceComponents = {}

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

return picker_tool