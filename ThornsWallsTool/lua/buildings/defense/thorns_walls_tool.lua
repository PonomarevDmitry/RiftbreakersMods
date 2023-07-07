require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'thorns_walls_tool' ( LuaEntityObject )

function thorns_walls_tool:__init()
    LuaEntityObject.__init(self,self)
end

function thorns_walls_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function thorns_walls_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    local selectorDB = EntityService:GetDatabase( self.selector )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity, false )

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent" ))

    local floorRef = reflection_helper(BuildingService:GetBuildingDesc( buildingComponent.bp ))

    self.floorBlueprint = floorRef.ghost_bp

    self.ghostWall = nil

    self.linesEntities = {}
    self.floorEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    self.wallBlueprint = self:GetWallBlueprint( selectorDB )

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self:SpawnWallTemplates()

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsCount = "$thorns_walls_count"

    -- Wall layers config
    self.wallLinesCount = selectorDB:GetIntOrDefault(self.configNameWallsCount, 2)
    self.wallLinesCount = self:CheckConfigExists(self.wallLinesCount)
end

function thorns_walls_tool:GetWallBlueprint( selectorDB )

    local defaultWall = "buildings/defense/wall_small_straight_01"

    local parameterName = "$selected_wall_small_blueprint"

    local blueprintName = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultWall)
    end

    if ( blueprintName == "" ) then
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
            blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultWall)
        end
    end

    if ( blueprintName == "" ) then
        return defaultWall
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultWall
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultWall
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultWall
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return defaultWall
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return defaultWall
    end

    return blueprintName
end

function thorns_walls_tool:SpawnWallTemplates()

    --local markerDB = EntityService:GetDatabase( self.markerEntity )
    --markerDB:SetString("message_text", "")
    --markerDB:SetInt("message_visible", 0)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( self.wallBlueprint ) )

    local transform = EntityService:GetWorldTransform( self.entity )

    local position = transform.position
    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local newPosition = EntityService:GetWorldTransform( self.entity ).position

    local buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.ghost_bp, self.selector )

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    self.ghostBlueprint = buildingDesc.ghost_bp

    self.buildingDesc = buildingDesc
    self.ghostWall = buildingEntity
end

function thorns_walls_tool:OnWorkExecute()

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

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.ghostWall )

        local newPositions, pathFromStartPositionToEndPosition = self:FindPositionsToBuildLine( currentTransform, wallLinesCount )

        if ( #self.linesEntities > #newPositions ) then

            for i=#self.linesEntities,#newPositions + 1,-1 do
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end

        elseif ( #self.linesEntities < #newPositions ) then

            for i=#self.linesEntities + 1 ,#newPositions do

                local lineEnt = EntityService:SpawnEntity( self.ghostBlueprint, newPositions[i], team )
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
            self:CheckEntityBuildable(entity, transform, false, i, false)
            EntityService:SetPosition( entity, newPositions[i])
            EntityService:SetOrientation(entity, transform.orientation )
            BuildingService:CheckAndFixBuildingConnection(entity)
        end

        local list = BuildingService:GetBuildCosts( self.wallBlueprint, self.playerId )
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

                local lineEnt = EntityService:SpawnEntity( self.floorBlueprint, pathFromStartPositionToEndPosition[i], team )
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
        local transform = EntityService:GetWorldTransform( self.ghostWall )
        local testBuildable = self:CheckEntityBuildable( self.ghostWall, transform )
    end



    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function thorns_walls_tool:FindPositionsToBuildLine( currentTransform, wallLinesCount )

    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        positionPlayer = EntityService:GetPosition( player )
    end

    local pathFromStartPositionToEndPosition = BuildingService:FindPathByBlueprint( self.buildStartPosition, currentTransform, self.wallBlueprint )




    local pathDistanceArray = self:GetPathDistanceArray(pathFromStartPositionToEndPosition)
    

    local deltaXZ = 2

    local hashPositions = {}
    local positionsArray = {}

    local hashMerge = {}

    local startSignVector = self:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

    local vectorArray = self:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)

    local hashOriginal = {}

    for position in Iter(pathFromStartPositionToEndPosition) do

        hashOriginal[position.x] = hashOriginal[position.x] or {}

        hashOriginal[position.x][position.z] = true
    end

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        local signVector = vectorArray[i]

        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

        local positionDistance = pathDistanceArray[i]

        local hasWall = ( positionDistance % 2 ) == 0

        if ( hasChangesX and hasChangesZ ) then

            local cornerX, cornerZ = self:GetCornerVector(pathFromStartPositionToEndPosition, i)

            local cornerType = signVector.x * cornerX + signVector.z * cornerZ

            -- Outer Corner
            if (cornerType > 0) then

                for indexStep=0,wallLinesCount-1 do

                    local hasWall = (indexStep % 2) == 0

                    local newBasePositionX = position.x + cornerX * indexStep * deltaXZ
                    local newBasePositionZ = position.z + cornerZ * indexStep * deltaXZ

                    if ( hasWall ) then
                        self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newBasePositionX, newBasePositionZ, position.y)
                    end

                    self:AddHashMerge( hashMerge, newBasePositionX, newBasePositionZ, indexStep, hasWall )

                    for zStep=1,(wallLinesCount - 1 - indexStep) do

                        local newPositionZ = newBasePositionZ + cornerZ * zStep * deltaXZ

                        if ( hasWall ) then
                            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newBasePositionX, newPositionZ, position.y)
                        end

                        self:AddHashMerge( hashMerge, newBasePositionX, newPositionZ, indexStep + zStep, hasWall )
                    end

                    for xStep=1,(wallLinesCount - 1 - indexStep) do

                        local newPositionX = newBasePositionX + cornerX * xStep * deltaXZ

                        if ( hasWall ) then
                            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newBasePositionZ, position.y)
                        end

                        self:AddHashMerge( hashMerge, newPositionX, newBasePositionZ, indexStep + xStep, hasWall )
                    end
                end



                --for zStep=1,wallLinesConfigLen do
                --
                --    local index = (zStep - 1)
                --
                --    local newPositionZ = position.z + cornerZ * index * deltaXZ
                --
                --    local subStrZ = string.sub(wallLinesConfig, zStep, zStep)
                --
                --    local hasWall = (subStrZ == "1" )
                --
                --    for xStep=1,zStep do
                --
                --        local newPositionX = position.x + cornerX * (xStep - 1) * deltaXZ
                --
                --        if ( hasWall ) then
                --
                --            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                --        end
                --
                --        self:AddHashMerge( hashMerge, newPositionX, newPositionZ, index, hasWall )
                --
                --        if ( xStep ~= 1 and zStep ~= 1 ) then
                --
                --            if ( hashOriginal[newPositionX] and hashOriginal[newPositionX][newPositionZ] == true ) then
                --                goto continueZStep
                --            end
                --        end
                --    end
                --
                --    ::continueZStep::
                --
                --    if ( zStep ~= 1 ) then
                --
                --        if ( hashOriginal[position.x] and hashOriginal[position.x][newPositionZ] == true ) then
                --            goto continueOuterCorner
                --        end
                --    end
                --end
                --
                --::continueOuterCorner::
                --
                --for xStep=1,wallLinesConfigLen do
                --
                --    local index = (xStep - 1)
                --
                --    local newPositionX = position.x + cornerX * index * deltaXZ
                --
                --    local subStrX = string.sub(wallLinesConfig, xStep, xStep)
                --
                --    local hasWall = (subStrX == "1")
                --
                --    for zStep=1,xStep do
                --
                --        local newPositionZ = position.z + cornerZ * (zStep - 1) * deltaXZ
                --
                --        if ( hasWall ) then
                --
                --            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, position.y)
                --        end
                --
                --        self:AddHashMerge( hashMerge, newPositionX, newPositionZ, index, hasWall )
                --
                --        if ( xStep ~= 1 and zStep ~= 1 ) then
                --
                --            if ( hashOriginal[newPositionX] and hashOriginal[newPositionX][newPositionZ] == true ) then
                --                goto continueXStep
                --            end
                --        end
                --    end
                --
                --    ::continueXStep::
                --
                --    if ( xStep ~= 1 ) then
                --
                --        if ( hashOriginal[newPositionX] and hashOriginal[newPositionX][position.z] == true ) then
                --            goto endOuterCorner
                --        end
                --    end
                --end
                --
                --::endOuterCorner::
            end

        elseif ( hasChangesX ) then

            self:AddNewPositionsByConfigByZ(hasWall, position, wallLinesCount, signVector.z, deltaXZ, hashPositions, positionsArray, hashMerge, hashOriginal)

        elseif ( hasChangesZ ) then

            self:AddNewPositionsByConfigByX(hasWall, position, wallLinesCount, signVector.x, deltaXZ, hashPositions, positionsArray, hashMerge, hashOriginal)
        end
    end




    local result = {}

    for position in Iter(positionsArray) do

        if ( hashMerge[position.x] and hashMerge[position.x][position.z] and hashMerge[position.x][position.z].hasWall == true ) then

            table.insert(result, position)
        end
    end

    return result, pathFromStartPositionToEndPosition
end

function thorns_walls_tool:GetPathDistanceArray(pathFromStartPositionToEndPosition)

    local cornersArray = self:GetCornersArray(pathFromStartPositionToEndPosition)

    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local minDistance = self:GetMinDistance(i, cornersArray)

        result[i] = minDistance
    end

    return result
end

function thorns_walls_tool:GetMinDistance(number, cornersArray)

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

function thorns_walls_tool:GetCornersArray(pathFromStartPositionToEndPosition)

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

function thorns_walls_tool:GetVectorArray(pathFromStartPositionToEndPosition, startSignVector)

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

function thorns_walls_tool:RotateVector(signVector, degree)

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

function thorns_walls_tool:GetStartSignVector(pathFromStartPositionToEndPosition, positionPlayer)

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

function thorns_walls_tool:GetNearestPosition(pathFromStartPositionToEndPosition, positionPlayer)

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

function thorns_walls_tool:SquareDistance( vector1, vector2 )

    local vector = {}

    vector.x = (vector2.x - vector1.x)
    vector.y = (vector2.y - vector1.y)
    vector.z = (vector2.z - vector1.z)

    return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z
end

function thorns_walls_tool:GetRotateDegree(pathFromStartPositionToEndPosition, cornerPositionNumber, direction)

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

function thorns_walls_tool:AddHashMerge(hashMerge, newPositionX, newPositionZ, index, hasWall)

    hashMerge[newPositionX] = hashMerge[newPositionX] or {}

    local hashXPosition = hashMerge[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        hashXPosition[newPositionZ] = {}

        hashXPosition[newPositionZ].currentIndex = index
        hashXPosition[newPositionZ].hasWall = hasWall

        return
    end

    local cellConfig = hashXPosition[newPositionZ]

    if ( cellConfig.currentIndex > index ) then

        cellConfig.currentIndex = index
        cellConfig.hasWall = hasWall

    elseif ( cellConfig.currentIndex == index ) then

        cellConfig.hasWall = cellConfig.hasWall or hasWall
    end
end

function thorns_walls_tool:GetXZSigns(position, positionPlayer)

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

function thorns_walls_tool:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)

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

function thorns_walls_tool:GetCornerVector(pathFromStartPositionToEndPosition, cornerPositionNumber)

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

function thorns_walls_tool:AddNewPositionsByConfigByX(hasWall, position, wallLinesCount, xSign, deltaXZ, hashPositions, positionsArray, hashMerge, hashOriginal)

    for index=0,wallLinesCount-1 do
        
        local newPositionX = position.x + xSign * index * deltaXZ

        if ( hasWall ) then

            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, position.z, position.y)
        end

        self:AddHashMerge( hashMerge, newPositionX, position.z, index, hasWall )

        if ( index ~= 0 ) then

            if ( hashOriginal[newPositionX] and hashOriginal[newPositionX][position.z] == true ) then
                return
            end
        end
    end
end

function thorns_walls_tool:AddNewPositionsByConfigByZ(hasWall, position, wallLinesCount, zSign, deltaXZ, hashPositions, positionsArray, hashMerge, hashOriginal)

    for index=0,wallLinesCount-1 do
        
        local newPositionZ = position.z + zSign * index * deltaXZ

        if ( hasWall ) then

            self:AddNewPositionToPositionsArray(hashPositions, positionsArray, position.x, newPositionZ, position.y)
        end

        self:AddHashMerge( hashMerge, position.x, newPositionZ, index, hasWall )

        if ( index ~= 0 ) then

            if ( hashOriginal[position.x] and hashOriginal[position.x][newPositionZ] == true ) then
                return
            end
        end
    end
end

function thorns_walls_tool:AddNewPositionToPositionsArray(hashPositions, positionsArray, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:HashContains( hashPositions, newPositionX, newPositionZ ) ) then
        return
    end

    local newPosition = {}
    newPosition.x = newPositionX
    newPosition.y = newPositionY
    newPosition.z = newPositionZ

    table.insert(positionsArray, newPosition)
end

-- Check position has not already been added to hashPositions
function thorns_walls_tool:HashContains(hashPositions, newPositionX, newPositionZ)

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

function thorns_walls_tool:CheckConfigExists( wallLinesCount )

    wallLinesCount = wallLinesCount or 2

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf( scaleWallLines, wallLinesCount )

    if ( index == nil ) then

        return scaleWallLines[1]
    end

    return wallLinesCount
end

function thorns_walls_tool:GetWallConfigArray()

    local scaleWallLines = {
        2,
        3,
        4,
        5,
        6,
        8,
        10
    }

    return scaleWallLines
end

function thorns_walls_tool:CheckEntityBuildable( entity, transform, id )
    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprint, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper(test:ToTypeInstance(), test )

    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

    local skinned = EntityService:IsSkinned(entity)

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_pass")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_pass")
            end
        else
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_deny")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_deny")
            end
        end
    else
        if ( canBuildOverride ) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_active_skinned")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_active")
            end
        elseif ( canBuild ) then
            EntityService:ChangeMaterial( entity, "selector/hologram_blue")
        else
            EntityService:ChangeMaterial( entity, "selector/hologram_red")
        end
    end

    return testBuildable
end

function thorns_walls_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.ghostWall )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall, false )

        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        self.positionPlayer = EntityService:GetPosition( player )

        self:OnWorkExecute()
    else
        self:FinishLineBuild()
    end
end

function thorns_walls_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()
end

function thorns_walls_tool:FinishLineBuild()

    EntityService:SetVisible( self.ghostWall, true )

    for floorGhost in Iter(self.floorEntities) do
        EntityService:RemoveEntity(floorGhost)
    end
    self.floorEntities = {}

    local count = #self.linesEntities
    local step = count

    if ( count > 5 ) then
        local additionalCubesCount = math.ceil( count / 5 )
        step = math.ceil( count / additionalCubesCount)
    end

    for i=1,count do

        local ghost = self.linesEntities[i]
        local createCube = ((i == 1) or (i == count) or (i % step == 0))

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

    self.linesEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function thorns_walls_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local scaleWallLines = self:GetWallConfigArray()

    local currentLinesConfig = self:CheckConfigExists(self.wallLinesCount)

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

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

    self:OnWorkExecute()
end

function thorns_walls_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}

    for floorGhost in Iter(self.floorEntities) do
        EntityService:RemoveEntity(floorGhost)
    end
    self.floorEntities = {}

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( self.ghostWall ~= nil) then
        EntityService:RemoveEntity(self.ghostWall)
        self.ghostWall = nil
    end

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end
end

return thorns_walls_tool