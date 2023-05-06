require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_perimeter_tool' ( LuaEntityObject )

function wall_perimeter_tool:__init()
    LuaEntityObject.__init(self,self)
end

function wall_perimeter_tool:init()
    
    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function wall_perimeter_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity , false )
    
    self.ghostWall = nil

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.wallBlueprintName = self:GetWallBlueprintName( selectorDB )

    self:SpawnWallTemplates(self.wallBlueprintName)

    -- Marker with number of wall layers
    self.markerLinesConfig = "0"
    self.currentMarkerLines = nil

    self.configNameWallsConfig = "$wall_perimeter_lines_config"

    -- Wall layers config
    self.wallLinesConfig = selectorDB:GetStringOrDefault(self.configNameWallsConfig, "1")
    self.wallLinesConfig = self:CheckConfigExists(self.wallLinesConfig)

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function wall_perimeter_tool:GetWallBlueprintName( selectorDB )

    local defaultWall = "buildings/defense/wall_small_straight_01"

    local blueprintName = selectorDB:GetStringOrDefault("$selected_wall_small_blueprint", defaultWall)

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultWall
    end

    if ( not BuildingService:IsBuildingAvailable( blueprintName ) ) then
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

function wall_perimeter_tool:SpawnWallTemplates(wallBlueprintName)

    --local markerDB = EntityService:GetDatabase( self.markerEntity )
    --markerDB:SetString("message_text", "")
    --markerDB:SetInt("message_visible", 0)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( wallBlueprintName ) )

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

function wall_perimeter_tool:OnWorkExecute()

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

        --local isLogNeeded = (#oldLinesEntities ~= #newPositionsArray)

        --if ( isLogNeeded ) then
        --    LogService:Log("OnWorkExecute Start")
        --end

        for i=1,#newPositionsArray do

            local newPosition = newPositionsArray[i]

            local lineEnt = self:GetEntityFromGrid( oldGridEntities, newPosition.x, newPosition.z )

            if ( lineEnt == nil ) then

                lineEnt = EntityService:SpawnEntity( self.ghostBlueprint, newPosition, team )
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

            self:CheckEntityBuildable( lineEnt, transform, i )
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

function wall_perimeter_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then
    
        return nil
    end
    
    local arrayXPosition = gridEntities[newPositionX]
    
    if ( arrayXPosition[newPositionZ] == nil ) then
        
        return nil
    end

    return arrayXPosition[newPositionZ]
end

function wall_perimeter_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then
    
        gridEntities[newPositionX] = {}
    end
    
    local arrayXPosition = gridEntities[newPositionX]
    
    arrayXPosition[newPositionZ] = lineEnt
end

function wall_perimeter_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then
    
        return false
    end
    
    local hashXPosition = hashPositions[newPositionX]
    
    if ( hashXPosition[newPositionZ] == nil ) then
        
        return false
    end
    
    return true
end

function wall_perimeter_tool:FindPositionsToBuildLine( buildEndPosition, wallLinesConfig )

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

function wall_perimeter_tool:AddCornerPositions(wallLinesConfig, positionX, positionY, positionZ, xSign, zSign, deltaXZ, hashPositions, result)

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

function wall_perimeter_tool:AddNewPositionsByXArray(wallLinesConfig, arrayX, positionY, positionZ, zSign, deltaXZ, hashPositions, result)

    for xIndex=1,#arrayX do
                
        local positionX = arrayX[xIndex]
        
        local position = {}
                
        position.x = positionX
        position.y = positionY
        position.z = positionZ

        self:AddNewPositionsByConfigByZ(position, wallLinesConfig, zSign, deltaXZ, hashPositions, result)
    end
end

function wall_perimeter_tool:AddNewPositionsByZArray(wallLinesConfig, positionX, positionY, arrayZ, xSign, deltaXZ, hashPositions, result)

    for zIndex=1,#arrayZ do
                
        local positionZ = arrayZ[zIndex]
        
        local position = {}
                
        position.x = positionX
        position.y = positionY
        position.z = positionZ

        self:AddNewPositionsByConfigByX(position, wallLinesConfig, xSign, deltaXZ, hashPositions, result)
    end
end

function wall_perimeter_tool:AddNewPositionsByConfigByX(position, wallLinesConfig, xSign, deltaXZ, hashPositions, result)

    for step=1,#wallLinesConfig do

        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then

            local newPositionX = position.x + xSign * (step - 1) * deltaXZ
            
            self:AddNewPositionToResult(hashPositions, result, newPositionX, position.z, position.y)
        end
    end  
end

function wall_perimeter_tool:AddNewPositionsByConfigByZ(position, wallLinesConfig, zSign, deltaXZ, hashPositions, result)

    for step=1,#wallLinesConfig do
    
        local subStr = string.sub(wallLinesConfig, step, step)
    
        if ( subStr == "1" ) then
        
            local newPositionZ = position.z + zSign * (step - 1) * deltaXZ

            self:AddNewPositionToResult(hashPositions, result, position.x, newPositionZ, position.y)
        end
    end
end

function wall_perimeter_tool:FindGridArrays(buildStartPosition, buildEndPosition)

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

function wall_perimeter_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)
    
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
function wall_perimeter_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

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

function wall_perimeter_tool:GetXZSigns(positionStart, positionEnd)
                
    local xSign = -1
    local zSign = -1
    
    if( positionEnd.x >= positionStart.x ) then
        xSign = 1
    end
    
    if( positionEnd.z >= positionStart.z ) then
        zSign = 1
    end

    return xSign, zSign
end

function wall_perimeter_tool:CheckConfigExists( wallLinesConfig )

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

function wall_perimeter_tool:GetWallConfigArray()

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

        -- 8
        "10101011",

        -- 9
        "101010101",

        -- 10
        "1010101011",

        -- 11
        "10101010101"
    }

    return scaleWallLines
end

function wall_perimeter_tool:CheckEntityBuildable( entity, transform, id )
    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprintName, id )

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

function wall_perimeter_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall , false )
        
        local player = PlayerService:GetPlayerControlledEnt(0)
        self.positionPlayer = EntityService:GetPosition( player )

        self:OnWorkExecute()
    else
        self:FinishLineBuild()
    end
end

function wall_perimeter_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()
end

function wall_perimeter_tool:FinishLineBuild()

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

function wall_perimeter_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()
    
    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local scaleWallLines = self:GetWallConfigArray()

    local currentLinesConfig = self:CheckConfigExists(self.wallLinesConfig)
    
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

    self:OnWorkExecute()
end

function wall_perimeter_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

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

return wall_perimeter_tool