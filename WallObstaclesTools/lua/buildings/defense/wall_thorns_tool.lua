local wall_base_tool = require("lua/buildings/defense/wall_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_thorns_tool' ( wall_base_tool )

function wall_thorns_tool:__init()
    wall_base_tool.__init(self,self)
end

function wall_thorns_tool:OnInit()

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent" ))

    local floorRef = reflection_helper(BuildingService:GetBuildingDesc( buildingComponent.bp ))

    self.floorBlueprintName = floorRef.ghost_bp

    self.linesEntities = {}
    self.floorEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsCount = "$thorns_walls_count"

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Wall layers config
    self.wallLinesCount = selectorDB:GetIntOrDefault(self.configNameWallsCount, 2)
    self.wallLinesCount = self:CheckConfigExists(self.wallLinesCount)
end

function wall_thorns_tool:OnUpdate()

    self.buildCost = {}

    -- Wall layers config
    local wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    -- Correct Marker to show right number of wall layers
    if ( self.markerLinesConfig ~= wallLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local markerBlueprint = "misc/marker_selector_thorns_walls_" .. tostring( wallLinesCount )

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )

        -- Save number of wall layers
        self.markerLinesConfig = wallLinesCount
    end

    self:RemoveMaterialFromOldBuildingsToSell()

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local newPositions, pathFromStartPositionToEndPosition = self:FindPositionsToBuildLine( currentTransform, wallLinesCount )

        if ( #self.linesEntities > #newPositions ) then

            for i=#self.linesEntities,#newPositions + 1,-1 do
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end

        elseif ( #self.linesEntities < #newPositions ) then

            for i=#self.linesEntities + 1 ,#newPositions do

                local lineEnt = EntityService:SpawnEntity( self.ghostBlueprintName, newPositions[i], team )
                EntityService:RemoveComponent( lineEnt, "LuaComponent" )
                Insert( self.linesEntities, lineEnt )
            end
        end

        for i=1,#newPositions do
            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = newPositions[i]

            local entity = self.linesEntities[i]
            EntityService:SetPosition( entity, newPositions[i])
            EntityService:SetOrientation(entity, transform.orientation )

            local testBuildable = self:CheckEntityBuildable(entity, transform, i)

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end

            BuildingService:CheckAndFixBuildingConnection(entity)
        end

        local list = BuildingService:GetBuildCosts( self.wallBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #newPositions )
        end




        if ( #self.floorEntities > #pathFromStartPositionToEndPosition ) then

            for i=#self.floorEntities,#pathFromStartPositionToEndPosition + 1,-1 do
                EntityService:RemoveEntity(self.floorEntities[i])
                self.floorEntities[i] = nil
            end

        elseif ( #self.floorEntities < #pathFromStartPositionToEndPosition ) then

            for i=#self.floorEntities + 1 ,#pathFromStartPositionToEndPosition do

                local lineEnt = EntityService:SpawnEntity( self.floorBlueprintName, pathFromStartPositionToEndPosition[i], team )
                EntityService:RemoveComponent( lineEnt, "LuaComponent" )
                EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )

                Insert( self.floorEntities, lineEnt )
            end
        end

        for i=1,#pathFromStartPositionToEndPosition do

            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = pathFromStartPositionToEndPosition[i]

            local entity = self.floorEntities[i]

            EntityService:ChangeMaterial( entity, "selector/hologram_blue" )
            EntityService:SetPosition( entity, pathFromStartPositionToEndPosition[i] )
            EntityService:SetOrientation( entity, transform.orientation )
        end


    else
        if ( self.ghostWall ~= nil ) then
            local transform = EntityService:GetWorldTransform( self.ghostWall )
            local testBuildable = self:CheckEntityBuildable( self.ghostWall, transform )

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end
        end
    end



    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function wall_thorns_tool:FindPositionsToBuildLine( currentTransform, wallLinesCount )

    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        positionPlayer = EntityService:GetPosition( player )
    end

    local pathFromStartPositionToEndPosition = BuildingService:FindPathByBlueprint( self.buildStartPosition, currentTransform, self.wallBlueprintName )


    local odds, cornerTileNumber = self:GetCorner(pathFromStartPositionToEndPosition)

    self.cornerVectorX = 0
    self.cornerVectorZ = 0
    self.cornerPositionX = 0
    self.cornerPositionZ = 0

    self.checkCollisionBox = false

    local cornerType = 0

    if ( cornerTileNumber ~= -1 ) then

        local cornerX, cornerZ = self:GetCornerVector(pathFromStartPositionToEndPosition, cornerTileNumber)

        local cornerPosition = pathFromStartPositionToEndPosition[cornerTileNumber]

        local cornerXSign, cornerZSign = self:GetXZSigns(cornerPosition, positionPlayer)

        cornerType = cornerXSign * cornerX + cornerZSign * cornerZ

        if ( cornerType == -2 ) then

            self.checkCollisionBox = true

            self.cornerPositionX = cornerPosition.x
            self.cornerPositionZ = cornerPosition.z
            self.cornerVectorX = cornerX
            self.cornerVectorZ = cornerZ

            local firstPosition = pathFromStartPositionToEndPosition[1]
            local lastPosition = pathFromStartPositionToEndPosition[#pathFromStartPositionToEndPosition]

            self:FillCollisionBoxBounds( cornerPosition, firstPosition, lastPosition )
        end
    end

    local deltaXZ = 2

    local hashPositions = {}
    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        if ( i % 2 == odds) then

            local position = pathFromStartPositionToEndPosition[i]

            local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

            local xSign, zSign = self:GetXZSigns(position, positionPlayer)

            -- Add if position has not been added yet
            if ( self:AddToHash(hashPositions, position.x, position.z ) ) then

                table.insert(result, position)
            end

            local currentValue = self:PositionResult(position.x, position.z)

            if ( hasChangesX ) then

                self:AddNewPositionsByConfigByZ(position, wallLinesCount, zSign, deltaXZ, currentValue, hashPositions, result)
            end

            if ( hasChangesZ ) then

                self:AddNewPositionsByConfigByX(position, wallLinesCount, xSign, deltaXZ, currentValue, hashPositions, result)
            end

            if ( i == cornerTileNumber ) then

                -- Outer Corner
                if (cornerType == 2) then

                    local xzDelta = 2

                    while (xzDelta <= wallLinesCount - 1) do

                        for zStep=0,(wallLinesCount - 1 - xzDelta) do

                            local newPositionX = position.x + xSign * xzDelta * 2
                            local newPositionZ = position.z + zSign * xzDelta * 2 + zSign * zStep * 2

                            self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
                        end

                        for xStep=0,(wallLinesCount - 1 - xzDelta) do

                            local newPositionX = position.x + xSign * xzDelta * 2 + xSign * xStep * 2
                            local newPositionZ = position.z + zSign * xzDelta * 2

                            self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
                        end

                        xzDelta = xzDelta + 2
                    end
                end
            end
        end
    end

    return result, pathFromStartPositionToEndPosition
end

function wall_thorns_tool:FillCollisionBoxBounds( cornerPosition, firstPosition, lastPosition )

    local widthX = math.max( math.abs( cornerPosition.x - lastPosition.x ), math.abs( cornerPosition.x - firstPosition.x ) )

    local widthZ = math.max( math.abs( cornerPosition.z - lastPosition.z ), math.abs( cornerPosition.z - firstPosition.z ) )

    local width = math.min( widthX, widthZ )

    local xPosition = cornerPosition.x - self.cornerVectorX * width;

    local collisionMinX = math.min( cornerPosition.x, xPosition )
    local collisionMaxX = math.max( cornerPosition.x, xPosition )

    self.collisionBoxMinX = collisionMinX
    self.collisionBoxMaxX = collisionMaxX

    local zPosition = cornerPosition.z - self.cornerVectorZ * width

    local collisionMinZ = math.min( cornerPosition.z, zPosition )
    local collisionMaxZ = math.max( cornerPosition.z, zPosition )

    self.collisionBoxMinZ = collisionMinZ
    self.collisionBoxMaxZ = collisionMaxZ

    local fullMinX = math.min( firstPosition.x, lastPosition.x )
    local fullMaxX = math.max( firstPosition.x, lastPosition.x )

    self.fullBoxMinX = fullMinX
    self.fullBoxMaxX = fullMaxX

    local fullMinZ = math.min( firstPosition.z, lastPosition.z )
    local fullMaxZ = math.max( firstPosition.z, lastPosition.z )

    self.fullBoxMinZ = fullMinZ
    self.fullBoxMaxZ = fullMaxZ
end

function wall_thorns_tool:PositionResult(positionX, positionZ)

    local result = (positionX - self.cornerPositionX) * self.cornerVectorZ - (positionZ - self.cornerPositionZ) * self.cornerVectorX

    if (result > 0) then

        return  1
    elseif result < 0 then

        return -1
    else

        return 0
    end
end

function wall_thorns_tool:GetXZSigns(position, positionPlayer)

    local xSign = 1
    local zSign = 1

    if( positionPlayer.x >= position.x ) then
        xSign = -1
    end

    if( positionPlayer.z >= position.z ) then
        zSign = -1
    end

    return xSign, zSign
end

function wall_thorns_tool:GetCorner(pathFromStartPositionToEndPosition)

    local odds = 1
    local cornerTileNumber = -1

    for i=1,#pathFromStartPositionToEndPosition do

        if ( (i > 1) and (i+1) <= #pathFromStartPositionToEndPosition ) then

            local position = pathFromStartPositionToEndPosition[i]

            local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

            if ( hasChangesX and hasChangesZ) then

                odds = i % 2
                cornerTileNumber = i
                break
            end
        end
    end

    return odds, cornerTileNumber
end

function wall_thorns_tool:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

    local hasChangesX = false
    local hasChangesZ = false

    if ( (i+1) <= #pathFromStartPositionToEndPosition ) then

        local positionNext = pathFromStartPositionToEndPosition[i+1]

        if ( position.x ~= positionNext.x ) then
            hasChangesX = true
        end

        if ( position.z ~= positionNext.z ) then
            hasChangesZ = true
        end
    end

    if ( i > 1 ) then

        local positionPrevious = pathFromStartPositionToEndPosition[i-1]

        if ( position.x ~= positionPrevious.x ) then
            hasChangesX = true
        end

        if ( position.z ~= positionPrevious.z ) then
            hasChangesZ = true
        end
    end

    return hasChangesX, hasChangesZ
end

function wall_thorns_tool:GetCornerVector(pathFromStartPositionToEndPosition, cornerPositionNumber)

    local cornerX = 0
    local cornerZ = 0

    if ( (cornerPositionNumber > 1) and (cornerPositionNumber+1) <= #pathFromStartPositionToEndPosition ) then

        local position = pathFromStartPositionToEndPosition[cornerPositionNumber]

        local positionPrevious = pathFromStartPositionToEndPosition[cornerPositionNumber-1]

        local positionNext = pathFromStartPositionToEndPosition[cornerPositionNumber+1]

        if ( positionPrevious.x < position.x ) then
            cornerX = 1
        end

        if ( positionPrevious.x > position.x ) then
            cornerX = -1
        end

        if ( positionPrevious.z < position.z ) then
            cornerZ = 1
        end

        if ( positionPrevious.z > position.z ) then
            cornerZ = -1
        end

        if ( position.x < positionNext.x ) then
            cornerX = -1
        end

        if ( position.x > positionNext.x ) then
            cornerX = 1
        end

        if ( position.z < positionNext.z ) then
            cornerZ = -1
        end

        if ( position.z > positionNext.z ) then
            cornerZ = 1
        end
    end

    return cornerX, cornerZ
end

function wall_thorns_tool:AddNewPositionsByConfigByX(position, wallLinesCount, xSign, deltaXZ, currentValue, hashPositions, result)

    for step=1,wallLinesCount do

        local newPositionX = position.x + xSign * (step - 1) * deltaXZ

        if ( self:PerformCheckCollisionBox( newPositionX, position.z, currentValue ) ) then

            self:AddNewPositionToResult(hashPositions, result, newPositionX, position.z, position.y)
        end
    end
end

function wall_thorns_tool:AddNewPositionsByConfigByZ(position, wallLinesCount, zSign, deltaXZ, currentValue, hashPositions, result)

    for step=1,wallLinesCount do

        local newPositionZ = position.z + zSign * (step - 1) * deltaXZ

        if ( self:PerformCheckCollisionBox( position.x, newPositionZ, currentValue ) ) then

            self:AddNewPositionToResult(hashPositions, result, position.x, newPositionZ, position.y)
        end
    end
end

function wall_thorns_tool:PerformCheckCollisionBox( newPositionX, newPositionZ, currentValue)

    if ( self.checkCollisionBox == false ) then

        return true
    end

    if ( (self.fullBoxMinX <= newPositionX and newPositionX <= self.fullBoxMaxX) and (self.fullBoxMinZ <= newPositionZ and newPositionZ <= self.fullBoxMaxZ) ) then

        local positionValue = self:PositionResult(newPositionX, newPositionZ)

        if ( positionValue == currentValue or positionValue == 0 ) then

            return true
        else

            return false
        end
    else

        if ( (self.collisionBoxMinX < newPositionX and newPositionX < self.collisionBoxMaxX) or newPositionX == self.cornerPositionX ) then

            return false
        end

        if ( (self.collisionBoxMinZ < newPositionZ and newPositionZ < self.collisionBoxMaxZ) or newPositionZ == self.cornerPositionZ ) then

            return false
        end

        return true
    end
end

function wall_thorns_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:AddToHash( hashPositions, newPositionX, newPositionZ ) ) then
        return
    end

    local newPosition = {}
    newPosition.x = newPositionX
    newPosition.y = newPositionY
    newPosition.z = newPositionZ

    table.insert(result, newPosition)
end

-- Check position has not already been added to hashPositions
function wall_thorns_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

    if ( hashPositions[newPositionX] == nil) then

        hashPositions[newPositionX] = {}
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] ~= nil ) then

        return false
    end

    hashXPosition[newPositionZ] = true

    return true
end

function wall_thorns_tool:CheckConfigExists( wallLinesCount )

    wallLinesCount = wallLinesCount or 2

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf( scaleWallLines, wallLinesCount )

    if ( index == nil ) then

        return scaleWallLines[1]
    end

    return wallLinesCount
end

function wall_thorns_tool:GetWallConfigArray()

    if ( self.scaleWallLines == nil ) then

        self.scaleWallLines = {
            2,
            3,
            4,
            5,
            6,
            8,
            10
        }
    end

    return self.scaleWallLines
end

function wall_thorns_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform

        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        self.positionPlayer = EntityService:GetPosition( player )


        self:DestroyGhostWall()

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function wall_thorns_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function wall_thorns_tool:FinishLineBuild()

    self:ClearFloorEntities()

    local count = #self.linesEntities
    local step = count

    if ( count > 5 ) then
        local additionalCubesCount = math.ceil( count / 5 )
        step = math.ceil( count / additionalCubesCount)
    end

    for i=1,count do

        local ghost = self.linesEntities[i]
        local createCube = i == 1 or i == count or i % step == 0

        local transform = EntityService:GetWorldTransform( ghost )
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghost, "BuildingComponent"))

        local testBuildable = self:CheckEntityBuildable( ghost, transform, i )

        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

        elseif( testBuildable.flag == CBF_REPAIR ) then
            QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
        end

        EntityService:RemoveEntity(ghost)
    end

    self:SpawnGhostWallEntity()

    self.linesEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function wall_thorns_tool:ClearFloorEntities()

    for floorGhost in Iter(self.floorEntities) do
        EntityService:RemoveEntity(floorGhost)
    end
    self.floorEntities = {}
end

function wall_thorns_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentLinesConfig = self:CheckConfigExists(self.wallLinesCount)

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf( scaleWallLines, currentLinesConfig )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #scaleWallLines

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = 1
    elseif( newIndex == 0 ) then
        newIndex = maxIndex
    end

    local newValue = scaleWallLines[newIndex]

    self.wallLinesCount = newValue

    -- Wall layers config
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameWallsCount, newValue)

    self:OnUpdate()
end

function wall_thorns_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}

    self:ClearFloorEntities()

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_thorns_tool