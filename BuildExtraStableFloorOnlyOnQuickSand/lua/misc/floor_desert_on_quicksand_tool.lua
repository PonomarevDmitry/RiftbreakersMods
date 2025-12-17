local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'floor_desert_on_quicksand_tool' ( tool )

function floor_desert_on_quicksand_tool:__init()
    tool.__init(self,self)
end

function floor_desert_on_quicksand_tool:OnPreInit()
    self.initialScale = { x=4, y=1, z=4 }
end

function floor_desert_on_quicksand_tool:GetScaleFromDatabase()
    return { x=4, y=1, z=4 }
end

function floor_desert_on_quicksand_tool:OnInit()
    self.baseSearch = false
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_floor_desert_on_quicksand_tool", self.entity)

    self.scaleMap = {
        1,
        2,
        3,
        4,
    }

    self.nowBuildingLine = false
    self.buildStartPosition = nil
    self.gridEntities = {}
    self.currentSize = 0

    self.floorBlueprintName = "buildings/decorations/floor_desert_1x1"
end

function floor_desert_on_quicksand_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function floor_desert_on_quicksand_tool:FillWithFloors( blueprint, indexes )

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

            transform.scale = {x=replaced,y=1,z=replaced}

            QueueEvent( "BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function floor_desert_on_quicksand_tool:FinishLineBuild()

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

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function floor_desert_on_quicksand_tool:GetAllEntities()

    local result = {}

    for xIndex=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xIndex]

        for zIndex=1,#gridEntitiesZ do

            local entity = gridEntitiesZ[zIndex]

            Insert(result, entity)
        end
    end

    return result
end

function floor_desert_on_quicksand_tool:GetAllFreeGrids(floorEntities)

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

                local terrainType = self:GetTerrainType( idx )

                if ( terrainType == "quicksand" ) then

                    hashAllFreeGrids[idx] = true
                end
            end
        end
    end

    return hashAllFreeGrids
end

function floor_desert_on_quicksand_tool:BuildFloorEntites(floorEntities)

    local hashAllFreeGrids = self:GetAllFreeGrids(floorEntities)

    local count = #floorEntities

    local listSelledEntities = {}

    for i=1,count do

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

function floor_desert_on_quicksand_tool:BuildFloor(testBuildable, hashAllFreeGrids, listSelledEntities)

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

        local hasCellsToBuildFloor = false
        local freeGrids = {}

        local indexes = gridCullerComponentHelper.terrain_cell_entities
        for i=indexes.count,1,-1 do

            local idx = indexes[i].id

            if ( hashAllFreeGrids[idx] == nil ) then

                Insert( freeGrids, idx )
            else
                hasCellsToBuildFloor = true
            end
        end

        if ( not hasCellsToBuildFloor ) then
            goto continue
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

    --Assert( removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )

    local cellsToBuild = self:GetCellsToRebuild(testBuildable, hashAllFreeGrids)

    if ( #cellsToBuild > 0 ) then

        self:FillWithFloors( self:FindBlueprint(self.floorBlueprintName), cellsToBuild )
    end

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end
end

function floor_desert_on_quicksand_tool:GetCellsToRebuild(testBuildable, hashAllFreeGrids)

    local result = {}

    local indexes = testBuildable.free_grids

    local indexesCount = #indexes

    if ( indexesCount == 0 ) then
        indexesCount = indexes.count
    end

    for i = 1,indexesCount do

        local idx = indexes[i]

        if ( IndexOf( result, idx ) ~= nil ) then

            goto continue
        end

        if ( hashAllFreeGrids[idx] == true ) then

            Insert( result, idx )
        end

        ::continue::
    end

    return result
end

function floor_desert_on_quicksand_tool:GetTerrainType( terrainCellEntityId )

    local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

    if ( terrainTypeLayerComponent ~= nil ) then

        local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

        if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

            return terrainTypeLayerComponentRef.terrain_type.resource.name
        end
    end

    return ""
end

function floor_desert_on_quicksand_tool:FindBlueprint(baseBlueprintName)

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

function floor_desert_on_quicksand_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function floor_desert_on_quicksand_tool:AddedToSelection( entity )
end

function floor_desert_on_quicksand_tool:RemovedFromSelection( entity )
end

function floor_desert_on_quicksand_tool:OnUpdate()

    local currentScale = EntityService:GetScale(self.entity).x

    if ( self.currentSize ~= currentScale ) then

        self.currentSize = currentScale

        self:StopBuildingGhosts()
    end

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local buildEndPosition = currentTransform.position

        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition )

        self.gridEntities = self.gridEntities or {}

        local positionX, positionZ

        if ( #self.gridEntities > #arrayX ) then

            for xIndex=#self.gridEntities,#arrayX + 1,-1 do

                local gridEntitiesZ = self.gridEntities[xIndex]

                for zIndex=1,#gridEntitiesZ do

                    EntityService:RemoveEntity(gridEntitiesZ[zIndex])

                    gridEntitiesZ[zIndex] = nil
                end

                self.gridEntities[xIndex] = nil
            end

        elseif ( #self.gridEntities < #arrayX ) then

            for xIndex=#self.gridEntities + 1,#arrayX do

                positionX = arrayX[xIndex]

                local gridEntitiesZ = {}

                self.gridEntities[xIndex] = gridEntitiesZ

                for zIndex=1,#arrayZ do

                    positionZ = arrayZ[zIndex]

                    local newPosition = {}

                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = EntityService:SpawnEntity("buildings/decorations/floor_desert_on_quicksand_tool_ghost", newPosition, team )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        for xIndex=1,#arrayX do

            positionX = arrayX[xIndex]

            local gridEntitiesZ = self.gridEntities[xIndex]

            if ( #gridEntitiesZ > #arrayZ ) then

                for zIndex=#gridEntitiesZ,#arrayZ + 1,-1 do
                    EntityService:RemoveEntity(gridEntitiesZ[zIndex])
                    gridEntitiesZ[zIndex] = nil
                end

            elseif ( #gridEntitiesZ < #arrayZ ) then

                for zIndex=#gridEntitiesZ + 1,#arrayZ do

                    positionZ = arrayZ[zIndex]

                    local newPosition = {}

                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = EntityService:SpawnEntity("buildings/decorations/floor_desert_on_quicksand_tool_ghost", newPosition, team )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        for xIndex=1,#arrayX do

            positionX = arrayX[xIndex]

            local gridEntitiesZ = self.gridEntities[xIndex]

            for zIndex=1,#arrayZ do

                positionZ = arrayZ[zIndex]

                local newPosition = {}

                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ

                local transform = {}
                transform.scale = {x=1,y=1,z=1}
                transform.orientation = currentTransform.orientation
                transform.position = newPosition

                local lineEnt = gridEntitiesZ[zIndex]
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)
            end
        end

        local list = BuildingService:GetBuildCosts( self.floorBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
                self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ * currentScale * currentScale )
        end
    end


    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, self.buildCost )
    end
end

function floor_desert_on_quicksand_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)

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

function floor_desert_on_quicksand_tool:GetXZSigns(positionStart, positionEnd)

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

function floor_desert_on_quicksand_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity, false )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function floor_desert_on_quicksand_tool:OnDeactivate()

    self:FinishLineBuild()
end

function floor_desert_on_quicksand_tool:StopBuildingGhosts()

    self:ClearGridEntities()

    EntityService:SetVisible( self.entity, true )
    self.nowBuildingLine = false
    self.buildStartPosition = nil
end

function floor_desert_on_quicksand_tool:ClearGridEntities()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghost in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghost)
            end
        end
    end

    self.gridEntities = {}
end

function floor_desert_on_quicksand_tool:OnRelease()

    self:ClearGridEntities()

    self.nowBuildingLine = false
    self.buildStartPosition = nil

    self.currentSize = 0

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function floor_desert_on_quicksand_tool:OnRotateSelectorRequest( evt )

    local degree = evt:GetDegree()
    local currentScale = EntityService:GetScale(self.entity).x

    local maxIndex = #self.scaleMap
    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local index = IndexOf(self.scaleMap, currentScale )
    if ( index == nil ) then index = 1 end

    local newValue = index + change
    if ( newValue > maxIndex ) then
        newValue = maxIndex
    elseif( newValue == 0 ) then
        newValue = 1
    end
    self.currentScale = self.scaleMap[newValue]
    EntityService:SetScale( self.entity, self.currentScale, 1.0, self.currentScale)
    if ( self.OnRotate ) then
        self:OnRotate(degree)
    end

    self:SetChildrenPosition()
    self:RescaleChild()

end

return floor_desert_on_quicksand_tool