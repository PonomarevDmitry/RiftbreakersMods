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

    self.selectedBluprintsNames = {

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "liquid_pump",

        "geothermal_powerplant",
    }

    local isCampaignBiome = MissionService:IsCampaignBiome()

    if ( isCampaignBiome ) then
        self:AddExpanedArsenalCampaignEntities( self.selectedBluprintsNames )
        self:AddExpanedArsenalSurvivalEntities( self.selectedBluprintsNames )
    else
        self:AddExpanedArsenalSurvivalEntities( self.selectedBluprintsNames )
        self:AddExpanedArsenalCampaignEntities( self.selectedBluprintsNames )
    end

    self.selectedBluprintsHash = {

        ["wind_turbine"] = "buildings/energy/wind_turbine",
        ["solar_panels"] = "buildings/energy/solar_panels",

        ["carbonium_factory"] = "buildings/resources/carbonium_factory",
        ["steel_factory"] = "buildings/resources/steel_factory",
        ["rare_element_mine"] = "buildings/resources/rare_element_mine",

        ["liquid_pump"] = "buildings/resources/liquid_pump",

        ["geothermal_powerplant"] = "buildings/energy/geothermal_powerplant",

        -- Expaned Arsenal Entities
        ["acid_refinery"] = "buildings/resources/acid_refinery",
        ["magma_lifter"] = "buildings/resources/magma_lifter",
        ["supercoolant_siphon"] = "buildings/resources/supercoolant_siphon",

        ["survival_acid_refinery"] = "buildings/resources/survival_acid_refinery",
        ["survival_magma_lifter"] = "buildings/resources/survival_magma_lifter",
        ["survival_supercoolant_siphon"] = "buildings/resources/survival_supercoolant_siphon",
    }
end

function picker_tool:AddExpanedArsenalCampaignEntities( list )

    Insert( list, "acid_refinery" )
    Insert( list, "magma_lifter" )
    Insert( list, "supercoolant_siphon" )
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

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        self.selectedResourceComponents = self.selectedResourceComponents or {}

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            if ( IndexOf( self.selectedResourceComponents, childResource ) ~= nil ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                goto continue
            end

            Insert( self.selectedResourceComponents, childResource )

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

            if ( IndexOf( self.selectedResourceComponents, childResource ) == nil ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                goto continue
            end

            if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                goto continue
            end

            Remove( self.selectedResourceComponents, childResource )

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
end

function picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize, self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize, self.currentScale - 0.5))

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins )

    self:AddResourceVolumes( selectedItems, min, max )

    self:AddResourceComponents( selectedItems, position )

    return selectedItems
end

function picker_tool:AddResourceVolumes( selectedItems, min, max )

    local resourceVolumeEntities = {}

    local predicate = {

        signature="ResourceVolumeComponent"
    };

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

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( position, p1 )
        local d2 = Distance( position, p2 )
        return d1 < d2
    end

    table.sort(resourceVolumeEntities, function(a,b)
        return sorter(resourceVolumeEntities, a, b)
    end)

    ConcatUnique( selectedItems, resourceVolumeEntities )
end

function picker_tool:AddResourceComponents( selectedItems, selectorPosition )

    local resourceComponents = {}

    local predicate = {

        signature="ResourceComponent,GridMarkerComponent"
    };

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local min = VectorSub(selectorPosition, VectorMulByNumber(boundsSize, self.currentScale))
    local max = VectorAdd(selectorPosition, VectorMulByNumber(boundsSize, self.currentScale))

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( resourceComponents, entity ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:CompareType( entity, "resource" ) ) then
            goto continue
        end

        local positionTemp = EntityService:GetPosition( entity )

        if ( not ( min.x <= positionTemp.x and positionTemp.x <= max.x ) ) then
            goto continue
        end

        if ( not ( min.z <= positionTemp.z and positionTemp.z <= max.z ) ) then
            goto continue
        end

        Insert( resourceComponents, entity )

        ::continue::
    end

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( position, p1 )
        local d2 = Distance( position, p2 )
        return d1 < d2
    end

    table.sort(resourceComponents, function(a,b)
        return sorter(resourceComponents, a, b)
    end)

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
    if ( currentBiome ~= "caverns" ) then
        return
    end

    local windModificator = BuildingService:GetWindPowerModificator( self.entity )

    local minModificator = 0.05

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

        local blueprintName = self:GetMineBlueprintName( entity ) or ""

        return blueprintName
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        local blueprintName = self:GetMineBlueprintName( entity ) or ""

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

    local baseDesc= BuildingService:FindBaseBuilding( blueprintName )
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

function picker_tool:GetMineBlueprintName( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) and EntityService:CompareType( entity, "water" ) ) then

        local lowName = "liquid_pump"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
    end

    local resourceId = self:GetLinkedResource(entity)

    if ( resourceId == "" ) then
        return ""
    end

    for lowName in Iter( self.selectedBluprintsNames ) do

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

    local parameterName = "$selected_" .. lowName .. "_blueprint"

    local selectorDB = EntityService:GetDatabase( self.selector )

    local blueprintName = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        blueprintName = selectorDB:GetStringOrDefault(parameterName, "") or ""
    end

    if ( blueprintName == "" ) then
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
            blueprintName = campaignDatabase:GetStringOrDefault(parameterName, "") or ""
        end
    end

    if ( blueprintName == "" ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return self:GetMaxAvailableLevel( defaultBlueprintName )
    end

    return blueprintName
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