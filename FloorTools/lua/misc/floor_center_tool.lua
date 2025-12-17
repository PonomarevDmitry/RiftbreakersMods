require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'floor_center_tool' ( LuaEntityObject )

function floor_center_tool:__init()
    LuaEntityObject.__init(self,self)
end

function floor_center_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function floor_center_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )
    self.childPos = {}

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    if ( self.data:HasString("blueprintName") ) then

        self.floorBlueprintName = self.data:GetString("blueprintName")
    else

        local defaultFloor = self.data:GetString("defaultFloor")
        local lowName = self.data:GetString("lowName")

        local parameterName = "$selected_" .. lowName .. "_blueprint"

        self.floorBlueprintName = self:GetFloorBlueprintName( selectorDB, parameterName, defaultFloor )
    end

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.buildStartTransform = nil
    self.positionCenterMarker = nil

    self.configNameSize = "$floor_center_tool_size"

    self.currentSize = selectorDB:GetIntOrDefault(self.configNameSize, 4)
    self.currentSize = self:CheckSize(self.currentSize)

    EntityService:SetScale( self.entity, self.currentSize, 1.0, self.currentSize)

    self:FillBuildingDesc()

    self:SpawnCornerBlueprint()

    self:SetChildrenPosition()
    self:RescaleChild()

    self.currentMarkerSize = 0
    self.currentMarker = nil
    self.currentMarkerBlueprint = ""

    self:UpdateMarker()

    self:CreateInfoChild()
end

function floor_center_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function floor_center_tool:OnWorkExecute()

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartTransform ) then

        local currentSize = EntityService:GetScale(self.entity).x

        local positionY = self.buildStartTransform.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local orientation = currentTransform.orientation

        local buildEndPosition = currentTransform.position

        local newPositionsArray, hashPositions = self:FindPositionsToBuildLine( self.buildStartTransform.position, buildEndPosition, currentSize )

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

                lineEnt = self:SpawnGhostFloorEntity(newPosition, orientation, currentSize, team)
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

        self.linesEntities = newLinesEntities
        self.linesEntityInfo = newLinesEntityInfo
        self.gridEntities = newGridEntities

        Assert(#self.linesEntities == #newPositionsArray, "ERROR: something wrong with line positioning: " .. tostring(#self.linesEntities) .. "/" .. tostring(#newPositionsArray))

        local id = 1

        for i=1,#newPositionsArray do

            local transform = {}

            local newPosition = newPositionsArray[i]

            transform.scale = {x=1,y=1,z=1}
            transform.orientation = orientation
            transform.position = newPosition

            local lineEnt = self.linesEntities[i]

            EntityService:SetPosition( lineEnt, newPosition)
            EntityService:SetOrientation( lineEnt, orientation )
            EntityService:SetScale( lineEnt, currentSize, 1.0, currentSize )

            --self:CheckEntityBuildable(lineEnt, transform, true, id, true)

            id = id + 1
        end

        local list = BuildingService:GetBuildCosts( self.floorBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
        end
    else

        --local currentTransform = EntityService:GetWorldTransform( self.entity )
        --local testBuildable = self:CheckEntityBuildable( self.entity, currentTransform )

        --BuildingService:CheckAndFixBuildingConnection(self.ghostWall)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function floor_center_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        return nil
    end

    local arrayXPosition = gridEntities[newPositionX]

    return arrayXPosition[newPositionZ]
end

function floor_center_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        gridEntities[newPositionX] = {}
    end

    local arrayXPosition = gridEntities[newPositionX]

    arrayXPosition[newPositionZ] = lineEnt
end

function floor_center_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then

        return false
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        return false
    end

    return true
end

function floor_center_tool:CheckSize( size )

    size = size or 4

    if ( size < 1) then
        size = 1
    elseif ( size >= 4 ) then
        size = 4
    end

    return size
end

function floor_center_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end


    local size = self:CheckSize(self.currentSize)

    local newValue = size + change

    newValue = self:CheckSize(newValue)

    self.currentSize = newValue

    EntityService:SetScale( self.entity, self.currentSize, 1.0, self.currentSize)

    EntityService:SetPosition( self.infoChild, -self.currentSize, 0, self.currentSize)

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameSize, newValue)

    self:SetChildrenPosition()
    self:RescaleChild()

    self:UpdateMarker()

    EntityService:SetVisible( self.entity , true )

    self:ClearGridEntities()
    self.buildStartTransform = nil
    self.nowBuildingLine = false

    self:DestroyPositionCenterMarker()
end

function floor_center_tool:DestroyPositionCenterMarker()

    if ( self.positionCenterMarker ~= nil ) then
        EntityService:RemoveEntity( self.positionCenterMarker )
        self.positionCenterMarker = nil
    end
end

function floor_center_tool:CreateInfoChild()

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -self.currentSize, 0, self.currentSize)
    end
end

function floor_center_tool:GetFloorBlueprintName( selectorDB, parameterName, defaultFloor )

    local blueprintName = ""


    local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

            blueprintName = globalPlayerEntityDB:GetStringOrDefault(parameterName, defaultFloor)
        end
    end


    if ( blueprintName == "" ) then

        if ( selectorDB and selectorDB:HasString(parameterName) ) then

            blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultFloor)
        end
    end


    if ( blueprintName == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultFloor)
            end
        end
    end

    if ( blueprintName == "" ) then
        return defaultFloor
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultFloor
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultFloor
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultFloor
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return defaultFloor
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return defaultFloor
    end

    return blueprintName
end

function floor_center_tool:FillBuildingDesc()

    local buildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( self.floorBlueprintName ) )

    self.ghostBlueprintName = buildingDescRef.ghost_bp
    self.buildingDescRef = buildingDescRef
end

function floor_center_tool:RescaleChild()

    local scale = EntityService:GetScale( self.entity )

    scale.x = 1.0 / scale.x
    scale.z = 1.0 / scale.z

    if ( self.corners ~= nil ) then
        EntityService:SetScale( self.corners,  scale.x, scale.y, scale.z )
    end
end

function floor_center_tool:SetChildrenPosition()

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local diagonal = VectorMulByNumber(boundsSize , self.currentSize)
    diagonal.y = 1

    local children = EntityService:GetChildren( self.corners, true )
    for child in Iter( children ) do

        local childPos = EntityService:GetLocalPosition(child)
        if ( self.childPos[child] == nil ) then
            self.childPos[child] = childPos
        else
            childPos = self.childPos[child]
        end
        childPos = VectorMul(childPos, diagonal)
        EntityService:SetPosition(child,childPos)
    end
end

function floor_center_tool:UpdateMarker()

    local currentSize = self.currentSize

    if ( self.currentMarkerSize == currentScale ) then

        return
    end

    self.currentMarkerSize = currentSize

    local markerBlueprint = "misc/marker_selector_floor_number_" .. tostring(currentSize)

    if ( self.currentMarkerBlueprint ~= markerBlueprint or self.currentMarker == nil ) then

        -- Destroy old marker
        if (self.currentMarker ~= nil) then

            EntityService:RemoveEntity(self.currentMarker)
            self.currentMarker = nil
        end

        self.currentMarkerBlueprint = markerBlueprint

        self.currentMarker = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

        EntityService:SetPosition( self.currentMarker, 0, 0, -0.3 )
    end
end

function floor_center_tool:SpawnGhostFloorEntity(position, orientation, currentSize, team)

    local lineEnt = EntityService:SpawnEntity( self.ghostBlueprintName, position, team )
    
    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )

    EntityService:RemoveComponent( lineEnt, "LuaComponent" )
    self:ChangeEntityMaterial( lineEnt, "hologram/blue" )

    EntityService:SetPosition( lineEnt, position )
    EntityService:SetOrientation( lineEnt, orientation )
    EntityService:SetScale( lineEnt, currentSize, 1.0, currentSize )

    return lineEnt
end

function floor_center_tool:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function floor_center_tool:FindPositionsToBuildLine( buildCenterPoint, buildSelectedPoint, currentSize )

    local delta = currentSize * 2


    

    local xSign, zSign = self:GetXZSigns(buildCenterPoint, buildSelectedPoint)

    local deltaX = delta * xSign
    local deltaZ = delta * zSign

    local smallDeltaX = (delta * xSign) / 4
    local smallDeltaZ = (delta * zSign) / 4

    local buildEndPositionX = buildSelectedPoint.x + smallDeltaX
    local buildEndPositionZ = buildSelectedPoint.z + smallDeltaZ

    local minX = math.min( buildCenterPoint.x, buildEndPositionX )
    local maxX = math.max( buildCenterPoint.x, buildEndPositionX )

    local minZ = math.min( buildCenterPoint.z, buildEndPositionZ )
    local maxZ = math.max( buildCenterPoint.z, buildEndPositionZ )

    local countX = 0

    local positionX = buildCenterPoint.x

    while (minX <= positionX + deltaX and positionX + deltaX <= maxX) do

        countX = countX + 1

        positionX = positionX + deltaX
    end

    local countZ = 0

    local positionZ = buildCenterPoint.z

    while (minZ <= positionZ + deltaZ and positionZ + deltaZ <= maxZ) do

        countZ = countZ + 1

        positionZ = positionZ + deltaZ
    end


    
    

    local newPosition = nil

    local result = {}

    for indexX = 0,countX do
        for indexZ = 0,countZ do

            local maxIndex = math.max(indexX, indexZ)
            local totalIndex = indexX + indexZ

            newPosition = {}
            newPosition.y = 0
            newPosition.x = indexX * deltaX + buildCenterPoint.x
            newPosition.z = indexZ * deltaZ + buildCenterPoint.z

            newPosition.maxIndex = maxIndex
            newPosition.totalIndex = totalIndex

            Insert( result, newPosition )

            if ( indexZ ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = indexX * deltaX + buildCenterPoint.x
                newPosition.z = - indexZ * deltaZ + buildCenterPoint.z

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end

            if ( indexX ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = - indexX * deltaX + buildCenterPoint.x
                newPosition.z = indexZ * deltaZ + buildCenterPoint.z

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end

            if ( indexX ~= 0 and indexZ ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = - indexX * deltaX + buildCenterPoint.x
                newPosition.z = - indexZ * deltaZ + buildCenterPoint.z

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end
        end
    end

    local sorter = function( position1, position2 )

        if (position1.maxIndex ~= position2.maxIndex) then

            return position1.maxIndex < position2.maxIndex
        end

        if (position1.totalIndex ~= position2.totalIndex) then

            return position1.totalIndex < position2.totalIndex
        end

        if (position1.x ~= position2.x) then

            return position1.x < position2.x
        end

        return position1.z < position2.z
    end

    table.sort(result, sorter)

    local hashPositions = {}

    for position in Iter(result) do

        hashPositions[position.x] = hashPositions[position.x] or {}

        hashPositions[position.x][position.z] = true
    end

    return result, hashPositions
end

function floor_center_tool:GetXZSigns(positionStart, positionEnd)

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

function floor_center_tool:FillWithFloors( blueprint, indexes )

    local toReplace = 1

    if string.find( blueprint, "4" ) then
        toReplace = 4
    elseif string.find( blueprint, "3" ) then
        toReplace = 3
    elseif string.find( blueprint, "2" ) then
        toReplace = 2
    end

    local idxToPos = {}
    local storage = {}
    local indexesCount = #indexes

    if ( indexesCount == 0 ) then
        indexesCount = indexes.count
    end

    indexesCount = indexesCount or 0
    if ( indexesCount == 0 ) then
        return
    end

    for i = 1,indexesCount do
        local idx = indexes[i]

        local pos = FindService:GetCellOrigin(idx)

        idxToPos[idx] = pos
        storage[idx] = pos
    end

    local sorter = function(k1,k2)
        local p1 = idxToPos[k1]
        local p2 = idxToPos[k2]
        if ( p1.z < p2.z ) then
            return true
        elseif( p1.z == p2.z and p1.x < p2.x) then
            return true
        end
        return false
    end

    table.sort( indexes, sorter )

    local right = {x=2,y=0,z=0}
    local down = {x=0,y=0,z=2}

    local toCreate = {{}}

    for s=toReplace,0,-1 do
        local i = 1
        while i <= indexesCount do

            local idx = indexes[i]
            if (idxToPos[idx] == nil ) then i = i + 1 goto continue end

            toUse = {}

            local pos = idxToPos[ idx ]
            for x=0,s-1 do
                local currentPos = VectorAdd( pos, VectorMulByNumber(right, x))
                for y=0,s-1 do

                    local checkPos = VectorAdd( currentPos, VectorMulByNumber(down, y))
                    for testIdx,testPos in pairs(idxToPos) do
                        if ( testPos.x == checkPos.x and testPos.z == checkPos.z) then
                            Insert(toUse, testIdx)
                            break
                        end
                    end
                end
            end

            if ( #toUse == s * s ) then
                if( toCreate[s] == nil ) then toCreate[s] = {} end

                table.insert(toCreate[s], toUse)
                for idx in Iter(toUse) do
                    idxToPos[idx] = nil
                end
                i = 1
            else
                i = i + 1
            end
            ::continue::
        end
    end

    local transform = EntityService:GetWorldTransform(self.entity)
    transform.scale = {x=1,y=1,z=1}

    for replaced = 1,toReplace do
        local data = toCreate[replaced]
        if ( data == nil ) then goto continue2 end
        local currentBlueprint = string.gsub( blueprint, tostring(toReplace), tostring(replaced) )
        for vIdx = 1,#data do
            local v = data[vIdx]
            local infoPos = storage[v[1]]

            if ( replaced == 1 ) then
                transform.position = infoPos
            elseif( replaced == 2 ) then
                local position = infoPos
                position = VectorAdd(position, {x=1,y=0,z=1})
                transform.position = position
            elseif ( replaced == 3 ) then
                transform.position = storage[v[5]]
            else
                local position = infoPos
                position = VectorAdd(position, {x=3,y=0,z=3})
                transform.position = position
            end
            transform.scale = {x=replaced,y=replaced,z=replaced}
            QueueEvent( "BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function floor_center_tool:FinishLineBuild()

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    EntityService:SetVisible( self.entity , true )

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        self:BuildFloorEntites(allEntities)
    end

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
    self.buildStartTransform = nil
    self.nowBuildingLine = false

    self:DestroyPositionCenterMarker()
end

function floor_center_tool:GetAllEntities()

    local result = {}

    for index=1,#self.linesEntities do

        local entity = self.linesEntities[index]

        Insert(result, entity)
    end

    return result
end

function floor_center_tool:GetAllFreeGrids(floorEntities)

    local hashAllFreeGrids = {}

    local count = #floorEntities

    for i=1,count do

        local ghostEntity = floorEntities[i]

        local ghostTransform = EntityService:GetWorldTransform( ghostEntity )

        local test = BuildingService:CheckGhostFloorStatus( self.playerId, ghostEntity, ghostTransform, self.floorBlueprintName )

        if ( test ) then

            local testBuildable = reflection_helper(test:ToTypeInstance())

            local indexesCount = testBuildable.free_grids.count

            for i = 1,indexesCount do

                local idx = testBuildable.free_grids[i]

                hashAllFreeGrids[idx] = true
            end
        end
    end

    return hashAllFreeGrids
end

function floor_center_tool:BuildFloorEntites(floorEntities)

    local hashAllFreeGrids = self:GetAllFreeGrids(floorEntities)

    local listSelledEntities = {}

    for i=1,#floorEntities do

        local ghostEntity = floorEntities[i]

        local ghostTransform = EntityService:GetWorldTransform( ghostEntity )

        local test = BuildingService:CheckGhostFloorStatus( self.playerId, ghostEntity, ghostTransform, self.floorBlueprintName )

        if ( test ) then

            local testBuildable = reflection_helper(test:ToTypeInstance())

            self:BuildFloor( testBuildable, hashAllFreeGrids, listSelledEntities )

            EntityService:RemoveEntity(ghostEntity)
        end
    end
end

function floor_center_tool:BuildFloor(testBuildable, hashAllFreeGrids, listSelledEntities)

    local toRecreate = {}

    local removedCount = 0

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell == nil ) then
            goto continue
        end
        if ( not EntityService:IsAlive( entityToSell ) ) then
            goto continue
        end
        local buildingComponent = EntityService:GetComponent( entityToSell, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode >= BM_SELLING ) then
                goto continue
             end
        end

        local gridCullerComponent = EntityService:GetComponent( entityToSell, "GridCullerComponent" )
        local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
        if( gridCullerComponent == nil or entityBlueprint == "" ) then
            goto continue
        end

        local gridCullerComponentHelper = reflection_helper(gridCullerComponent)

        local freeGrids = {}

        local indexes = gridCullerComponentHelper.terrain_cell_entities
        for i=indexes.count,1,-1 do

            local idx = indexes[i].id

            if ( hashAllFreeGrids[idx] == nil ) then

                Insert( freeGrids, idx )
            end
        end

        if ( #freeGrids > 0 ) then
            Insert( toRecreate, { ["bp"] = entityBlueprint, ["indexes"] = freeGrids } )
        end

        if ( IndexOf( listSelledEntities, entityToSell ) == nil ) then

            removedCount = removedCount + 1

            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )

            Insert( listSelledEntities, entityToSell )
        end

        ::continue::
    end

    Assert( removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )

    self:FillWithFloors( self:FindBlueprint(self.floorBlueprintName), testBuildable.free_grids )

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end
end

function floor_center_tool:FindBlueprint(baseBlueprintName)

    local scale = EntityService:GetScale( self.entity )

    local next = 1
    if ( scale.x > 4 ) then
        next = 4
    else
        next = scale.x
    end

    for i=1,4 do

        local prevId = tostring(i)

        if ( string.find(baseBlueprintName, prevId) ) then

            local currentId = tostring(next)
            local blueprint = string.gsub( baseBlueprintName, prevId, currentId )
            return blueprint
        end
    end

    return baseBlueprintName
end

function floor_center_tool:OnActivateSelectorRequest()

    if ( self.buildStartTransform == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartTransform = transform
        EntityService:SetVisible( self.entity , false )

        self.positionCenterMarker = EntityService:SpawnEntity( "effects/multilayeredwalls_markers/objective_marker", self.buildStartTransform.position, EntityService:GetTeam(self.entity) )

        self:OnWorkExecute()
    else
        self:FinishLineBuild()
    end
end

function floor_center_tool:OnDeactivateSelectorRequest()

    self:FinishLineBuild()
end

function floor_center_tool:ClearGridEntities()

    if ( self.linesEntities ~= nil) then
        for ghost in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghost)
        end
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
end

function floor_center_tool:OnRelease()

    self:ClearGridEntities()

    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    self:DestroyPositionCenterMarker()

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if (self.currentMarker ~= nil) then
        EntityService:RemoveEntity(self.currentMarker)
        self.currentMarker = nil
    end

    self.currentSize = 0
end

return floor_center_tool