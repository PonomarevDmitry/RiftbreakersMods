require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'diagonal_wall_tool' ( LuaEntityObject )

function diagonal_wall_tool:__init()
    LuaEntityObject.__init(self,self)
end

function diagonal_wall_tool:init()
    
    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function diagonal_wall_tool:InitializeValues()

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

    self.buildStartPosition = nil
    self.positionPlayer = nil

    self.wallBlueprint = self:GetWallBlueprint()

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self:SpawnWallTemplates()

    -- Marker with number of wall layers
    self.markerLinesConfig = "0"
    self.currentMarkerLines = nil

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Wall layers config
    self.wallLinesConfig = selectorDB:GetStringOrDefault("wall_lines_config", "1")
    self.wallLinesConfig = self:CheckConfigExists(self.wallLinesConfig)
end

function diagonal_wall_tool:GetWallBlueprint()

    return "buildings/defense/wall_small_straight_01"
end

function diagonal_wall_tool:SpawnWallTemplates()

    --local markerDB = EntityService:GetDatabase( self.markerEntity )
    --markerDB:SetString("message_text", "")
    --markerDB:SetInt("message_visible", 0)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( self.wallBlueprint ) )

    LogService:Log( tostring(buildingDesc) )

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

function diagonal_wall_tool:OnWorkExecute()

    self.buildCost = {}

    -- Wall layers config
    local wallLinesConfig = self.wallLinesConfig
    
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

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)
        
        local currentTransform = EntityService:GetWorldTransform( self.ghostWall )

        local buildEndPosition = currentTransform.position

        local newPositions = self:FindPositionsToBuildLine( buildEndPosition, wallLinesConfig )

        if ( #self.linesEntities > #newPositions ) then
        
            for i=#self.linesEntities,#newPositions + 1,-1 do 
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end
            
        elseif ( #self.linesEntities < #newPositions ) then
        
            for i=#self.linesEntities + 1 ,#newPositions do

                local lineEnt = EntityService:SpawnEntity( self.ghostBlueprint, newPositions[i], team )
                EntityService:RemoveComponent(lineEnt, "LuaComponent")
                Insert(self.linesEntities, lineEnt)
            end
        end
        
        for i=1,#newPositions do

            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = newPositions[i]
            
            local entity = self.linesEntities[i]

            self:CheckEntityBuildable(entity, transform, i )
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

function diagonal_wall_tool:FindPositionsToBuildLine( buildEndPosition, wallLinesConfig )
    
    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(0)
        positionPlayer = EntityService:GetPosition( player )    
    end

    local pathFromStartPositionToEndPosition = self:FindSingleDiagonalLine( buildEndPosition, positionPlayer )
    if ( wallLinesConfig == "1" ) then
    
        return pathFromStartPositionToEndPosition    
    end

    local playerValue = self:CalcFunction( positionPlayer.x, positionPlayer.z )
    
    local deltaXZ = 2
            
    local wallLinesConfigLen = string.len( wallLinesConfig ) - 1

    local hashPositions = {}
    local result = {}

    local R2 = wallLinesConfigLen * wallLinesConfigLen

    for i=1,#pathFromStartPositionToEndPosition do
    
        local position = pathFromStartPositionToEndPosition[i]
        
        -- Add if position has not been added yet
        if ( not self:HashContains(hashPositions, position.x, position.z ) ) then
        
            table.insert(result, position)
        end

        for stepX=-wallLinesConfigLen,wallLinesConfigLen do

            local newPositionX = position.x + stepX * deltaXZ

            for stepZ=-wallLinesConfigLen,wallLinesConfigLen do

                local len = stepX * stepX + stepZ * stepZ

                if ( len <= R2 ) then
    
                    local newPositionZ = position.z + stepZ * deltaXZ

                    local positionValue = self:CalcFunction( newPositionX, newPositionZ )
            
                    if ( positionValue == 0 or positionValue * playerValue < 0 ) then

                        self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
                    end
                end
            end
        end
    end

    return result 
end

function diagonal_wall_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)
    
    -- Add if position has not been added yet
    if ( self:HashContains(hashPositions, newPositionX, newPositionZ ) ) then
        return
    end

    local newPosition = {}
    newPosition.x = newPositionX
    newPosition.y = newPositionY
    newPosition.z = newPositionZ

    table.insert(result, newPosition)
end

-- Check position has not already been added to hashPositions
function diagonal_wall_tool:HashContains(hashPositions, newPositionX, newPositionZ)

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

function diagonal_wall_tool:GetVectorOut(position, playerValue)
                
    for xSign in Iter( {1,-1} ) do

        for zSign in Iter( {1,-1} ) do

            local newPositionX = position.x + xSign * 10
            local newPositionZ = position.z + zSign * 10

            local positionValue = self:CalcFunction( newPositionX, newPositionZ )
            
            if ( positionValue * playerValue < 0 ) then

                return xSign, zSign
            end
        end 
    end    

    return 0, 0
end

function diagonal_wall_tool:CalcFunction( positionX, positionZ )

    local result = self.coefX * positionX + self.coefZ * positionZ + self.const

    if ( result > 0 ) then
        return 1
    elseif ( result < 0 ) then
        return -1
    end

    return 0
end

function diagonal_wall_tool:FindSingleDiagonalLine( buildEndPosition, positionPlayer )

    local xSignPlayer, zSignPlayer = self:GetXZSigns(positionPlayer, self.buildStartPosition.position)
    
    local xSign, zSign = self:GetXZSigns(self.buildStartPosition.position, buildEndPosition)

    local zPriority = (xSignPlayer * xSign) < 0 and (zSignPlayer * zSign) > 0

    local x0 = self.buildStartPosition.position.x
    local z0 = self.buildStartPosition.position.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    local deltaX = 2 * xSign
    local deltaZ = 2 * zSign

    self.coefX = (z1 - z0)
    self.coefZ = -(x1 - x0)
    self.const = x1*z0 - x0*z1

    local dx = math.abs(x1 - x0)
    local dz = -math.abs(z1 - z0)

    local dzAbs = math.abs(z1 - z0)

    local result = {}

    local positionY = self.buildStartPosition.position.y

    local positionX = x0
    local positionZ = z0

    local error = dx + dz

    while ( true ) do
    
        local position = {}

        position.x = positionX
        position.y = positionY
        position.z = positionZ

        Insert(result, position)

        if ( positionX == x1 and positionZ == z1 ) then
            break
        end

        local errorMul2 = 2 * error

        if ( zPriority ) then

            if ( errorMul2 <= dx ) then
                if ( positionZ == z1 ) then
                    break
                end
                error = error +  dx
                positionZ = positionZ + deltaZ
                goto continue
            end

            if ( errorMul2 >= dz ) then
                if positionX == x1 then
                    break
                end
                error = error + dz
                positionX = positionX + deltaX
                goto continue
            end
        else

            if ( errorMul2 >= dz ) then
                if positionX == x1 then
                    break
                end
                error = error + dz
                positionX = positionX + deltaX
                goto continue
            end

            if ( errorMul2 <= dx ) then
                if ( positionZ == z1 ) then
                    break
                end
                error = error +  dx
                positionZ = positionZ + deltaZ
                goto continue
            end
        end
            
        ::continue::
    end

    return result
end

function diagonal_wall_tool:GetXZSigns(positionStart, positionEnd, playerValue)
                
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

function diagonal_wall_tool:CheckConfigExists( wallLinesConfig )

    local scaleWallLines = self:GetWallConfigArray()
    
    local index = IndexOf(scaleWallLines, wallLinesConfig )
    
    if ( index == nil ) then 
    
        return "1"
    end
    
    return wallLinesConfig
end

function diagonal_wall_tool:GetWallConfigArray()

    local scaleWallLines = {
        -- 1
        "1",
        
        -- 2
        "11",
        
        -- 3
        "111",
        
        -- 4
        "1111",
        
        -- 5
        "11111",
        
        -- 6
        "111111",
    }

    return scaleWallLines
end

function diagonal_wall_tool:CheckEntityBuildable( entity, transform, id )
    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprint, id)

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

function diagonal_wall_tool:OnActivateSelectorRequest()

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

function diagonal_wall_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()
end

function diagonal_wall_tool:FinishLineBuild()

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
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function diagonal_wall_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local scaleWallLines = self:GetWallConfigArray()

    local currentLinesConfig = self.wallLinesConfig
    currentLinesConfig = self:CheckConfigExists(currentLinesConfig)
    
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

    self.wallLinesConfig = newValue

    -- Wall layers config
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetString("wall_lines_config", newValue)

    self:OnWorkExecute()
end

function diagonal_wall_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}

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

return diagonal_wall_tool