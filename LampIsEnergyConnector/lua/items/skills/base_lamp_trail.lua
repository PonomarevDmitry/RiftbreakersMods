local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'base_lamp_trail' ( item )

function base_lamp_trail:__init()
    item.__init(self,self)
end

function base_lamp_trail:OnInit()

    if ( item.OnInit ) then
        item.OnInit(self)
    end

    self:FillInitialParams()
end

function base_lamp_trail:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    self:FillInitialParams()
end

function base_lamp_trail:FillInitialParams()

    self.buildPosition = self.buildPosition or {}

    self.isWorking = self.isWorking or false

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function base_lamp_trail:GetLampBlueprint()

    local blueprintDatabase = EntityService:GetBlueprintDatabase( self.entity )

    local defaultBlueprint = blueprintDatabase:GetString("defaultBlueprint")

    local parameterName = blueprintDatabase:GetString("parameterName")

    local blueprintName = ""


    local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

            blueprintName = globalPlayerEntityDB:GetStringOrDefault(parameterName, defaultBlueprint)
        end
    end


    if ( blueprintName == "" ) then

        local selector = PlayerService:GetPlayerSelector(self.playerId)
        if ( selector and selector ~= INVALID_ID ) then

            local selectorDB = EntityService:GetOrCreateDatabase( selector )
            if ( selectorDB and selectorDB:HasString(parameterName) ) then

                blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultBlueprint)
            end
        end
    end


    if ( blueprintName == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultBlueprint)
            end
        end
    end

    if ( blueprintName == "" ) then
        return defaultBlueprint
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultBlueprint
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultBlueprint
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultBlueprint
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return defaultBlueprint
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return defaultBlueprint
    end

    return blueprintName
end

function base_lamp_trail:FindMinDistance()

    --local lowName = BuildingService:FindLowUpgrade( blueprint )

    --LogService:Log("FindMinDistance " .. blueprint .. " " .. lowName )

    local blueprintName = self:GetLampBlueprint()

    self.radius = BuildingService:FindEnergyRadius( blueprintName )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max( bounds.x, bounds.z ) / 2.0
    end
end

function base_lamp_trail:FillPlayerId()

    self.playerId = 0

    if ( self.owner ~= nil and self.owner ~= INVALID_ID ) then

        local playerReferenceComponent = EntityService:GetComponent( self.owner, "PlayerReferenceComponent" )
        if ( playerReferenceComponent ) then

            local helper = reflection_helper(playerReferenceComponent)

            self.playerId = helper.player_id
        end
    end
end

function base_lamp_trail:OnActivate()

    if ( self.owner == nil or self.owner == INVALID_ID ) then

        return
    end

    self:FillPlayerId()

    self:FindMinDistance()

    self:InitStateMachine()

    self.isWorking = self.isWorking or false

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        if ( self.iconEntity ~= nil ) then
            EntityService:RemoveEntity(self.iconEntity)
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( self.entity )

        local skillIcon = blueprintDatabase:GetString("skill_icon")

        self.iconEntity = EntityService:SpawnAndAttachEntity( "items/skills/base_lamp_trail/icon", self.owner )

        local database = EntityService:GetOrCreateDatabase( self.iconEntity )
        database:SetString("skill_icon", skillIcon)

        self:FillConnectorsList()

        if ( #self.buildPosition == 0 ) then

            local blueprintName = self:GetLampBlueprint()

            local transform = self:GetPlayerTransform()

            self:BuildOnSpot( blueprintName, transform )
        end

        self:OnWorkExecute()

        self.stateMachine:ChangeState("working")
    end
end

function base_lamp_trail:GetPlayerTransform()

    local transform = EntityService:GetWorldTransform( self.owner )
    transform.orientation = { x=0, y=1, z=0, w=0 }

    return transform
end

function base_lamp_trail:FillConnectorsList()

    self.buildPosition = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        local selectableComponent = EntityService:GetConstComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then
            goto continue
        end

        local resourceStorageComponent = EntityService:GetComponent( entity, "ResourceStorageComponent")
        if ( resourceStorageComponent == nil ) then
            goto continue
        end

        local resourceStorageRef = reflection_helper( resourceStorageComponent )
        if ( not self:HasDistributionRadius( resourceStorageRef ) ) then
            goto continue
        end

        --local blueprintName = EntityService:GetBlueprintName( entity )

        --LogService:Log("FillConnectorsList blueprintName " .. blueprintName .. " " .. tostring(resourceStorageRef) )

        local transform = EntityService:GetWorldTransform( entity )

        Insert( self.buildPosition, transform )

        ::continue::
    end

    --LogService:Log("FillConnectorsList #self.buildPosition " .. tostring(#self.buildPosition) )
end

function base_lamp_trail:HasDistributionRadius( resourceStorageRef )

    if ( resourceStorageRef ~= nil and resourceStorageRef.Storages ~= nil ) then

        local count = resourceStorageRef.Storages.count

        for i=1,count do

            local storage = resourceStorageRef.Storages[i]

            if ( tostring(storage.group) == "12" and storage.distribution_radius >= 1 ) then

                if ( storage.resource and storage.resource.resource and storage.resource.resource.id and storage.resource.resource.id == "energy" ) then

                    return true
                end
            end
        end
    end

    return false
end

function base_lamp_trail:OnUnequipped()
    if ( self.isWorking ) then

        self:StopWorking()
    end
end

function base_lamp_trail:StopWorking()

    self.isWorking = false

    self.stateMachine:Deactivate()

    self.buildPosition = {}

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function base_lamp_trail:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function base_lamp_trail:InitStateMachine()

    if ( self.stateMachine ~= nil ) then
        return
    end

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
end

function base_lamp_trail:OnWorkExecute()

    if ( #self.buildPosition == 0 ) then

        return
    end

    local transform = self:GetPlayerTransform()

    local nearestSpot = self:GetNearestSpot(transform.position)

    local blueprintName = self:GetLampBlueprint()

    local spots = BuildingService:FindSpotsByDistance( nearestSpot, transform, self.radius, blueprintName )

    for spot in Iter( spots ) do

        self:BuildOnSpot( blueprintName, spot )
    end
end

function base_lamp_trail:BuildOnSpot( blueprintName, spot )

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"

    if ( BuildingService:IsBuildingAvailable( self.playerId, antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then

        local buildDesertFloor = self:ShouldBuildDesertFloor( spot.position )

        if ( buildDesertFloor ) then

            local transformFloor = {}
            transformFloor.position = spot.position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=1, y=1, z=1}

            QueueEvent("BuildFloorRequest", INVALID_ID, self.playerId, antiQuickSandFloor, transformFloor )
        end
    end

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) and BuildingService:CanAffordBuilding( blueprintName, self.playerId) ) then

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, spot, true, {} )

        Insert( self.buildPosition, spot )
    end
end

function base_lamp_trail:ShouldBuildDesertFloor( position )

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

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        return true
    end

    return false
end

function base_lamp_trail:GetNearestSpot( playerPosition )

    local currentSpot = nil
    local currentDistance = nil

    for spot in Iter( self.buildPosition ) do

        local distance = Distance( playerPosition, spot.position )

        if currentSpot == nil or distance < currentDistance then

            currentSpot = spot;
            currentDistance = distance

            local lineDistance = self:GetDistance( playerPosition, spot.position )

            if ( lineDistance <= self.radius ) then

                return currentSpot
            end
        end
    end

    return currentSpot
end

function base_lamp_trail:GetDistance( playerPosition, position )

    local dx = math.abs(playerPosition.x - position.x)
    local dz = math.abs(playerPosition.z - position.z)

    return math.max(dx, dz)
end

return base_lamp_trail