local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'floor_rebuilder_tool' ( tool )

function floor_rebuilder_tool:__init()
    tool.__init(self,self)
end

function floor_rebuilder_tool:OnPreInit()
    self.initialScale = { x=4, y=1, z=4 }
end

function floor_rebuilder_tool:GetScaleFromDatabase()
    return { x=4, y=1, z=4 }
end

function floor_rebuilder_tool:OnInit()
    self.baseSearch = false
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_floor_rebuilder_tool", self.entity)

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
end

function floor_rebuilder_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function floor_rebuilder_tool:FillWithFloors( blueprint, indexes )

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

            local pos = idxToPos[ idx ];
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
            QueueEvent( "BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function floor_rebuilder_tool:RebuildFloor()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    local hashGridsToErase = {}

    for xIndex=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xIndex]

        for zIndex=1,#gridEntitiesZ do

            local entity = gridEntitiesZ[zIndex]

            local gridToErase = FindService:GetEntityCellIndexes( entity )

            for i = 1,#gridToErase do

                local idx = gridToErase[i]

                hashGridsToErase[idx] = true
            end
        end
    end

    local toRecreate = {}

    local listSelledEntities = {}

    local entitiesBlueprints = {}

    for i = 1, #self.selectedEntities do

        local entityToSell = self.selectedEntities[i]

        if (entityToSell == nil or not EntityService:IsAlive( entityToSell) ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entityToSell, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode >= 3 ) then
                goto continue
            end
        end

        local gridCullerComponent = EntityService:GetComponent( entityToSell, "GridCullerComponent")
        local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
        if( gridCullerComponent == nil or entityBlueprint == "" ) then
            goto continue
        end

        local blueprintNameNormilized, countCells = self:GetNormilizedBlueprintName(entityBlueprint)

        entitiesBlueprints[blueprintNameNormilized] = entitiesBlueprints[blueprintNameNormilized] or 0

        entitiesBlueprints[blueprintNameNormilized] = entitiesBlueprints[blueprintNameNormilized] + countCells

        local gridCullerComponentHelper = reflection_helper(gridCullerComponent)

        local freeGrids = {}

        local indexes = gridCullerComponentHelper.terrain_cell_entities
        for i=indexes.count,1,-1 do

            local idx = indexes[i].id

            if ( hashGridsToErase[idx] == nil ) then

                Insert( freeGrids, idx )
            end
        end

        if ( #freeGrids > 0 ) then
            Insert( toRecreate, { ["bp"] = entityBlueprint, ["indexes"] = freeGrids } )
        end

        if ( IndexOf( listSelledEntities, entityToSell ) == nil ) then

            QueueEvent( "SellBuildingRequest", entityToSell, self.playerId, false )

            Insert( listSelledEntities, entityToSell )
        end

        ::continue::
    end

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end

    local frequentBlueptinName = self:FindFrequentBlueptint(entitiesBlueprints)

    local rebuildBlueptinName = self:FindBlueprint(frequentBlueptinName)

    for xIndex=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xIndex]

        for zIndex=1,#gridEntitiesZ do

            local entity = gridEntitiesZ[zIndex]

            local gridToErase = FindService:GetEntityCellIndexes( entity )

            self:FillWithFloors( rebuildBlueptinName, gridToErase )
        end
    end
end

function floor_rebuilder_tool:FindBlueprint(baseBlueprintName)

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

function floor_rebuilder_tool:FindFrequentBlueptint( entitiesBlueprints )

    local result = nil
    local resultCount = 0

    for blueprintName, count in pairs( entitiesBlueprints ) do

        if ( result == nil or count > resultCount ) then
            result = blueprintName
            resultCount = count
        end
    end

    return result
end

function floor_rebuilder_tool:GetNormilizedBlueprintName( blueprintName )

    local toReplace = 1

    if string.find( blueprintName, "4" ) then
        toReplace = 4
    elseif string.find( blueprintName, "3" ) then
        toReplace = 3
    elseif string.find( blueprintName, "2" ) then
        toReplace = 2
    end

    local count = toReplace * toReplace

    local currentBlueprint = string.gsub( blueprintName, tostring(toReplace), "1" )

    return currentBlueprint, count
end

function floor_rebuilder_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = {}

    for xIndex=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xIndex]

        for zIndex=1,#gridEntitiesZ do

            local entity = gridEntitiesZ[zIndex]

            local position = EntityService:GetPosition( entity )

            local boundsSize = { x=1.0, y=1.0, z=1.0 }

            local min = VectorSub(position, VectorMulByNumber(boundsSize, self.currentScale))
            local max = VectorAdd(position, VectorMulByNumber(boundsSize, self.currentScale))

            local tempSelected = FindService:FindGridMiscByBox( min, max )

            for tempEntity in Iter( tempSelected ) do

                if ( tempEntity ~= nil and IndexOf( possibleSelectedEnts, tempEntity ) == nil ) then
                   Insert( possibleSelectedEnts, tempEntity )
                end
            end
        end
    end

    local selectorPosition = selectorComponent.position

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b)
        return sorter(possibleSelectedEnts, a, b)
    end)

    local selectedEntities = {}

    for entity in Iter( possibleSelectedEnts ) do

        if ( IndexOf( selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= 3 ) then
            goto continue
        end

        Insert(selectedEntities, entity )

        ::continue::
    end

    return selectedEntities
end

function floor_rebuilder_tool:AddedToSelection( entity )
    local meshEntity = BuildingService:GetMeshEntity(entity);
    EntityService:SetMaterial( meshEntity, "selector/hologram_blue", "selected")
end

function floor_rebuilder_tool:RemovedFromSelection( entity )
    local meshEntity = BuildingService:GetMeshEntity(entity);
    EntityService:RemoveMaterial(meshEntity, "selected" )
end

function floor_rebuilder_tool:OnUpdate()

    local currentScale = EntityService:GetScale(self.entity).x

    if ( self.currentSize ~= currentScale ) then

        self.currentSize = currentScale

        self:StopBuildingGhosts()
    end

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local buildEndPosition = currentTransform.position

        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition )

        if ( self.gridEntities == nil ) then
            self.gridEntities = {}
        end

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

                    local lineEnt = EntityService:SpawnEntity("buildings/tools/eraser_1x1_ghost", newPosition, team )
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

                    local lineEnt = EntityService:SpawnEntity("buildings/tools/eraser_1x1_ghost", newPosition, team )
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

                local lineEnt = gridEntitiesZ[zIndex];
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)
            end
        end
    end






    self.sellCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function floor_rebuilder_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

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

function floor_rebuilder_tool:GetXZSigns(positionStart, positionEnd)

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

function floor_rebuilder_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity, false )

        self:OnUpdate()
    else
        self:RebuildFloor()

        self:StopBuildingGhosts()
    end
end

function floor_rebuilder_tool:OnDeactivate()

    self:RebuildFloor()

    self:StopBuildingGhosts()
end

function floor_rebuilder_tool:StopBuildingGhosts()

    self:ClearGridEntities()

    EntityService:SetVisible( self.entity, true )
    self.nowBuildingLine = false
    self.buildStartPosition = nil
end

function floor_rebuilder_tool:ClearGridEntities()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghost in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghost)
            end
        end
    end

    self.gridEntities = {}
end

function floor_rebuilder_tool:OnRelease()

    self:ClearGridEntities()

    self.nowBuildingLine = false
    self.buildStartPosition = nil

    self.currentSize = 0

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function floor_rebuilder_tool:OnRotate()
end

return floor_rebuilder_tool