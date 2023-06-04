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

function thorns_walls_tool:FillCollisionBoxBounds( cornerPosition, firstPosition, lastPosition )

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

function thorns_walls_tool:PositionResult(positionX, positionZ)

    local result = (positionX - self.cornerPositionX) * self.cornerVectorZ - (positionZ - self.cornerPositionZ) * self.cornerVectorX

    if (result > 0) then

        return  1
    elseif result < 0 then

        return -1
    else

        return 0
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

function thorns_walls_tool:GetCorner(pathFromStartPositionToEndPosition)

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

function thorns_walls_tool:AddNewPositionsByConfigByX(position, wallLinesCount, xSign, deltaXZ, currentValue, hashPositions, result)

    for step=1,wallLinesCount do

        local newPositionX = position.x + xSign * (step - 1) * deltaXZ

        if ( self:PerformCheckCollisionBox( newPositionX, position.z, currentValue ) ) then

            self:AddNewPositionToResult(hashPositions, result, newPositionX, position.z, position.y)
        end
    end
end

function thorns_walls_tool:AddNewPositionsByConfigByZ(position, wallLinesCount, zSign, deltaXZ, currentValue, hashPositions, result)

    for step=1,wallLinesCount do

        local newPositionZ = position.z + zSign * (step - 1) * deltaXZ

        if ( self:PerformCheckCollisionBox( position.x, newPositionZ, currentValue ) ) then

            self:AddNewPositionToResult(hashPositions, result, position.x, newPositionZ, position.y)
        end
    end
end

function thorns_walls_tool:PerformCheckCollisionBox( newPositionX, newPositionZ, currentValue)

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

function thorns_walls_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)

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
function thorns_walls_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

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