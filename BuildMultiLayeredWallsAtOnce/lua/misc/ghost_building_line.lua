local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")

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
    --    EntityService:SetVisible( self.entity , false )
    --    
    --    local player = PlayerService:GetPlayerControlledEnt(0)
    --    self.positionPlayer = EntityService:GetPosition( player )
    --end

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
    
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
            self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
            
            -- Save number of wall layers
            self.markerLinesConfig = wallLinesConfig
            
        end
    end

    if ( self.buildStartPosition ) then
        
        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local newPositions = self:FindPositionsToBuildLine( currentTransform, wallLinesConfig )

        if ( #self.linesEntities > #newPositions ) then
        
            for i=#self.linesEntities,#newPositions + 1,-1 do 
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end
            
        elseif ( #self.linesEntities < #newPositions ) then
        
            for i=#self.linesEntities + 1 ,#newPositions do

                local lineEnt = EntityService:SpawnEntity(self.ghostBlueprint, newPositions[i], EntityService:GetTeam(self.entity) )
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
        local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )
       -- BuildingService:CheckAndFixBuildingConnection(self.entity)

    end
    
    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end
    
    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    
    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost)
    else
        BuildingService:OperateBuildCosts( self.infoChild , self.playerId, {})
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
    local pathFromStartPositionToEndPosition = BuildingService:FindPathByBlueprint(self.buildStartPosition, currentTransform, self.blueprint )
    
    -- If wallLinesConfig equals "1" then do nothing, return path from buildStartPosition to currentTransform
    if ( wallLinesConfig == "1" ) then
    
        return pathFromStartPositionToEndPosition    
    end
    
    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(0)
        positionPlayer = EntityService:GetPosition( player )    
    end

    return self:CreateSolidWalls(pathFromStartPositionToEndPosition, wallLinesConfig, positionPlayer)
end

function ghost_building_line:PositionResult(positionX, positionZ)

    local result = (positionX - self.cornerPositionX) * self.cornerVectorZ - (positionZ - self.cornerPositionZ) * self.cornerVectorX
    
    if (result > 0) then
    
        return  1
    elseif result < 0 then
    
        return -1
    else
    
        return 0
    end
end

function ghost_building_line:CreateSolidWalls(pathFromStartPositionToEndPosition, wallLinesConfig, positionPlayer)
    
    local odds, cornerTileNumber = self:GetCorner(pathFromStartPositionToEndPosition)
    
    self.cornerVectorX = 0
    self.cornerVectorZ = 0
    self.cornerPositionX = 0
    self.cornerPositionZ = 0
    
    self.checkCollisionBox = false
    
    local cornerType = 0
            
    local wallLinesConfigLen = string.len( wallLinesConfig )
    
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
            
            self:FillCollisionBoxBounds( wallLinesConfigLen, cornerPosition, firstPosition, lastPosition )
        end
    end
    
    local deltaXZ = 2

    local hashPositions = {}
    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do
    
        local position = pathFromStartPositionToEndPosition[i]
        
        local hasChangesX, hasChangesZ = self:GetPositionXZChanges(pathFromStartPositionToEndPosition, position, i)
        
        local xSign, zSign = self:GetXZSigns(position, positionPlayer)
                
        -- Add if position has not been added yet
        if ( not self:HashContains(hashPositions, position.x, position.z ) ) then

            table.insert(result, position)
        end

        -- Adding new positions for wall layers

        local currentValue = self:PositionResult(position.x, position.z)
        
        if ( hasChangesX ) then

            self:AddNewPositionsByConfigByZ(position, wallLinesConfig, wallLinesConfigLen, zSign, deltaXZ, currentValue, hashPositions, result)
        end
        
        if ( hasChangesZ ) then
        
            self:AddNewPositionsByConfigByX(position, wallLinesConfig, wallLinesConfigLen, xSign, deltaXZ, currentValue, hashPositions, result)
        end
        
        if ( hasChangesX and hasChangesZ ) then
            
            -- Outer Corner
            if (cornerType == 2) then
            
                for zStep=1,wallLinesConfigLen do

                    local subStrZ = string.sub(wallLinesConfig, zStep, zStep)
                    
                    for xStep=1,wallLinesConfigLen do
                    
                        local subStrX = string.sub(wallLinesConfig, xStep, xStep)
                    
                        if ( (subStrZ == "1" and xStep <= zStep) or (subStrX == "1" and zStep <= xStep) ) then
                            
                            local newPositionX = position.x + xSign * (xStep - 1) * deltaXZ
                            local newPositionZ = position.z + zSign * (zStep - 1) * deltaXZ
                            
                            self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
                        end
                    end
                end
            end
        end
    end
    
    return result
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

function ghost_building_line:GetCorner(pathFromStartPositionToEndPosition)

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

function ghost_building_line:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:HashContains(hashPositions, newPositionX, newPositionZ ) ) then

        local newPosition = {}
        newPosition.x = newPositionX
        newPosition.y = newPositionY
        newPosition.z = newPositionZ

        table.insert(result, newPosition)
    end
end

-- Check position has not already been added to hashPositions
function ghost_building_line:HashContains(hashPositions, newPositionX, newPositionZ)

    if ( hashPositions[newPositionX] == nil) then
    
        hashPositions[newPositionX] = {}
    end
    
    local hashXPosition = hashPositions[newPositionX]
    
    if ( hashXPosition[newPositionZ] ~= nil ) then
        
        return true
    end
    
    hashXPosition[newPositionZ] = true
    
    return false
end

function ghost_building_line:AddNewPositionsByConfigByX(position, wallLinesConfig, wallLinesConfigLen, xSign, deltaXZ, currentValue, hashPositions, result)

    for step=2,wallLinesConfigLen do

        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then

            local newPositionX = position.x + xSign * (step - 1) * deltaXZ
            
            if ( self:PerformCheckCollisionBox( newPositionX, position.z, currentValue ) ) then
            
                self:AddNewPositionToResult(hashPositions, result, newPositionX, position.z, position.y)
            end
        end
    end  
end

function ghost_building_line:AddNewPositionsByConfigByZ(position, wallLinesConfig, wallLinesConfigLen, zSign, deltaXZ, currentValue, hashPositions, result)

    for step=2,wallLinesConfigLen do
    
        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then
        
            local newPositionZ = position.z + zSign * (step - 1) * deltaXZ
            
            if ( self:PerformCheckCollisionBox( position.x, newPositionZ, currentValue ) ) then
            
                self:AddNewPositionToResult(hashPositions, result, position.x, newPositionZ, position.y)
            end
        end
    end
end

function ghost_building_line:PerformCheckCollisionBox( newPositionX, newPositionZ, currentValue)

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

function ghost_building_line:FillCollisionBoxBounds( wallLinesConfigLen, cornerPosition, firstPosition, lastPosition )

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

function ghost_building_line:FinishLineBuild()
    EntityService:SetVisible( self.entity , true )

    local count = #self.linesEntities -- 6
    local step = count
    if ( count > 5 )  then
        local additionalCubesCount = math.ceil( count / 5 ) 
        step = math.ceil( count / additionalCubesCount) 
    end

    for i=1,count do

        local ghost = self.linesEntities[i]

        local createCube = i == 1 or i == count or i % step == 0

        --LogService:Log(tostring(i) .. ":" .. tostring(step) .. ":" .. tostring(createCube))
        local transform = EntityService:GetWorldTransform( ghost )
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghost, "BuildingComponent"))
       
        local testBuildable = self:CheckEntityBuildable( ghost , transform, false, i )
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )
            
        elseif( testBuildable.flag == CBF_REPAIR  ) then
            QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
        end

        EntityService:RemoveEntity(ghost)
    end

    self.linesEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function ghost_building_line:OnActivate()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )

        local player = PlayerService:GetPlayerControlledEnt(0)
        self.positionPlayer = EntityService:GetPosition( player )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end

end

function ghost_building_line:OnDeactivate()
    self:FinishLineBuild()
end

function ghost_building_line:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
    end
    
    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then
    
        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end
end

return ghost_building_line