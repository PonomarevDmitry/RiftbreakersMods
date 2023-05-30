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

    return selectedItems
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

        return true
    end

    local isRuins = function ( entity )

        if( EntityService:GetGroup( entity ) == "##ruins##" ) then

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

    local blueprintName = EntityService:GetBlueprintName(entity)

    local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )

    local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

    if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then

        local resourceId = resourceVolumeComponentRef.type.resource.id

        if ( EntityService:CompareType( entity, "water" ) ) then

            local lowName = "liquid_pump"
            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
        else

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

    local blueprintName = selectorDB:GetStringOrDefault( parameterName, defaultBlueprintName ) or defaultBlueprintName

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultBlueprintName
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultBlueprintName
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return defaultBlueprintName
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultBlueprintName
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return defaultBlueprintName
    end

    return blueprintName
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