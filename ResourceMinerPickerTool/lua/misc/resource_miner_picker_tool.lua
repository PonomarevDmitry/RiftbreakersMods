local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'resource_miner_picker_tool' ( tool )

function resource_miner_picker_tool:__init()
    tool.__init(self,self)
end

function resource_miner_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function resource_miner_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_resource_miner_picker_tool", self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.selectedResourceComponents = {}

    self:FillSelectedBlueprints()
end

function resource_miner_picker_tool:FillSelectedBlueprints()

    self.selectedBluprintsNames = {

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "liquid_pump",

        "geothermal_powerplant",
    }

    local isCampaignBiome = MissionService:IsCampaignBiome()

    if ( isCampaignBiome ) then
        self:AddCampaignEntities( self.selectedBluprintsNames )
        self:AddSurvivalEntities( self.selectedBluprintsNames )
    else
        self:AddSurvivalEntities( self.selectedBluprintsNames )
        self:AddCampaignEntities( self.selectedBluprintsNames )
    end

    self.selectedBluprintsHash = {

        ["carbonium_factory"] = "buildings/resources/carbonium_factory",
        ["steel_factory"] = "buildings/resources/steel_factory",
        ["rare_element_mine"] = "buildings/resources/rare_element_mine",

        ["liquid_pump"] = "buildings/resources/liquid_pump",

        ["geothermal_powerplant"] = "buildings/energy/geothermal_powerplant",

        ["acid_refinery"] = "buildings/resources/acid_refinery",
        ["magma_lifter"] = "buildings/resources/magma_lifter",
        ["supercoolant_siphon"] = "buildings/resources/supercoolant_siphon",

        ["survival_acid_refinery"] = "buildings/resources/survival_acid_refinery",
        ["survival_magma_lifter"] = "buildings/resources/survival_magma_lifter",
        ["survival_supercoolant_siphon"] = "buildings/resources/survival_supercoolant_siphon",
    }
end

function resource_miner_picker_tool:AddCampaignEntities( list )

    Insert( list, "acid_refinery" )
    Insert( list, "magma_lifter" )
    Insert( list, "supercoolant_siphon" )
end

function resource_miner_picker_tool:AddSurvivalEntities( list )

    Insert( list, "survival_acid_refinery" )
    Insert( list, "survival_magma_lifter" )
    Insert( list, "survival_supercoolant_siphon" )
end

function resource_miner_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function resource_miner_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function resource_miner_picker_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = {}

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local min = VectorSub(selectorPosition, VectorMulByNumber(self.boundsSize , self.currentScale))
    local max = VectorAdd(selectorPosition, VectorMulByNumber(self.boundsSize , self.currentScale))

    local predicate = {

        signature="ResourceVolumeComponent"
    };

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
            goto continue
        end

        Insert( possibleSelectedEnts, entity )

        ::continue::
    end

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b)
        return sorter(possibleSelectedEnts, a, b)
    end)

    return possibleSelectedEnts
end

function resource_miner_picker_tool:AddedToSelection( entity )

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
end

function resource_miner_picker_tool:RemovedFromSelection( entity )

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
end

function resource_miner_picker_tool:OnRotate()
end

function resource_miner_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local entityBlueprintName = EntityService:GetBlueprintName(entity)

        local blueprintName = self:GetMineBlueprintName( entity )

        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseDesc= BuildingService:FindBaseBuilding( blueprintName )
        if  (baseDesc ~= nil ) then
            buildingDesc = baseDesc
        end

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
        if ( #list == 0 ) then
            goto continue
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

        do
            return
        end

        ::continue::
    end
end

function resource_miner_picker_tool:GetMineBlueprintName( entity )

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

function resource_miner_picker_tool:IsResourceRequired( resourceRequirement, resourceId )

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

function resource_miner_picker_tool:GetSelectorBlueprintName( lowName, defaultBlueprintName )

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

    if ( not BuildingService:IsBuildingAvailable( blueprintName ) ) then
        return defaultBlueprintName
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return defaultBlueprintName
    end

    return blueprintName
end

function resource_miner_picker_tool:OnRelease()

    if ( self.selectedResourceComponents ~= nil) then

        for childResource in Iter( self.selectedResourceComponents ) do
            QueueEvent( "DeselectEntityRequest", childResource )
        end
    end
    self.selectedResourceComponents = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return resource_miner_picker_tool