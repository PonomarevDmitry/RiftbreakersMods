local wall_base_tool = require("lua/buildings/defense/wall_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_borders_tool' ( wall_base_tool )

function wall_borders_tool:__init()
    wall_base_tool.__init(self,self)
end

function wall_borders_tool:OnInit()

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    -- Marker with number of wall layers
    self.markerLinesConfig = "0"
    self.currentMarkerLines = nil

    self.configNameWallsConfig = "$wall_borders_lines_config"

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Wall layers config
    self.wallLinesConfig = selectorDB:GetStringOrDefault(self.configNameWallsConfig, "1")
    self.wallLinesConfig = self:CheckConfigExists(self.wallLinesConfig)
end

function wall_borders_tool:OnUpdate()

    self.buildCost = {}

    -- Wall layers config
    local wallLinesConfig = self:CheckConfigExists(self.wallLinesConfig)

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

    self:RemoveMaterialFromOldBuildingsToSell()

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.ghostWall )

        local buildEndPosition = currentTransform.position

        local newPositionsArray, hashPositions = self:FindPositionsToBuildLine( buildEndPosition, wallLinesConfig )

        local oldLinesEntities = self.linesEntities
        local oldLinesEntityInfo = self.linesEntityInfo
        local oldGridEntities = self.gridEntities

        local newLinesEntities = {}
        local newLinesEntityInfo = {}
        local newGridEntities = {}

        for i=1,#newPositionsArray do

            local newPosition = newPositionsArray[i]

            local lineEnt = self:GetEntityFromGrid( oldGridEntities, newPosition.x, newPosition.z )

            if ( lineEnt == nil ) then

                lineEnt = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
                EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
                EntityService:RemoveComponent(lineEnt, "LuaComponent")

                EntityService:SetOrientation(lineEnt, currentTransform.orientation )
                EntityService:SetPosition( lineEnt, newPosition)
            end

            Insert( newLinesEntities, lineEnt )
            self:InsertEntityToGrid( newGridEntities, lineEnt, newPosition.x, newPosition.z  )

            local entityInfo = {}

            entityInfo.position = newPosition
            entityInfo.entity = lineEnt

            Insert( newLinesEntityInfo, entityInfo )
        end

        for i=#oldLinesEntityInfo,1,-1 do

            local entityInfo = oldLinesEntityInfo[i]

            local lineEnt = entityInfo.entity

            local lineEntPosition = entityInfo.position

            if ( not self:HashContains( hashPositions, lineEntPosition.x, lineEntPosition.z ) ) then

                EntityService:RemoveEntity( lineEnt )
                oldLinesEntityInfo[i] = nil
            end
        end

        for i=1,#newLinesEntities do

            local lineEnt = newLinesEntities[i]

            local transform = EntityService:GetWorldTransform( lineEnt )

            local testBuildable = self:CheckEntityBuildable( lineEnt, transform, i )

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end

            BuildingService:CheckAndFixBuildingConnection( lineEnt )
        end

        self.linesEntities = newLinesEntities
        self.linesEntityInfo = newLinesEntityInfo
        self.gridEntities = newGridEntities

        local list = BuildingService:GetBuildCosts( self.wallBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0 
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #newPositionsArray )
        end
    else
        local transform = EntityService:GetWorldTransform( self.ghostWall )
        local testBuildable = self:CheckEntityBuildable( self.ghostWall, transform )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
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

function wall_borders_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then
    
        return nil
    end
    
    local arrayXPosition = gridEntities[newPositionX]
    
    if ( arrayXPosition[newPositionZ] == nil ) then
        
        return nil
    end

    return arrayXPosition[newPositionZ]
end

function wall_borders_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then
    
        gridEntities[newPositionX] = {}
    end
    
    local arrayXPosition = gridEntities[newPositionX]
    
    arrayXPosition[newPositionZ] = lineEnt
end

function wall_borders_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then
    
        return false
    end
    
    local hashXPosition = hashPositions[newPositionX]
    
    if ( hashXPosition[newPositionZ] == nil ) then
        
        return false
    end
    
    return true
end

function wall_borders_tool:FindPositionsToBuildLine( buildEndPosition, wallLinesConfig )

    local xSign, zSign = self:GetXZSigns( self.buildStartPosition.position, buildEndPosition)

    local arrayX, arrayZ = self:FindGridArrays( self.buildStartPosition.position, buildEndPosition )

    local buildStartPositionX = self.buildStartPosition.position.x
    local buildStartPositionZ = self.buildStartPosition.position.z

    local buildEndPositionX = buildEndPosition.x
    local buildEndPositionZ = buildEndPosition.z

    local positionY = self.buildStartPosition.position.y

    local result = {}
    local hashPositions = {}

    local deltaXZ = 2

    self:AddCornerPositions(wallLinesConfig, buildStartPositionX, positionY, buildStartPositionZ, -xSign, -zSign, deltaXZ, hashPositions, result)



    self:AddNewPositionsByZArray(wallLinesConfig, buildStartPositionX, positionY, arrayZ, -xSign, deltaXZ, hashPositions, result)

    self:AddCornerPositions(wallLinesConfig, buildStartPositionX, positionY, buildEndPositionZ, -xSign, zSign, deltaXZ, hashPositions, result)



    self:AddNewPositionsByXArray(wallLinesConfig, arrayX, positionY, buildStartPositionZ, -zSign, deltaXZ, hashPositions, result)

    self:AddCornerPositions(wallLinesConfig, buildEndPositionX, positionY, buildStartPositionZ, xSign, -zSign, deltaXZ, hashPositions, result)



    self:AddNewPositionsByZArray(wallLinesConfig, buildEndPositionX, positionY, arrayZ, xSign, deltaXZ, hashPositions, result)

    self:AddNewPositionsByXArray(wallLinesConfig, arrayX, positionY, buildEndPositionZ, zSign, deltaXZ, hashPositions, result)


    self:AddCornerPositions(wallLinesConfig, buildEndPositionX, positionY, buildEndPositionZ, xSign, zSign, deltaXZ, hashPositions, result)

    return result, hashPositions
end

function wall_borders_tool:AddCornerPositions(wallLinesConfig, positionX, positionY, positionZ, xSign, zSign, deltaXZ, hashPositions, result)

    for zStep=1,#wallLinesConfig do

        local subStrZ = string.sub(wallLinesConfig, zStep, zStep)
                    
        for xStep=1,#wallLinesConfig do
                    
            local subStrX = string.sub(wallLinesConfig, xStep, xStep)
                    
            if ( (subStrZ == "1" and xStep <= zStep) or (subStrX == "1" and zStep <= xStep) ) then
                            
                local newPositionX = positionX + xSign * (xStep - 1) * deltaXZ
                local newPositionZ = positionZ + zSign * (zStep - 1) * deltaXZ
                            
                self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, positionY)
            end
        end
    end
end

function wall_borders_tool:AddNewPositionsByXArray(wallLinesConfig, arrayX, positionY, positionZ, zSign, deltaXZ, hashPositions, result)

    for xIndex=1,#arrayX do
                
        local positionX = arrayX[xIndex]
        
        local position = {}
                
        position.x = positionX
        position.y = positionY
        position.z = positionZ

        self:AddNewPositionsByConfigByZ(position, wallLinesConfig, zSign, deltaXZ, hashPositions, result)
    end
end

function wall_borders_tool:AddNewPositionsByZArray(wallLinesConfig, positionX, positionY, arrayZ, xSign, deltaXZ, hashPositions, result)

    for zIndex=1,#arrayZ do
                
        local positionZ = arrayZ[zIndex]
        
        local position = {}
                
        position.x = positionX
        position.y = positionY
        position.z = positionZ

        self:AddNewPositionsByConfigByX(position, wallLinesConfig, xSign, deltaXZ, hashPositions, result)
    end
end

function wall_borders_tool:AddNewPositionsByConfigByX(position, wallLinesConfig, xSign, deltaXZ, hashPositions, result)

    for step=1,#wallLinesConfig do

        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then

            local newPositionX = position.x + xSign * (step - 1) * deltaXZ
            
            self:AddNewPositionToResult(hashPositions, result, newPositionX, position.z, position.y)
        end
    end  
end

function wall_borders_tool:AddNewPositionsByConfigByZ(position, wallLinesConfig, zSign, deltaXZ, hashPositions, result)

    for step=1,#wallLinesConfig do
    
        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then
        
            local newPositionZ = position.z + zSign * (step - 1) * deltaXZ

            self:AddNewPositionToResult(hashPositions, result, position.x, newPositionZ, position.y)
        end
    end
end

function wall_borders_tool:FindGridArrays(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.ghostWall)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local deltaX = gridSize.x * 2 * xSign
    local deltaZ = gridSize.z * 2 * zSign

    local smallDeltaX = (gridSize.x * xSign) / 2
    local smallDeltaZ = (gridSize.z * zSign) / 2

    local buildEndPositionX = buildEndPosition.x + smallDeltaX
    local buildEndPositionZ = buildEndPosition.z + smallDeltaZ

    local minX = math.min( buildStartPosition.x, buildEndPositionX )
    local maxX = math.max( buildStartPosition.x, buildEndPositionX )

    local minZ = math.min( buildStartPosition.z, buildEndPositionZ )
    local maxZ = math.max( buildStartPosition.z, buildEndPositionZ )

    local arrayX = {}

    local positionX = buildStartPosition.x

    while (minX <= positionX and positionX <= maxX) do

        Insert(arrayX, positionX)

        positionX = positionX + deltaX
    end

    local arrayZ = {}

    local positionZ = buildStartPosition.z

    while (minZ <= positionZ and positionZ <= maxZ) do

        Insert(arrayZ, positionZ)

        positionZ = positionZ + deltaZ
    end

    return arrayX, arrayZ
end

function wall_borders_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)
    
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
function wall_borders_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

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

function wall_borders_tool:CheckConfigExists( wallLinesConfig )

    wallLinesConfig = wallLinesConfig or "1"

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf(scaleWallLines, wallLinesConfig )

    if ( index == nil ) then 

        return scaleWallLines[1]
    end

    return wallLinesConfig
end

function wall_borders_tool:GetWallConfigArray()

    if ( self.scaleWallLines == nil ) then

        self.scaleWallLines = {
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

            -- 8
            "10101011",

            -- 9
            "101010101",

            -- 10
            "1010101011",

            -- 11
            "10101010101"
        }
    end

    return self.scaleWallLines
end

function wall_borders_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall , false )
        
        local player = PlayerService:GetPlayerControlledEnt(0)
        self.positionPlayer = EntityService:GetPosition( player )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function wall_borders_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()
end

function wall_borders_tool:FinishLineBuild()

    EntityService:SetVisible( self.ghostWall , true )

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

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function wall_borders_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()
    
    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentLinesConfig = self:CheckConfigExists(self.wallLinesConfig)

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

    self.wallLinesConfig = newValue

    -- Wall layers config
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetString(self.configNameWallsConfig, newValue)

    self:OnUpdate()
end

function wall_borders_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
    
    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then
    
        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_borders_tool