local portal_base_tool = require("lua/misc/portal_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'portal_builder_tool' ( portal_base_tool )

function portal_builder_tool:__init()
    portal_base_tool.__init(self,self)
end

function portal_builder_tool:OnInit()

    local selectorDB = EntityService:GetDatabase( self.selector )

    EntityService:SetVisible( self.entity, false )
    EntityService:SetScale( self.entity, 2, 1, 2 )

    self.linesEntities = {}

    self.configNameDirection = "$portal_builder_tool_size"

    self.currentDirection = selectorDB:GetIntOrDefault(self.configNameDirection, self.defaultRadius)
    self.currentDirection = self:CheckSizeExists(self.currentDirection)

    self.currentMarker = nil
    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    self:SpawnGhostConnectorEntities()
end

function portal_builder_tool:GetConfigArray()

    if ( self.configArray == nil ) then

        self.configArray = { }

        for i=1,self.radius do

            Insert( self.configArray, i )
            Insert( self.configArray, -i )
        end
    end

    return self.configArray
end

function portal_builder_tool:CheckSizeExists( currentDirection )

    if ( currentDirection == nil ) then
        return self.defaultRadius
    end

    if ( currentDirection == 0 ) then
        return self.defaultRadius
    end

    local configArray = self:GetConfigArray()


    local index = IndexOf( configArray, currentDirection )
    if ( index == nil ) then

        return self.defaultRadius
    end

    return currentDirection
end

function portal_builder_tool:SpawnGhostConnectorEntities()

    local currentDirection = self:CheckSizeExists(self.currentDirection)

    local createChain = ( currentDirection < 0 or self.type == 0 )
    currentDirection = math.abs(currentDirection)

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local orientation = currentTransform.orientation

    local newPositions = self:FindPositionsToBuildLine( currentDirection )

    if ( #self.linesEntities > #newPositions ) then

        for i=#self.linesEntities,#newPositions + 1,-1 do
            local lineEnt = self.linesEntities[i]
            EntityService:RemoveEntity(lineEnt)
            self.linesEntities[i] = nil
        end

    elseif ( #self.linesEntities < #newPositions ) then

        for i=#self.linesEntities + 1 ,#newPositions do

            local lineEnt = self:SpawnGhostConnectorEntity(newPositions[i], orientation)

            Insert( self.linesEntities, lineEnt )
        end
    end

    Assert(#self.linesEntities == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#self.linesEntities) .. "/" .. tostring(#newPositions))

    for i=1,#newPositions do

        local transform = {}

        transform.scale = {x=1,y=1,z=1}
        transform.orientation = orientation
        transform.position = newPositions[i]

        local lineEnt = self.linesEntities[i]

        EntityService:SetPosition( lineEnt, newPositions[i])
        EntityService:SetOrientation( lineEnt, orientation )
    end

    self.buildCost = {}

    local list = BuildingService:GetBuildCosts( self.connectorBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end

    self:UpdateMarker(currentDirection, createChain)
end

function portal_builder_tool:FindPositionsToBuildLine(currentDirection)

    currentDirection = math.abs(currentDirection)

    if ( self.type == 1 ) then

        return self:FindPositionsType1(currentDirection)

    elseif ( self.type == 2 ) then

        return self:FindPositionsType2(currentDirection)

    elseif ( self.type == 3 ) then

        return self:FindPositionsType3(currentDirection)
    end

    local result = {}

    local newPosition = nil

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    return result
end

function portal_builder_tool:FindPositionsType1(currentDirection)

    local result = {}

    local delta = currentDirection * 2

    local newPosition = nil

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = - delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = - delta

    Insert( result, newPosition )

    return result
end

function portal_builder_tool:FindPositionsType2(currentDirection)

    local result = {}

    local delta = currentDirection * 2

    local newPosition = nil

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = - delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = 0

    Insert( result, newPosition )

    return result
end

function portal_builder_tool:FindPositionsType3(currentDirection)

    local result = {}

    local delta = currentDirection * 2

    for indexX = 0,1 do
        for indexZ = 0,1 do

            local maxIndex = math.max(indexX, indexZ)
            local totalIndex = indexX + indexZ

            local newPosition = nil

            newPosition = {}
            newPosition.y = 0
            newPosition.x = indexX * delta
            newPosition.z = indexZ * delta

            newPosition.maxIndex = maxIndex
            newPosition.totalIndex = totalIndex

            Insert( result, newPosition )

            if ( indexZ ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = indexX * delta
                newPosition.z = - indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end

            if ( indexX ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = - indexX * delta
                newPosition.z = indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end

            if ( indexX ~= 0 and indexZ ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = - indexX * delta
                newPosition.z = - indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end
        end
    end

    local sorter = function( position1, position2 )

        if (position1.maxIndex ~= position2.maxIndex) then

            return position1.maxIndex < position2.maxIndex
        end

        if (position1.totalIndex ~= position2.totalIndex) then

            return position1.totalIndex < position2.totalIndex
        end

        if (position1.x ~= position2.x) then

            return position1.x < position2.x
        end

        return position1.z < position2.z
    end

    table.sort(result, sorter)

    return result
end

function portal_builder_tool:UpdateMarker(currentDirection)

    currentDirection = math.abs(currentDirection)

    if ( self.currentMarkerSize ~= currentDirection ) then

        self.currentMarkerSize = currentDirection

        local markerBlueprint = "misc/marker_selector_portal_builder_tool_radius_" .. tostring(currentDirection)

        if ( currentDirection > 16 ) then
            markerBlueprint = "misc/marker_selector_portal_builder_tool_radius_g16"
        end

        if ( self.currentMarkerBlueprint ~= markerBlueprint or self.currentMarker == nil ) then

            -- Destroy old marker
            if (self.currentMarker ~= nil) then

                EntityService:RemoveEntity(self.currentMarker)
                self.currentMarker = nil
            end

            self.currentMarkerBlueprint = markerBlueprint

            self.currentMarker = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )
            EntityService:SetPosition( self.currentMarker, 0, 0, -2 )
        end
    end
end

function portal_builder_tool:OnUpdate()

    for number=1,#self.linesEntities do

        local lineEnt = self.linesEntities[number]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, number )
    end



    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end



    if ( self.activated and self.buildTransform ~= nil ) then

        
    end
end

function portal_builder_tool:OnActivateSelectorRequest()

    self:FinishLineBuild()

    self.buildTransform = EntityService:GetWorldTransform( self.entity )
    self.activated = true
end

function portal_builder_tool:FinishLineBuild()

    local currentDirection = self:CheckSizeExists(self.currentDirection)

    local createChain = ( currentDirection < 0 or self.type == 0 )
    currentDirection = math.abs(currentDirection)

    if ( not createChain ) then

        self:BuildEnergyConnectorsFromGhosts()
        return
    end

    local buildingsTransformsArray = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        local resourceStorageComponent = EntityService:GetComponent( entity, "ResourceStorageComponent")
        if ( resourceStorageComponent == nil ) then
            goto continue
        end

        local resourceStorageRef = reflection_helper( resourceStorageComponent )
        if ( not self:HasDistributionRadius( resourceStorageRef ) ) then
            goto continue
        end

        local transform = EntityService:GetWorldTransform( entity )

        Insert( buildingsTransformsArray, transform )

        ::continue::
    end


    if ( #buildingsTransformsArray == 0 ) then

        self:BuildEnergyConnectorsFromGhosts()
        return
    end

    local selfTransform = EntityService:GetWorldTransform( self.entity )

    while ( #buildingsTransformsArray > 0 ) do

        local nearestSpotTransform = self:GetNearestSpot(selfTransform.position, buildingsTransformsArray)
        if ( nearestSpotTransform == nil ) then

            self:BuildEnergyConnectorsFromGhosts()
            return
        end

        Remove( buildingsTransformsArray, nearestSpotTransform )

        local spots = self:FindSpotsByDistance( nearestSpotTransform, selfTransform )

        if ( #spots > 0 ) then

            local newAdditionalVectors = self:FindPositionsToBuildLine( currentDirection )

            for spot in Iter( spots ) do

                for i=1,#newAdditionalVectors do

                    local newPosition = newAdditionalVectors[i]

                    local transform = {}
                    transform.scale = spot.scale
                    transform.orientation = spot.orientation

                    transform.position = {}
                    transform.position.x = spot.position.x + newPosition.x
                    transform.position.y = spot.position.y + newPosition.y
                    transform.position.z = spot.position.z + newPosition.z

                    local lineEnt = self.linesEntities[i]

                    self:BuildEntity(lineEnt, transform, true)
                end
            end

            self:BuildEnergyConnectorsFromGhosts()
            return
        end
    end
end

function portal_builder_tool:FindSpotsByDistance(startTransform, endTransform)

    local spots = BuildingService:FindSpotsByDistance( startTransform, endTransform, self.radius, self.connectorBlueprintName )

    if ( #spots == 0 ) then
        return spots
    end

    local result = self:GetBuildableSpotsArray(spots)

    return result
end

function portal_builder_tool:GetBuildableSpotsArray(spots)

    local result = {}

    for i = 1,#spots do
            
        local spot = spots[i]

        local correctedTransform = self:GetBuildableSpot(spot)

        if ( #result > 0 ) then

            local lastSpot = result[#result]

            local difference = math.max( math.abs(lastSpot.position.x - correctedTransform.position.x), math.abs(lastSpot.position.z - correctedTransform.position.z) )

            if ( difference > self.radius ) then

                local newPosition = {}
                newPosition.x = SnapValue( (correctedTransform.position.x + lastSpot.position.x) / 2, 2.0 )
                newPosition.y = spot.position.y
                newPosition.z = SnapValue( (correctedTransform.position.z + lastSpot.position.z) / 2, 2.0 )

                local transform = {}
                transform.scale = spot.scale
                transform.orientation = spot.orientation
                transform.position = newPosition

                local transform = self:GetBuildableSpot(transform)

                Insert( result, transform )
            end
        end

        Insert( result, correctedTransform )
    end

    return result
end

function portal_builder_tool:GetBuildableSpot(spot)

    if ( not self:IsTransformOccupied(spot) ) then

        return spot
    end

    local transform = {}
    transform.scale = spot.scale
    transform.orientation = spot.orientation

    for i=1,#self.correctionVectors do

        local correctionVector = self.correctionVectors[i]

        local newPosition = {}
        newPosition.x = spot.position.x + correctionVector.x
        newPosition.y = spot.position.y
        newPosition.z = spot.position.z + correctionVector.z

        transform.position = newPosition

        if ( not self:IsTransformOccupied(transform) ) then
                        
            return transform
        end
    end

    return spot
end

function portal_builder_tool:AddToHash(hashPositions, position)

    hashPositions[position.x] = hashPositions[position.x] or {}

    local hashXPosition = hashPositions[position.x]

    if ( hashXPosition[position.z] ~= nil ) then

        return false
    end

    hashXPosition[position.z] = true

    return true
end

function portal_builder_tool:HashContains(hashPositions, position)

    hashPositions[position.x] = hashPositions[position.x] or {}

    local hashXPosition = hashPositions[position.x]

    if ( hashXPosition[position.z] ~= nil ) then

        return true
    end

    return false
end

function portal_builder_tool:IsTransformOccupied(transform)

    local isSpaceOccupied = BuildingService:IsSpaceOccupied( transform.position, "", "" )
    if ( isSpaceOccupied ) then

        return true
    end

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(transform.position)

    local buildingBlockerLayerComponent = EntityService:GetComponent( terrainCellEntityId, "BuildingBlockerLayerComponent" )
    if ( buildingBlockerLayerComponent ~= nil ) then
        return true
    end

    local worldBlockerLayerComponent = EntityService:GetComponent( terrainCellEntityId, "WorldBlockerLayerComponent" )
    if ( worldBlockerLayerComponent ~= nil ) then
        return true
    end

    local testBuildable = self:CheckEntityBuildable( self.linesEntities[1], transform )
    if ( testBuildable == nil ) then

        return true
    end

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        return false
    end

    return true
end

function portal_builder_tool:BuildEnergyConnectorsFromGhosts()

    for i=1,#self.linesEntities do

        local ghostEntity = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( ghostEntity )

        self:BuildEntity(ghostEntity, transform, true)
    end
end

function portal_builder_tool:HasDistributionRadius( resourceStorageRef )

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

function portal_builder_tool:GetNearestSpot( entityPosition, buildingsTransformsArray )

    local currentSpot = nil
    local currentDistance = nil

    for spot in Iter( buildingsTransformsArray ) do

        local distance = Distance( entityPosition, spot.position )

        if currentSpot == nil or distance < currentDistance then

            currentSpot = spot;
            currentDistance = distance

            local lineDistance = self:GetDistance( entityPosition, spot.position )

            if ( lineDistance <= self.radius ) then

                return currentSpot
            end
        end
    end

    return currentSpot
end

function portal_builder_tool:GetDistance( position1, position2 )

    local dx = math.abs(position1.x - position2.x)
    local dz = math.abs(position1.z - position2.z)

    return math.max(dx, dz)
end

function portal_builder_tool:OnDeactivateSelectorRequest()

    self.buildTransform = nil
    self.activated = false
end

function portal_builder_tool:OnRotateSelectorRequest(evt)

    if ( self.type == 0 ) then
        return
    end

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentDirection = self:CheckSizeExists(self.currentDirection)

    local configArray = self:GetConfigArray()

    local index = IndexOf( configArray, currentDirection )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #configArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex < 1 ) then
        newIndex = 1
    end

    local newValue = configArray[newIndex]

    self.currentDirection = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameDirection, newValue)

    self:SpawnGhostConnectorEntities()
end

function portal_builder_tool:OnRelease()

    if ( self.linesEntities ~= nil) then
        for ghostEntity in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghostEntity)
        end
    end
    self.linesEntities = {}

    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    if (self.currentMarker ~= nil) then

        EntityService:RemoveEntity(self.currentMarker)
        self.currentMarker = nil
    end

    if ( portal_base_tool.OnRelease ) then
        portal_base_tool.OnRelease(self)
    end
end

return portal_builder_tool