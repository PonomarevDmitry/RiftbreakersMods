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

    self:SpawnGhostWallEntity()

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent" ))

    local floorRef = reflection_helper(BuildingService:GetBuildingDesc( buildingComponent.bp ))

    self.floorBlueprintName = floorRef.ghost_bp

    self.linesEntities = {}
    self.floorEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    self.positionPlayerMarker = nil

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsCount = "$thorns_walls_count"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

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
        EntityService:SetPosition( self.currentMarkerLines, 0, 0, -2 )

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

                self:RemoveUselessComponents(lineEnt)

                Insert( self.linesEntities, lineEnt )
            end
        end

        for i=1,#newPositions do
            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = newPositions[i]

            local lineEnt = self.linesEntities[i]
            EntityService:SetPosition( lineEnt, newPositions[i])
            EntityService:SetOrientation(lineEnt, transform.orientation )

            self:RemoveUselessComponents(lineEnt)

            local testBuildable = self:CheckEntityBuildable(lineEnt, transform, i)

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end

            BuildingService:CheckAndFixBuildingConnection(lineEnt)
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

                self:RemoveUselessComponents(lineEnt)

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

            self:RemoveUselessComponents(entity)

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


    local pathDistanceArray = self:GetPathDistanceArray(pathFromStartPositionToEndPosition)


    local deltaXZ = 2

    local startSignVector = self:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

    local vectorArray = self:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)



    local hashMerge = {}

    local arrayWallVectors = {}


    --LogService:Log("Start Original #pathFromStartPositionToEndPosition " .. tostring(#pathFromStartPositionToEndPosition) .. " wallLinesCount " .. tostring(wallLinesCount) )

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        local signVector = vectorArray[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        local positionDistance = pathDistanceArray[i]

        local hasWall = ( positionDistance % 2 ) == 0

        self:AddHashMerge( hashMerge, position.x, position.z, hasWall, signVector )

        local wallVector = {}
        wallVector.position = position
        wallVector.isOuterCorner = false
        wallVector.hasWall = hasWall

        if ( hasChangesX and hasChangesZ ) then

            local cornerX, cornerZ = self:GetCornerVector(pathFromStartPositionToEndPosition, i)

            local cornerType = signVector.x * cornerX + signVector.z * cornerZ

            if (cornerType > 0) then

                wallVector.isOuterCorner = true

                wallVector.vector = {}
                wallVector.vector.x = cornerX
                wallVector.vector.z = cornerZ

                Insert(arrayWallVectors, wallVector)
            end
        else
            wallVector.vector = signVector

            Insert(arrayWallVectors, wallVector)
        end

        --LogService:Log("    i " .. tostring(i) .. " wallVector position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z) .. " isOuterCorner " .. tostring(wallVector.isOuterCorner) .. " hasWall " .. tostring(hasWall))
    end

    --LogService:Log("End Original #pathFromStartPositionToEndPosition " .. tostring(#pathFromStartPositionToEndPosition) .. " wallLinesCount " .. tostring(wallLinesCount) )

    for step=2,wallLinesCount do

        local hashPositions = {}

        --LogService:Log("Start step " .. tostring(step) .. " #arrayWallVectors " .. tostring(#arrayWallVectors) .. " wallLinesCount " .. tostring(wallLinesCount) )

        if ( #arrayWallVectors == 0 ) then
            goto endCalculation
        end

        local newArrayWallVectors = {}

        for i=1,#arrayWallVectors do

            local wallVector = arrayWallVectors[i]

            local position = wallVector.position

            local signVector = wallVector.vector

            local hasWall = wallVector.hasWall

            --LogService:Log("    i " .. tostring(i) .. " wallVector position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z) .. " isOuterCorner " .. tostring(wallVector.isOuterCorner) .. " hasWall " .. tostring(hasWall))

            local newPositionX = position.x + signVector.x * deltaXZ
            local newPositionZ = position.z + signVector.z * deltaXZ

            if ( wallVector.isOuterCorner ) then

                self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, position.x, position.y, newPositionZ, false, 0, signVector.z, hasWall)

                self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, position.y, position.z, false, signVector.x, 0, hasWall)

                hasWall = not hasWall
            end

            self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, position.y, newPositionZ, wallVector.isOuterCorner, signVector.x, signVector.z, hasWall)
        end

        --LogService:Log("End step " .. tostring(step) )



        local filteredArrayNewVectors = {}
        local hashFilteredArrayNewVectors = {}

        --LogService:Log("Start filter #newArrayWallVectors " .. tostring(#newArrayWallVectors) .. " step " .. tostring(step))

        for i=1,#newArrayWallVectors do

            local wallVector = newArrayWallVectors[i]

            local position = wallVector.position

            local signVector = wallVector.vector

            self:AddHashMerge( hashMerge, position.x, position.z, wallVector.hasWall, signVector )

            local cellConfig = hashPositions[position.x][position.z]

            local canContinueWallVector = self:CanContitue(cellConfig)

            --LogService:Log("    i " .. tostring(i) .. " wallVector position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z) .. " hasWall " .. tostring(wallVector.hasWall) .. " canContinueWallVector " .. tostring(canContinueWallVector))

            if ( canContinueWallVector and self:AddToHash(hashFilteredArrayNewVectors, position.x, position.z ) ) then

                Insert(filteredArrayNewVectors, wallVector)
            end
        end

        for i=1,#filteredArrayNewVectors do

            local wallVector = filteredArrayNewVectors[i]

            local position = wallVector.position

            local signVector = wallVector.vector

            local hasWall = ( hashMerge[position.x] ~= nil and hashMerge[position.x][position.z] ~= nil and hashMerge[position.x][position.z].hasWall == true )

            if ( hasWall ) then

                if ( wallVector.isOuterCorner ) then

                    local vector1 = {}
                    vector1.x = signVector.x
                    vector1.z = 0

                    local vector2 = {}
                    vector2.x = 0
                    vector2.z = signVector.z

                    self:FillPreviousGaps(hashMerge, position, vector1)
                    self:FillPreviousGaps(hashMerge, position, vector2)
                else

                    self:FillPreviousGaps(hashMerge, position, signVector, step)
                end
            end
        end

        --LogService:Log("End filter #filteredArrayNewVectors " .. tostring(#filteredArrayNewVectors) .. " step " .. tostring(step) )

        arrayWallVectors = filteredArrayNewVectors
    end

    ::endCalculation::





    local positionsArrayOrder = self:GetWallPositionInOrder(pathFromStartPositionToEndPosition, vectorArray, wallLinesCount)

    local result = {}

    for position in Iter(positionsArrayOrder) do

        local hasWall = ( hashMerge[position.x] ~= nil and hashMerge[position.x][position.z] ~= nil and hashMerge[position.x][position.z].hasWall == true )

        --LogService:Log("       Wall position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " hasWall " .. tostring(hasWall))

        if ( hasWall ) then

            table.insert(result, position)
        end
    end

    return result, pathFromStartPositionToEndPosition
end

function wall_thorns_tool:FillPreviousGaps(hashMerge, position, signVector)

    local deltaXZ = 2

    local previousX = position.x - signVector.x * deltaXZ
    local previousZ = position.z - signVector.z * deltaXZ

    local previous2X = position.x - 2 * signVector.x * deltaXZ
    local previous2Z = position.z - 2 * signVector.z * deltaXZ

    if ( hashMerge[previousX] ~= nil and hashMerge[previousX][previousZ] ~= nil and hashMerge[previous2X] ~= nil and hashMerge[previous2X][previous2Z] ~= nil ) then

        local previousHasWall = ( hashMerge[previousX][previousZ].hasWall == true )
        local previous2HasWall = ( hashMerge[previous2X][previous2Z].hasWall == true )

        if ( not previousHasWall and previous2HasWall ) then

            local cellConfig = hashMerge[previous2X][previous2Z]

            local fillPrevious = self:FillPrevious(cellConfig, signVector)

            if ( fillPrevious ) then

                --LogService:Log("    FillGaps" .. " previousX " .. tostring(previousX) .. " previousZ " .. tostring(previousZ) .. " previousHasWall " .. tostring(previousHasWall) .. " previous2X " .. tostring(previous2X) .. " previous2Z " .. tostring(previous2Z) .. " previous2HasWall " .. tostring(previous2HasWall) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z))

                hashMerge[previousX][previousZ].hasWall = true
            end
        end
    end
end

function wall_thorns_tool:FillPrevious(cellConfig, signVector)

    for i=1,#cellConfig.vectors do

        local vector = cellConfig.vectors[i]

        local scalarMul = vector.x * signVector.x + vector.z * signVector.z

        if ( scalarMul > 0 ) then

            return true
        end
    end

    return false
end

function wall_thorns_tool:CanContitue(cellConfig)

    if ( cellConfig.count == 1 ) then
        return true
    end

    for i=1,#cellConfig.vectors do

        local vector1 = cellConfig.vectors[i]

        for j=i+1,#cellConfig.vectors do

            local vector2 = cellConfig.vectors[i]

            if ( vector1.x ~= vector2.x or vector1.z ~= vector2.z ) then

                return false
            end
        end
    end

    return true
end

function wall_thorns_tool:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, positionY, newPositionZ, isOuterCorner, signVectorX, signVectorZ, hasWall)

    local isVisited = hashMerge[newPositionX] ~= nil and hashMerge[newPositionX][newPositionZ] ~= nil
    if ( isVisited ) then
        return
    end

    hashPositions[newPositionX] = hashPositions[newPositionX] or {}

    local hashXPosition = hashPositions[newPositionX]

    hashXPosition[newPositionZ] = hashXPosition[newPositionZ] or {}

    local cellConfig = hashXPosition[newPositionZ]

    cellConfig.count = cellConfig.count or 0

    cellConfig.count = cellConfig.count + 1

    cellConfig.vectors = cellConfig.vectors or {}

    local vector = {}
    vector.x = signVectorX
    vector.z = signVectorZ

    Insert(cellConfig.vectors, vector)

    local newWallVector = {}
    newWallVector.position = {}
    newWallVector.position.x = newPositionX
    newWallVector.position.y = positionY
    newWallVector.position.z = newPositionZ

    newWallVector.vector = vector

    newWallVector.isOuterCorner = isOuterCorner

    newWallVector.hasWall = hasWall

    Insert(newArrayWallVectors, newWallVector)
end

function wall_thorns_tool:GetWallPositionInOrder(pathFromStartPositionToEndPosition, vectorArray, wallLinesCount)

    local deltaXZ = 2

    local hashPositions = {}
    local positionsArray = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        local signVector = vectorArray[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        -- Add if position has not been added yet
        if ( self:AddToHash(hashPositions, position.x, position.z ) ) then

            table.insert(positionsArray, position)
        end

        -- Adding new positions for wall layers

        if ( hasChangesX and hasChangesZ ) then

            local cornerX, cornerZ = self:GetCornerVector(pathFromStartPositionToEndPosition, i)

            local cornerType = signVector.x * cornerX + signVector.z * cornerZ

            -- Outer Corner
            if (cornerType > 0) then

                for zStep=1,wallLinesCount do

                    local index = (zStep - 1)

                    local newPositionZ = position.z + cornerZ * index * deltaXZ

                    for xStep=1,zStep do

                        local newPositionX = position.x + cornerX * (xStep - 1) * deltaXZ

                        self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                    end
                end

                for xStep=1,wallLinesCount do

                    local index = (xStep - 1)

                    local newPositionX = position.x + cornerX * index * deltaXZ

                    for zStep=1,xStep do

                        local newPositionZ = position.z + cornerZ * (zStep - 1) * deltaXZ

                        self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                    end
                end
            end

        elseif ( hasChangesX ) then

            self:AddNewPositionsByConfigByZ(position, wallLinesCount, signVector.z, deltaXZ, hashPositions, positionsArray)

        elseif ( hasChangesZ ) then

            self:AddNewPositionsByConfigByX(position, wallLinesCount, signVector.x, deltaXZ, hashPositions, positionsArray)

        end
    end

    return positionsArray
end

function wall_thorns_tool:GetPathDistanceArray(pathFromStartPositionToEndPosition)

    local cornersArray = self:GetCornersArray(pathFromStartPositionToEndPosition)

    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local minDistance = self:GetMinDistance(i, cornersArray)

        result[i] = minDistance
    end

    return result
end

function wall_thorns_tool:GetMinDistance(number, cornersArray)

    if ( IndexOf( cornersArray, number ) ) then
        return 0
    end

    local currentCorner = nil
    local distance = number - 1

    for i=1,#cornersArray do

        local cornerNumber = cornersArray[i]

        local newDistance = math.abs(cornerNumber - number)

        if ( currentCorner == nil or newDistance < distance ) then
            currentCorner = cornerNumber
            distance = newDistance
        end
    end

    return distance
end

function wall_thorns_tool:GetCornersArray(pathFromStartPositionToEndPosition)

    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        if ( hasChangesX and hasChangesZ ) then

            table.insert(result, i)
        end
    end

    return result
end

function wall_thorns_tool:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)

    local signVector = {}
    signVector.x = startSignVector.x
    signVector.z = startSignVector.z

    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        result[i] = {}
        result[i].x = signVector.x
        result[i].z = signVector.z

        local position = pathFromStartPositionToEndPosition[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        -- Adding new positions for wall layers

        if ( hasChangesX and hasChangesZ ) then

            local degree = self:GetRotateDegree(pathFromStartPositionToEndPosition, i, 1)

            self:RotateVector(signVector, degree)
        end
    end

    return result
end

function wall_thorns_tool:RotateVector(signVector, degree)

    -- Identity matrix
    --   A B
    -- A 1 0
    -- B 0 1
    local coefAA = 1
    local coefAB = 0
    local coefBA = 0
    local coefBB = 1

    if ( degree > 0 ) then

        -- counter-clockwise matrix
        --    A B
        -- A  0 1
        -- B -1 0

        coefAA = 0
        coefAB = 1
        coefBA = -1
        coefBB = 0
    else

        -- clockwise matrix
        --   A  B
        -- A 0 -1
        -- B 1  0

        coefAA = 0
        coefAB = -1
        coefBA = 1
        coefBB = 0
    end

    local newSignVectorX = signVector.x * coefAA + signVector.z * coefBA
    local newSignVectorZ = signVector.x * coefAB + signVector.z * coefBB

    signVector.x = newSignVectorX
    signVector.z = newSignVectorZ
end

function wall_thorns_tool:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

    local startPosition = pathFromStartPositionToEndPosition[1]

    local startPositionHasChangesX, startPositionHasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, startPosition, 1)

    local result = {}
    result.x = 0
    result.z = 0

    if ( startPositionHasChangesX ) then

        result.z = 1

    elseif ( startPositionHasChangesZ ) then

        result.x = 1
    end

    -- Copy Vector
    local signVector = {}
    signVector.x = result.x
    signVector.z = result.z



    local nearestPositionNumber = self:GetNearestPosition(pathFromStartPositionToEndPosition, positionPlayer)

    -- Rotate vector to nearest Position
    for i=1,nearestPositionNumber do

        local position = pathFromStartPositionToEndPosition[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        if ( hasChangesX and hasChangesZ ) then

            local degree = self:GetRotateDegree(pathFromStartPositionToEndPosition, i, 1)

            self:RotateVector(signVector, degree)
        end
    end

    local nearestPosition = pathFromStartPositionToEndPosition[nearestPositionNumber]

    local nearestPositionXSign, nearestPositionZSign = self:GetXZSigns(nearestPosition, positionPlayer)

    local coef = nearestPositionXSign * signVector.x + nearestPositionZSign * signVector.z

    -- Invert base vector
    if ( coef < 0 ) then

        result.x = -result.x
        result.z = -result.z
    end

    return result
end

function wall_thorns_tool:GetNearestPosition(pathFromStartPositionToEndPosition, positionPlayer)

    local resultNumber = 1
    local resultDistance = self:SquareDistance( positionPlayer, pathFromStartPositionToEndPosition[1] )

    for i=2,#pathFromStartPositionToEndPosition do

        local distance = self:SquareDistance( positionPlayer, pathFromStartPositionToEndPosition[i] )

        if ( distance < resultDistance ) then

            resultNumber = i
            resultDistance = distance

        elseif ( distance == resultDistance ) then

            if ( resultNumber == 1) then

                resultNumber = i
                resultDistance = distance
            end
        end
    end

    return resultNumber
end

function wall_thorns_tool:SquareDistance( vector1, vector2 )

    local vector = {}

    vector.x = (vector2.x - vector1.x)
    vector.y = (vector2.y - vector1.y)
    vector.z = (vector2.z - vector1.z)

    return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z
end

function wall_thorns_tool:GetRotateDegree(pathFromStartPositionToEndPosition, cornerPositionNumber, direction)

    direction = direction or 1

    if ( (cornerPositionNumber > 1) and (cornerPositionNumber+1) <= #pathFromStartPositionToEndPosition ) then

        local position = pathFromStartPositionToEndPosition[cornerPositionNumber]

        local positionPrevious = pathFromStartPositionToEndPosition[cornerPositionNumber - direction]

        local positionNext = pathFromStartPositionToEndPosition[cornerPositionNumber + direction]

        local first = {}
        first.x = position.x - positionPrevious.x
        first.z = position.z - positionPrevious.z

        local second = {}
        second.x = positionNext.x - position.x
        second.z = positionNext.z - position.z

        local value = first.x * second.z - first.z * second.x

        if ( value > 0 ) then
            return 90
        else
            return -90
        end
    end

    return 0
end

function wall_thorns_tool:AddHashMerge(hashMerge, newPositionX, newPositionZ, hasWall, signVector)

    hashMerge[newPositionX] = hashMerge[newPositionX] or {}

    local hashXPosition = hashMerge[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        hashXPosition[newPositionZ] = {}

        hashXPosition[newPositionZ].hasWall = hasWall

        hashXPosition[newPositionZ].vectors = {}
    end

    local cellConfig = hashXPosition[newPositionZ]

    cellConfig.hasWall = cellConfig.hasWall and hasWall

    Insert( cellConfig.vectors, signVector )
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

function wall_thorns_tool:AddNewPositionsByConfigByX(position, wallLinesCount, xSign, deltaXZ, hashPositions, positionsArray)

    for index=0,wallLinesCount-1 do

        local newPositionX = position.x + xSign * index * deltaXZ

        self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, position.z, position.y)
    end
end

function wall_thorns_tool:AddNewPositionsByConfigByZ(position, wallLinesCount, zSign, deltaXZ, hashPositions, positionsArray)

    for index=0,wallLinesCount-1 do

        local newPositionZ = position.z + zSign * index * deltaXZ

        self:AddNewPositionToPositionsArray(hashPositions, positionsArray, position.x, newPositionZ, position.y)
    end
end

function wall_thorns_tool:AddNewPositionToPositionsArray(hashPositions, result, newPositionX, newPositionZ, newPositionY)

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

        self:DestroyPositionPlayerMarker()

        self.positionPlayerMarker = EntityService:SpawnEntity( "effects/multilayeredwalls_markers/objective_marker", self.positionPlayer, EntityService:GetTeam(self.entity) )


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

        local ghostEntity = self.linesEntities[i]
        local createCube = ((i == 1) or (i == count) or (i % step == 0))

        local transform = EntityService:GetWorldTransform( ghostEntity )
        if ( self.randomRotation == 1 ) then
            transform.orientation = self.randomOrientationArray[RandInt(1,4)]
        end
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghostEntity, "BuildingComponent"))

        local testBuildable = self:CheckEntityBuildable( ghostEntity, transform, i )

        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

        elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

            QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
        end

        EntityService:RemoveEntity(ghostEntity)
    end

    self:SpawnGhostWallEntity()

    self.linesEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil

    self:DestroyPositionPlayerMarker()
end

function wall_thorns_tool:DestroyPositionPlayerMarker()

    if ( self.positionPlayerMarker ~= nil ) then
        EntityService:RemoveEntity( self.positionPlayerMarker )
        self.positionPlayerMarker = nil
    end
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
    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameWallsCount, newValue)

    self:OnUpdate()
end

function wall_thorns_tool:OnRelease()

    for ghostEntity in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghostEntity)
    end
    self.linesEntities = {}

    self:ClearFloorEntities()

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    self:DestroyPositionPlayerMarker()

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_thorns_tool