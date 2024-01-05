local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")

class 'ghost_building_line' ( ghost )

function ghost_building_line:__init()
    ghost.__init(self,self)
end

function ghost_building_line:OnInit()
    -- action line
    self.data:SetString("action", "line")

    self.linesEntities = {}

    --if ( self.data:GetInt("activated") == 1 ) then
    --    self.activated = true
    --    self.buildStartPosition = EntityService:GetWorldTransform( self.entity )
    --    self.buildStartPosition.position.x = self.data:GetFloat("activation_position_x")
    --    self.buildStartPosition.position.y = self.data:GetFloat("activation_position_y")
    --    self.buildStartPosition.position.z = self.data:GetFloat("activation_position_z")
    --    EntityService:SetVisible( self.entity, false )
    --
    --    local player = PlayerService:GetPlayerControlledEnt(self.playerId)
    --    self.positionPlayer = EntityService:GetPosition( player )
    --end

    self.positionPlayerMarker = nil

    self:CreateInfoChild()

    local typeName = ""
    local buildingDesc = BuildingService:GetBuildingDesc( self.blueprint )
    if( buildingDesc ~= nil ) then
        local buildingDescHelper = reflection_helper(buildingDesc)
        typeName = buildingDescHelper.type
    end

    -- Marker with number of wall layers
    self.markerLinesConfig = "0"
    self.currentMarkerLines = nil
    self.isWall = ( typeName == "wall" )
end

function ghost_building_line:CreateInfoChild()

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1 )
    end
end

function ghost_building_line:OnUpdate()
    self.buildCost = {}

    -- Multi layers only for wall, not pipes
    local wallLinesConfig = "1"

    if (self.isWall) then

        -- Wall layers config
        wallLinesConfig = self.data:GetStringOrDefault("wall_lines_config", "1")

        wallLinesConfig = self:CheckConfigExists(wallLinesConfig)

        -- Correct Marker to show right number of wall layers
        if ( self.markerLinesConfig ~= wallLinesConfig or self.currentMarkerLines == nil) then

            -- Destroy old marker
            if (self.currentMarkerLines ~= nil) then

                EntityService:RemoveEntity(self.currentMarkerLines)
                self.currentMarkerLines = nil
            end

            local markerBlueprint = "misc/marker_selector_wall_lines_" .. wallLinesConfig

            -- Create new marker
            self.currentMarkerLines = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

            EntityService:SetPosition( self.currentMarkerLines, -2, 0, 0 )

            -- Save number of wall layers
            self.markerLinesConfig = wallLinesConfig

        end
    end

    if ( self.buildStartPosition ) then

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local newPositions = self:FindPositionsToBuildLine( currentTransform, wallLinesConfig )

        local team = EntityService:GetTeam(self.entity)

        if ( #self.linesEntities > #newPositions ) then

            for i=#self.linesEntities,#newPositions + 1,-1 do
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end

        elseif ( #self.linesEntities < #newPositions ) then

            for i=#self.linesEntities + 1 ,#newPositions do

                local lineEnt = EntityService:SpawnEntity(self.ghostBlueprint, newPositions[i], team )
                if ( EntityService:HasComponent( lineEnt, "DisplayRadiusComponent" ) ) then
                    EntityService:RemoveComponent( lineEnt, "DisplayRadiusComponent" )
                end

                if ( EntityService:HasComponent( lineEnt, "GhostLineCreatorComponent" ) ) then
                    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )
                end
                EntityService:RemoveComponent(lineEnt, "LuaComponent")
                Insert(self.linesEntities, lineEnt)
            end
        end

        Assert(#self.linesEntities == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#self.linesEntities) .. "/" .. tostring(#newPositions))

        for i=1,#newPositions do
            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = newPositions[i]

            local entity = self.linesEntities[i]
            if ( EntityService:HasComponent( entity, "DisplayRadiusComponent" ) ) then
                EntityService:RemoveComponent( entity, "DisplayRadiusComponent" )
            end

            if ( EntityService:HasComponent( entity, "GhostLineCreatorComponent" ) ) then
                EntityService:RemoveComponent( entity, "GhostLineCreatorComponent" )
            end

            self:CheckEntityBuildable(entity, transform, false, i, false)
            EntityService:SetPosition( entity, newPositions[i])
            EntityService:SetOrientation(entity, transform.orientation )
            BuildingService:CheckAndFixBuildingConnection(entity)
        end

        local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
        for resourceCost in Iter(list) do
            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end
            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #newPositions )
        end
    else
        local transform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.entity, transform, false )
       -- BuildingService:CheckAndFixBuildingConnection(self.entity)
    end

    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function ghost_building_line:CheckConfigExists( wallLinesConfig )

    wallLinesConfig = wallLinesConfig or "1"

    local scaleWallLines = {
        -- 1
        "1",

        -- 2
        "11",

        -- 3
        "101",
        "111",

        -- 4
        "1011",
        "1111",

        -- 5
        "10101",
        "11111",

        -- 6
        "101011",
        "111111",

        -- 7
        "1010101",
        "1111111",

        -- 8
        "10101011",
        "11111111",

        -- 9
        "101010101",
        "111111111",

        -- 10
        "1010101011",
        "1111111111",

        -- 11
        "10101010101",
        "11111111111",
    }

    local index = IndexOf(scaleWallLines, wallLinesConfig )

    if ( index == nil ) then

        return "1"
    end

    return wallLinesConfig
end

-- Get positions to build wall entites
function ghost_building_line:FindPositionsToBuildLine(currentTransform, wallLinesConfig)

    -- Path from buildStartPosition to currentTransform
    local pathFromStartPositionToEndPosition = BuildingService:FindPathByBlueprint( self.buildStartPosition, currentTransform, self.blueprint )

    -- If wallLinesConfig equals "1" then do nothing, return path from buildStartPosition to currentTransform
    if ( wallLinesConfig == "1" ) then

        return pathFromStartPositionToEndPosition
    end

    if ( #pathFromStartPositionToEndPosition <= 1 ) then
        return pathFromStartPositionToEndPosition
    end

    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        positionPlayer = EntityService:GetPosition( player )
    end

    return self:CreateSolidWalls(pathFromStartPositionToEndPosition, wallLinesConfig, positionPlayer)
end

function ghost_building_line:CreateSolidWalls(pathFromStartPositionToEndPosition, wallLinesConfig, positionPlayer)

    local wallLinesConfigLen = string.len( wallLinesConfig )

    local deltaXZ = 2

    local startSignVector = self:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

    local vectorArray = self:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)

    local hashMerge = {}

    local arrayWallVectors = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        self:AddHashMerge( hashMerge, position.x, position.z, true )

        local wallVector = {}
        wallVector.position = position
        wallVector.isOuterCorner = false

        local signVector = vectorArray[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

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
    end

    for step=2,wallLinesConfigLen do

        if ( #arrayWallVectors == 0 ) then
            goto continue
        end

        local newArrayWallVectors = {}
    
        local hashPositions = {}

        --LogService:Log("Start step " .. tostring(step) .. " #arrayWallVectors " .. tostring(#arrayWallVectors) )

        for i=1,#arrayWallVectors do

            local wallVector = arrayWallVectors[i]

            local position = wallVector.position

            local signVector = wallVector.vector

            --LogService:Log("    i " .. tostring(i) .. " wallVector position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z))

            local newPositionX = position.x + signVector.x * deltaXZ
            local newPositionZ = position.z + signVector.z * deltaXZ

            if ( wallVector.isOuterCorner ) then

                self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, position.x, position.y, newPositionZ, false, 0, signVector.z)

                self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, position.y, position.z, false, signVector.x, 0)
            end

            self:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, position.y, newPositionZ, wallVector.isOuterCorner, signVector.x, signVector.z)
        end

        --LogService:Log("End step " .. tostring(step) )

        local filteredArrayNewVectors = {}
        local hashFilteredArrayNewVectors = {}

        local subStr = string.sub(wallLinesConfig, step, step)

        local hasWall = ( subStr == "1" )

        --LogService:Log("Start filter #newArrayWallVectors " .. tostring(#newArrayWallVectors) .. " subStr " .. tostring(subStr) .. " hasWall " .. tostring(hasWall) )

        for i=1,#newArrayWallVectors do

            local wallVector = newArrayWallVectors[i]

            local position = wallVector.position

            local signVector = wallVector.vector

            --LogService:Log("    i " .. tostring(i) .. " wallVector position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " signVector.x " .. tostring(signVector.x) .. " signVector.z " .. tostring(signVector.z))

            self:AddHashMerge( hashMerge, position.x, position.z, hasWall )

            local cellConfig = hashPositions[position.x][position.z]

            local canContinueWallVector = self:CanContitue(cellConfig)

            if ( canContinueWallVector ) then

                if ( not self:HashContains(hashFilteredArrayNewVectors, position.x, position.z ) ) then

                    Insert(filteredArrayNewVectors, wallVector)
                end
            end
        end

        --LogService:Log("End filter #newArrayWallVectors " .. tostring(#newArrayWallVectors) )


        arrayWallVectors = filteredArrayNewVectors
    end

    ::continue::
    
    local positionsArrayOrder = self:GetWallPositionInOrder(pathFromStartPositionToEndPosition, vectorArray, wallLinesConfig)

    local result = {}

    for position in Iter(positionsArrayOrder) do

        local hasWall = ( hashMerge[position.x] ~= nil and hashMerge[position.x][position.z] ~= nil and hashMerge[position.x][position.z].hasWall == true )

        --LogService:Log(" Wall position.x " .. tostring(position.x) .. " position.z " .. tostring(position.z) .. " hasWall " .. tostring(hasWall))

        if ( hasWall ) then

            table.insert(result, position)
        end
    end

    return result
end

function ghost_building_line:CanContitue(cellConfig)

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

function ghost_building_line:AddNewWallVector(hashMerge, hashPositions, newArrayWallVectors, newPositionX, positionY, newPositionZ, isOuterCorner, signVectorX, signVectorZ)

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

    Insert(newArrayWallVectors, newWallVector)
end

function ghost_building_line:GetWallPositionInOrder(pathFromStartPositionToEndPosition, vectorArray, wallLinesConfig)

    local wallLinesConfigLen = string.len( wallLinesConfig )

    local deltaXZ = 2

    local hashPositions = {}
    local positionsArray = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        local signVector = vectorArray[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        -- Add if position has not been added yet
        if ( not self:HashContains(hashPositions, position.x, position.z ) ) then

            table.insert(positionsArray, position)
        end

        -- Adding new positions for wall layers

        if ( hasChangesX and hasChangesZ ) then

            local cornerX, cornerZ = self:GetCornerVector(pathFromStartPositionToEndPosition, i)

            local cornerType = signVector.x * cornerX + signVector.z * cornerZ

            -- Outer Corner
            if (cornerType > 0) then

                for zStep=1,wallLinesConfigLen do

                    local index = (zStep - 1)

                    local newPositionZ = position.z + cornerZ * index * deltaXZ

                    local subStrZ = string.sub(wallLinesConfig, zStep, zStep)

                    local hasWall = (subStrZ == "1" )

                    if ( hasWall ) then

                        for xStep=1,zStep do

                            local newPositionX = position.x + cornerX * (xStep - 1) * deltaXZ

                            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                        end
                    end
                end

                for xStep=1,wallLinesConfigLen do

                    local index = (xStep - 1)

                    local newPositionX = position.x + cornerX * index * deltaXZ

                    local subStrX = string.sub(wallLinesConfig, xStep, xStep)

                    local hasWall = (subStrX == "1")

                    if ( hasWall ) then

                        for zStep=1,xStep do

                            local newPositionZ = position.z + cornerZ * (zStep - 1) * deltaXZ

                            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                        end
                    end
                end
            end

        elseif ( hasChangesX ) then

            self:AddNewPositionsByConfigByZ(position, wallLinesConfig, wallLinesConfigLen, signVector.z, deltaXZ, hashPositions, positionsArray)

        elseif ( hasChangesZ ) then

            self:AddNewPositionsByConfigByX(position, wallLinesConfig, wallLinesConfigLen, signVector.x, deltaXZ, hashPositions, positionsArray)

        end
    end

    return positionsArray
end

function ghost_building_line:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)

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

function ghost_building_line:RotateVector(signVector, degree)

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

function ghost_building_line:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

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

function ghost_building_line:GetNearestPosition(pathFromStartPositionToEndPosition, positionPlayer)

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

function ghost_building_line:SquareDistance( vector1, vector2 )

    local vector = {}

    vector.x = (vector2.x - vector1.x)
    vector.y = (vector2.y - vector1.y)
    vector.z = (vector2.z - vector1.z)

    return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z
end

function ghost_building_line:GetRotateDegree(pathFromStartPositionToEndPosition, cornerPositionNumber, direction)

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

function ghost_building_line:AddHashMerge(hashMerge, newPositionX, newPositionZ, hasWall)

    hashMerge[newPositionX] = hashMerge[newPositionX] or {}

    local hashXPosition = hashMerge[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        hashXPosition[newPositionZ] = {}

        hashXPosition[newPositionZ].hasWall = hasWall

        return
    end

    local cellConfig = hashXPosition[newPositionZ]

    cellConfig.hasWall = cellConfig.hasWall and hasWall
end

function ghost_building_line:GetXZSigns(position, positionPlayer)

    local xSign = 1
    local zSign = 1

    -- The offset is always away from the player.
    if( positionPlayer.x >= position.x ) then
        xSign = -1
    end

    if( positionPlayer.z >= position.z ) then
        zSign = -1
    end

    return xSign, zSign
end

function ghost_building_line:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

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

function ghost_building_line:GetCornerVector(pathFromStartPositionToEndPosition, cornerPositionNumber)

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

function ghost_building_line:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:HashContains(hashPositions, newPositionX, newPositionZ ) ) then

        local newPosition = {}
        newPosition.x = newPositionX
        newPosition.y = newPositionY
        newPosition.z = newPositionZ

        table.insert(positionsArray, newPosition)
    end
end

-- Check position has not already been added to hashPositions
function ghost_building_line:HashContains(hashPositions, newPositionX, newPositionZ)

    hashPositions[newPositionX] = hashPositions[newPositionX] or {}

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] ~= nil ) then

        return true
    end

    hashXPosition[newPositionZ] = true

    return false
end

function ghost_building_line:AddNewPositionsByConfigByX(position, wallLinesConfig, wallLinesConfigLen, xSign, deltaXZ, hashPositions, positionsArray)

    for step=1,wallLinesConfigLen do

        local newPositionX = position.x + xSign * (step - 1) * deltaXZ

        local subStr = string.sub(wallLinesConfig, step, step)

        local hasWall = (subStr == "1")
        if ( hasWall ) then

            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, position.z, position.y)
        end
    end
end

function ghost_building_line:AddNewPositionsByConfigByZ(position, wallLinesConfig, wallLinesConfigLen, zSign, deltaXZ, hashPositions, positionsArray)

    for step=1,wallLinesConfigLen do

        local newPositionZ = position.z + zSign * (step - 1) * deltaXZ

        local subStr = string.sub(wallLinesConfig, step, step)

        local hasWall = (subStr == "1")

        if ( hasWall ) then

            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, position.x, newPositionZ, position.y)
        end
    end
end

function ghost_building_line:FinishLineBuild()
    EntityService:SetVisible( self.entity, true )

    local count = #self.linesEntities -- 6
    local step = count
    if ( count > 5 )  then
        local additionalCubesCount = math.ceil( count / 5 )
        step = math.ceil( count / additionalCubesCount)
    end

    for i=1,count do

        local ghostEntity = self.linesEntities[i]

        local createCube = ((i == 1) or (i == count) or (i % step == 0))

        --LogService:Log(tostring(i) .. ":" .. tostring(step) .. ":" .. tostring(createCube))
        local transform = EntityService:GetWorldTransform( ghostEntity )
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghostEntity, "BuildingComponent"))

        local testBuildable = self:CheckEntityBuildable( ghostEntity, transform, false, i )
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

        elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then
            local healthComponent = EntityService:GetComponent(testBuildable.entity_to_repair, "HealthComponent")
            if ( healthComponent ~= nil ) then

                local healthComponentRef = reflection_helper(healthComponent)

                if ( healthComponentRef.health < healthComponentRef.max_health ) then
                    QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
                end
            end
        end

        EntityService:RemoveEntity(ghostEntity)
    end

    self.linesEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil

    self:DestroyPositionPlayerMarker()
end

function ghost_building_line:DestroyPositionPlayerMarker()

    if ( self.positionPlayerMarker ~= nil ) then
        EntityService:RemoveEntity( self.positionPlayerMarker )
        self.positionPlayerMarker = nil
    end
end

function ghost_building_line:OnActivate()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity, false )

        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        self.positionPlayer = EntityService:GetPosition( player )

        self:DestroyPositionPlayerMarker()

        self.positionPlayerMarker = EntityService:SpawnEntity( "effects/multilayeredwalls_markers/objective_marker", self.positionPlayer, EntityService:GetTeam(self.entity) )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function ghost_building_line:OnDeactivate()
    self:FinishLineBuild()
end

function ghost_building_line:OnRelease()

    for ghostEntity in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghostEntity)
    end
    self.linesEntities = {}

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    -- Destroy Marker with layers count
    if ( self.currentMarkerLines ~= nil ) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    self:DestroyPositionPlayerMarker()

    if ( ghost.OnRelease ) then
        ghost.OnRelease(self)
    end
end

return ghost_building_line