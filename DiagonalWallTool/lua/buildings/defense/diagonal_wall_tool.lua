require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

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

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )
    EntityService:SetVisible( self.entity, false )

    self.ghostWall = nil

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    self.wallBlueprint = self:GetWallBlueprint( selectorDB )

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self:SpawnWallTemplates()

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsCount = "$diagonal_wall_lines_count"

    -- Wall layers config
    self.wallLinesCount = selectorDB:GetIntOrDefault(self.configNameWallsCount, 1)
    self.wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    self.randomRotation = 0

    local database = EntityService:GetBlueprintDatabase( self.wallBlueprint )
    if ( database and database:HasInt("random_rotation") ) then

        self.randomRotation = database:GetIntOrDefault( "random_rotation", 0 )

        if ( self.randomRotation == 1 ) then

            local vector = { x=0, y=1, z=0 }

            self.randomOrientationArray = {
                CreateQuaternion( vector, 0 ),
                CreateQuaternion( vector, 90 ),
                CreateQuaternion( vector, 180 ),
                CreateQuaternion( vector, 270 )
            }
        end
    end
end

function diagonal_wall_tool:GetWallBlueprint( selectorDB )

    local defaultWall = "buildings/defense/wall_small_straight_01"

    local parameterName = "$selected_wall_small_blueprint"

    local blueprintName = ""


    local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

            blueprintName = globalPlayerEntityDB:GetStringOrDefault(parameterName, defaultWall)
        end
    end


    if ( blueprintName == "" ) then

        if ( selectorDB and selectorDB:HasString(parameterName) ) then

            blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultWall)
        end
    end


    if ( blueprintName == "" ) then

        if ( CampaignService.GetCampaignData ) then

            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultWall)
            end
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

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return defaultWall
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return defaultWall
    end

    return blueprintName
end

function diagonal_wall_tool:SpawnWallTemplates()

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( self.wallBlueprint ) )

    local transform = EntityService:GetWorldTransform( self.entity )

    local position = transform.position
    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local newPosition = EntityService:GetWorldTransform( self.entity ).position

    local buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.ghost_bp, self.selector )

    if ( EntityService:HasComponent( buildingEntity, "DisplayRadiusComponent" ) ) then
        EntityService:RemoveComponent( buildingEntity, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( buildingEntity, "GhostLineCreatorComponent" ) ) then
        EntityService:RemoveComponent( buildingEntity, "GhostLineCreatorComponent" )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

    self.ghostBlueprint = buildingDesc.ghost_bp

    self.buildingDesc = buildingDesc
    self.ghostWall = buildingEntity
end

function diagonal_wall_tool:GetGhostBlueprintByConnectType( connectType )

    for i=1,self.buildingDesc.connect.count do

        local connectRecord = self.buildingDesc.connect[i]

        if ( connectRecord.key == connectType and connectRecord.value.count > 0 ) then

            local connectBlueprintName = connectRecord.value[1]

            local buildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( connectBlueprintName ) )

            return connectBlueprintName, buildingDescRef.ghost_bp
        end
    end

    return self.buildingDesc.bp, self.buildingDesc.ghost_bp
end

function diagonal_wall_tool:GetGhostBlueprintByPosition(hashPositions, newPositionX, newPositionZ)

    local connectTypeStraight = 2
    local connectTypeCorner = 4
    local connectTypeT = 8
    local connectTypeX = 16

    local deltaXZ = 2

    local hasLeft = self:HashContains( hashPositions, newPositionX, newPositionZ - deltaXZ )
    local hasRight = self:HashContains( hashPositions, newPositionX, newPositionZ + deltaXZ )
    local hasTop = self:HashContains( hashPositions, newPositionX + deltaXZ, newPositionZ )
    local hasBottom = self:HashContains( hashPositions, newPositionX - deltaXZ, newPositionZ )

    local neiborsCount = 0

    if ( hasLeft ) then
        neiborsCount = neiborsCount + 1
    end
    if ( hasRight ) then
        neiborsCount = neiborsCount + 1
    end
    if ( hasTop ) then
        neiborsCount = neiborsCount + 1
    end
    if ( hasBottom ) then
        neiborsCount = neiborsCount + 1
    end

    local blueprintName = ""
    local ghostBlueprintName = ""
    local angle = 0

    if ( neiborsCount == 4 ) then
        blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeX)

        return blueprintName, ghostBlueprintName, angle
    end

    if ( neiborsCount == 3 ) then
        blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeT)

        if ( not hasBottom ) then
            angle = 0
        end

        if ( not hasTop ) then
            angle = 180
        end

        if ( not hasLeft ) then
            angle = 270
        end

        if ( not hasRight ) then
            angle = 90
        end

        return blueprintName, ghostBlueprintName, angle
    end

    if ( neiborsCount == 2 ) then

        if ( hasBottom and hasTop ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeStraight)

            angle = 0
        end

        if ( hasLeft and hasRight ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeStraight)

            angle = 90
        end





        if ( hasTop and hasLeft ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeCorner)

            angle = 90
        end

        if ( hasTop and hasRight ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeCorner)

            angle = 0
        end

        if ( hasBottom and hasLeft ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeCorner)

            angle = 180
        end

        if ( hasBottom and hasRight ) then

            blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeCorner)

            angle = 270
        end

        return blueprintName, ghostBlueprintName, angle
    end

    blueprintName, ghostBlueprintName = self:GetGhostBlueprintByConnectType(connectTypeStraight)

    if ( neiborsCount == 1 ) then

        if ( hasBottom) then
            angle = 0
        end

        if ( hasTop) then
            angle = 0
        end

        if ( hasLeft) then
            angle = 90
        end

        if ( hasRight) then
            angle = 90
        end

        return blueprintName, ghostBlueprintName, angle
    end

    return blueprintName, ghostBlueprintName, angle
end

function diagonal_wall_tool:OnWorkExecute()

    self.buildCost = {}

    -- Wall layers config
    local wallLinesCount = self.wallLinesCount

    wallLinesCount = self:CheckConfigExists(wallLinesCount)

    -- Correct Marker to show right number of wall layers
    if ( self.markerLinesConfig ~= wallLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local markerBlueprint = "misc/marker_selector_diagonal_wall_lines_" .. tostring( wallLinesCount )

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
        EntityService:SetPosition( self.currentMarkerLines, 0, 0, -2 )

        -- Save number of wall layers
        self.markerLinesConfig = wallLinesCount
    end

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.ghostWall )

        local buildEndPosition = currentTransform.position

        local newPositionsArray, hashPositions = self:FindPositionsToBuildLine( buildEndPosition, wallLinesCount )

        local oldLinesEntities = self.linesEntities
        local oldLinesEntityInfo = self.linesEntityInfo
        local oldGridEntities = self.gridEntities

        local newLinesEntities = {}
        local newLinesEntityInfo = {}
        local newGridEntities = {}

        if ( self.orientationArray == nil ) then

            local vector = { x=0, y=1, z=0 }

            self.orientationArray = {}

            self.orientationArray[0] = CreateQuaternion( vector, 0 )
            self.orientationArray[90] = CreateQuaternion( vector, 90 )
            self.orientationArray[180] = CreateQuaternion( vector, 180 )
            self.orientationArray[270] = CreateQuaternion( vector, 270 )
        end

        for i=1,#newPositionsArray do

            local newPosition = newPositionsArray[i]

            local lineEnt = self:GetEntityFromGrid( oldGridEntities, newPosition.x, newPosition.z )

            local blueprintName, ghostBlueprintName, angle = self:GetGhostBlueprintByPosition(hashPositions, newPosition.x, newPosition.z)

            local orientation = self.orientationArray[angle]

            if ( lineEnt == nil ) then

                lineEnt = EntityService:SpawnEntity( ghostBlueprintName, newPosition, team )

                if ( EntityService:HasComponent( lineEnt, "DisplayRadiusComponent" ) ) then
                    EntityService:RemoveComponent( lineEnt, "DisplayRadiusComponent" )
                end

                if ( EntityService:HasComponent( lineEnt, "GhostLineCreatorComponent" ) ) then
                    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )
                end
                self:ChangeEntityMaterial( lineEnt, "hologram/blue" )
                EntityService:RemoveComponent(lineEnt, "LuaComponent")

                EntityService:SetPosition( lineEnt, newPosition)
            end

            --local buildingComponent = reflection_helper(EntityService:GetComponent( lineEnt, "BuildingComponent" ))
            --buildingComponent.bp = blueprintName

            EntityService:SetOrientation( lineEnt, orientation )

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

        local list = BuildingService:GetBuildCosts( self.wallBlueprint, self.playerId )
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

function diagonal_wall_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        return nil
    end

    local arrayXPosition = gridEntities[newPositionX]

    if ( arrayXPosition[newPositionZ] == nil ) then

        return nil
    end

    return arrayXPosition[newPositionZ]
end

function diagonal_wall_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        gridEntities[newPositionX] = {}
    end

    local arrayXPosition = gridEntities[newPositionX]

    arrayXPosition[newPositionZ] = lineEnt
end

function diagonal_wall_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then

        return false
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        return false
    end

    return true
end

function diagonal_wall_tool:FindPositionsToBuildLine( buildEndPosition, wallLinesCount )

    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        positionPlayer = EntityService:GetPosition( player )
    end

    local hashPositions = {}

    local pathFromStartPositionToEndPosition = self:FindSingleDiagonalLine( self.buildStartPosition.position, buildEndPosition, positionPlayer )
    if ( wallLinesCount == 1 ) then

        for i=1,#pathFromStartPositionToEndPosition do

            local position = pathFromStartPositionToEndPosition[i]

            self:AddToHash( hashPositions, position.x, position.z )
        end

        return pathFromStartPositionToEndPosition, hashPositions
    end

    local x0 = self.buildStartPosition.position.x
    local z0 = self.buildStartPosition.position.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    self.coefX = (z1 - z0)
    self.coefZ = -(x1 - x0)
    self.const = x1*z0 - x0*z1

    local playerValue = self:CalcFunction( positionPlayer.x, positionPlayer.z )

    local newPositionX = x0 + self.coefX * 3
    local newPositionZ = z0 + self.coefZ * 3

    local secondValue = self:CalcFunction( newPositionX, newPositionZ )

    if ( secondValue * playerValue > 0 ) then

        newPositionX = x0 - self.coefX * 3
        newPositionZ = z0 - self.coefZ * 3
    end

    local endPositionMulti = {}
    endPositionMulti.x = newPositionX
    endPositionMulti.y = self.buildStartPosition.position.y
    endPositionMulti.z = newPositionZ

    local pathMulti = self:FindSingleDiagonalLine( self.buildStartPosition.position, endPositionMulti, positionPlayer )

    self:MakeRelativePath( pathMulti, x0, z0 )

    local multiWallsArray = self:GetPathWithNumberChanges( pathMulti, wallLinesCount - 1 )



    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        -- Add if position has not been added yet
        if ( self:AddToHash( hashPositions, position.x, position.z ) ) then

            table.insert(result, position)
        end

        for vector in Iter( multiWallsArray ) do

            local newPositionX = position.x + vector.x
            local newPositionZ = position.z + vector.z

            self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
        end
    end

    return result, hashPositions
end

function diagonal_wall_tool:GetPathWithNumberChanges( pathMulti, changesCount )

    if ( #pathMulti == 0 or #pathMulti == 1 ) then
        return pathMulti
    end

    local x0 = 0
    local z0 = 0

    local changesX = 0
    local changesZ = 0

    local index = 1
    local previousPosition = nil


    local result = {}

    local countCalcs = 0

    while ( true ) do

        local position = pathMulti[index]

        local newPositionX = x0 + position.x
        local newPositionZ = z0 + position.z

        local vector = {}
        vector.x = newPositionX
        vector.z = newPositionZ

        Insert( result, vector )

        if (previousPosition ~= nil) then

            if ( previousPosition.x ~= newPositionX ) then
                changesX = changesX + 1
            end

            if ( previousPosition.z ~= newPositionZ ) then
                changesZ = changesZ + 1
            end
        end

        if ( changesX >= changesCount or changesZ >= changesCount ) then
            break;
        end

        previousPosition = vector

        index = index + 1

        if ( index > #pathMulti ) then
            index = 2;

            x0 = newPositionX
            z0 = newPositionZ
        end

        countCalcs = countCalcs + 1

        if ( countCalcs > 50 ) then
            break
        end
    end

    return result
end

function diagonal_wall_tool:MakeRelativePath( pathMulti, x0, z0 )

    for position in Iter( pathMulti ) do

        local newPositionX = position.x - x0
        local newPositionZ = position.z - z0

        position.x = newPositionX
        position.z = newPositionZ
    end
end

function diagonal_wall_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:AddToHash(hashPositions, newPositionX, newPositionZ ) ) then
        return
    end

    local newPosition = {}
    newPosition.x = newPositionX
    newPosition.y = newPositionY
    newPosition.z = newPositionZ

    table.insert(result, newPosition)
end

-- Check position has not already been added to hashPositions
function diagonal_wall_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

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

function diagonal_wall_tool:CalcFunction( positionX, positionZ )

    local result = self.coefX * positionX + self.coefZ * positionZ + self.const

    if ( result > 0 ) then
        return 1
    elseif ( result < 0 ) then
        return -1
    end

    return 0
end

function diagonal_wall_tool:SetLineParameters( buildStartPosition, buildEndPosition )

    local x0 = buildStartPosition.x
    local z0 = buildStartPosition.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    self.coefX = (z1 - z0)
    self.coefZ = -(x1 - x0)
    self.const = x1*z0 - x0*z1

end

function diagonal_wall_tool:FindSingleDiagonalLine( buildStartPosition, buildEndPosition, positionPlayer )

    local xSignPlayer, zSignPlayer = self:GetXZSigns(positionPlayer, buildStartPosition)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local zPriority = (xSignPlayer * xSign) < 0 and (zSignPlayer * zSign) > 0

    local x0 = buildStartPosition.x
    local z0 = buildStartPosition.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    local deltaX = 2 * xSign
    local deltaZ = 2 * zSign

    local dx = math.abs(x1 - x0)
    local dz = -math.abs(z1 - z0)

    local dzAbs = math.abs(z1 - z0)

    local result = {}

    local positionY = buildStartPosition.y

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

function diagonal_wall_tool:CheckConfigExists( wallLinesCount )

    wallLinesCount = wallLinesCount or 1

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf( scaleWallLines, wallLinesCount )

    if ( index == nil ) then

        return scaleWallLines[1]
    end

    return wallLinesCount
end

function diagonal_wall_tool:GetWallConfigArray()

    local scaleWallLines = {
        1,
        2,
        3,
        4,
        5,
        6,
    }

    return scaleWallLines
end

function diagonal_wall_tool:CheckEntityBuildable( entity, transform, id )
    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprint, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper(test:ToTypeInstance(), test )

    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

    local materialToSet = "hologram/blue"

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then

            materialToSet = "hologram/pass"

        else

            materialToSet = "hologram/deny"
        end
    else
        if ( canBuildOverride ) then

            materialToSet = "hologram/active"

        elseif ( canBuild ) then

            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end
    end

    self:ChangeEntityMaterial( entity, materialToSet )

    return testBuildable
end

function diagonal_wall_tool:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function diagonal_wall_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall, false )

        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
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

    EntityService:SetVisible( self.ghostWall, true )

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
        if ( self.randomRotation == 1 ) then
            transform.orientation = self.randomOrientationArray[RandInt(1,4)]
        end
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghost, "BuildingComponent"))

        local testBuildable = self:CheckEntityBuildable( ghost, transform, i )

        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )

        elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

            QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
        end

        EntityService:RemoveEntity(ghost)
    end

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function diagonal_wall_tool:OnRotateSelectorRequest(evt)

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
    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameWallsCount, newValue)

    self:OnWorkExecute()
end

function diagonal_wall_tool:OnRelease()

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

return diagonal_wall_tool