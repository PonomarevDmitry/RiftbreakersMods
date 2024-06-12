require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'floor_tool' ( LuaEntityObject )

function floor_tool:__init()
    LuaEntityObject.__init(self,self)
end

function floor_tool:init()

    self:InitializeValues()
end

function floor_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )
    self.childPos = {}

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    local selectorDB = EntityService:GetDatabase( self.selector )

    if ( self.data:HasString("blueprintName") ) then

        self.floorBlueprintName = self.data:GetString("blueprintName")
    else

        local defaultFloor = self.data:GetString("defaultFloor")
        local lowName = self.data:GetString("lowName")

        local parameterName = "$selected_" .. lowName .. "_blueprint"

        self.floorBlueprintName = self:GetFloorBlueprintName( selectorDB, parameterName, defaultFloor )
    end

    self.linesEntities = {}

    self.currentSize = self.data:GetInt("size")

    self:CreateInfoChild()

    self.configNameCellCount = "$floor_tool_cell_count_" .. tostring(self.currentSize)

    self.cellCount = selectorDB:GetIntOrDefault(self.configNameCellCount, 0)
    self.cellCount = self:CheckCellCount(self.cellCount)

    self.currentCellCount = 0
    self.currentCellCountMarker = nil
    self.currentCellCountMarkerBlueprint = ""

    self:FillBuildingDesc()

    self:SpawnCornerBlueprint()

    self:SpawnGhostFloorEntities()
end

function floor_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function floor_tool:CheckCellCount( cellCount )

    cellCount = cellCount or 0

    if ( cellCount < 0) then
        cellCount = 0
    end

    return cellCount
end

function floor_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end


    local cellCount = self:CheckCellCount(self.cellCount)

    local newValue = cellCount + change

    if ( newValue < 0 ) then
        newValue = 0
    end

    self.cellCount = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameCellCount, newValue)

    self:SpawnGhostFloorEntities()
end

function floor_tool:CreateInfoChild()

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -self.currentSize, 0, self.currentSize)
    end
end

function floor_tool:GetFloorBlueprintName( selectorDB, parameterName, defaultFloor )

    local blueprintName = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultFloor)
    end

    if ( blueprintName == "" ) then
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
            blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultFloor)
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

function floor_tool:FillBuildingDesc()

    local blueprintName = EntityService:GetBlueprintName( self.entity )

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( blueprintName ) )

    self.ghostBlueprintName = buildingDesc.ghost_bp
    self.buildingDesc = buildingDesc
end

function floor_tool:SpawnGhostFloorEntities()

    local currentSize = self.currentSize
    local cellCount = self:CheckCellCount(self.cellCount)

    EntityService:SetScale( self.entity, currentSize, 1.0, currentSize )

    self:SetChildrenPosition()
    self:RescaleChild()

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local orientation = currentTransform.orientation

    local newPositions = self:FindPositionsToBuildLine( currentSize, cellCount )

    if ( #self.linesEntities > #newPositions ) then

        for i=#self.linesEntities,#newPositions + 1,-1 do
            local lineEnt = self.linesEntities[i]
            EntityService:RemoveEntity(lineEnt)
            self.linesEntities[i] = nil
        end

    elseif ( #self.linesEntities < #newPositions ) then

        for i=#self.linesEntities + 1 ,#newPositions do

            local lineEnt = self:SpawnGhostFloorEntity(newPositions[i], orientation, currentSize)

            Insert( self.linesEntities, lineEnt )
        end
    end

    Assert(#self.linesEntities == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#self.linesEntities) .. "/" .. tostring(#newPositions))

    for i=1,#newPositions do

        local transform = {}

        transform.scale = {x=1,y=1,z=1}
        transform.orientation = orientation
        transform.position = newPositions[i]

        local lineEnt = self.linesEntities[i]

        EntityService:SetPosition( lineEnt, newPositions[i])
        EntityService:SetOrientation( lineEnt, orientation )
        EntityService:SetScale( lineEnt, currentSize, 1.0, currentSize )
    end

    self:UpdateMarker(cellCount)
end

function floor_tool:RescaleChild()

    local scale = EntityService:GetScale( self.entity )

    scale.x = 1.0 / scale.x
    scale.z  = 1.0 / scale.z

    if ( self.corners ~= nil ) then
        EntityService:SetScale( self.corners,  scale.x, scale.y, scale.z )
    end
end

function floor_tool:SetChildrenPosition()

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

function floor_tool:UpdateMarker(cellCount)

    local currentScale = (cellCount + 1)

    if ( self.currentCellCount ~= currentScale ) then

        self.currentCellCount = currentScale

        local markerBlueprint = "misc/marker_selector_floor_size_" .. currentScale

        if ( currentScale > 16 ) then
            markerBlueprint = "misc/marker_selector_floor_size_g16"
        end

        if ( self.currentCellCountMarkerBlueprint ~= markerBlueprint or self.currentCellCountMarker == nil ) then

            -- Destroy old marker
            if (self.currentCellCountMarker ~= nil) then

                EntityService:RemoveEntity(self.currentCellCountMarker)
                self.currentCellCountMarker = nil
            end

            self.currentCellCountMarkerBlueprint = markerBlueprint

            self.currentCellCountMarker = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )
        end
    end
end

function floor_tool:SpawnGhostFloorEntity(position, orientation, currentSize)

    local lineEnt = EntityService:SpawnAndAttachEntity( self.ghostBlueprintName, self.selector )
    
    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )

    EntityService:RemoveComponent( lineEnt, "LuaComponent" )
    EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )

    EntityService:SetPosition( lineEnt, position )
    EntityService:SetOrientation( lineEnt, orientation )
    EntityService:SetScale( lineEnt, currentSize, 1.0, currentSize )

    return lineEnt
end

function floor_tool:FindPositionsToBuildLine(currentSize, cellCount)

    local result = {}

    if ( cellCount <= 0 ) then
        return result
    end

    local delta = currentSize * 2

    for indexX = 0,cellCount do
        for indexZ = 0,cellCount do

            if ( indexX ~= 0 or indexZ ~= 0 ) then

                local maxIndex = math.max(indexX, indexZ)
                local totalIndex = indexX + indexZ

                local newPosition = nil

                newPosition = {}
                newPosition.y = 0
                newPosition.x = indexX * delta
                newPosition.z = indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )

                if ( indexZ ~= 0 ) then

                    newPosition = {}
                    newPosition.y = 0
                    newPosition.x = indexX * delta
                    newPosition.z = - indexZ * delta

                    newPosition.maxIndex = maxIndex
                    newPosition.totalIndex = totalIndex

                    Insert( result, newPosition )
                end

                if ( indexX ~= 0 ) then

                    newPosition = {}
                    newPosition.y = 0
                    newPosition.x = - indexX * delta
                    newPosition.z = indexZ * delta

                    newPosition.maxIndex = maxIndex
                    newPosition.totalIndex = totalIndex

                    Insert( result, newPosition )
                end

                if ( indexX ~= 0 and indexZ ~= 0 ) then

                    newPosition = {}
                    newPosition.y = 0
                    newPosition.x = - indexX * delta
                    newPosition.z = - indexZ * delta

                    newPosition.maxIndex = maxIndex
                    newPosition.totalIndex = totalIndex

                    Insert( result, newPosition )
                end
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

    return result
end

function floor_tool:FillWithFloors( blueprint, indexes )

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
            QueueEvent( "BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function floor_tool:FinishLineBuild()

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        self:BuildFloorEntites(allEntities)
    end
end

function floor_tool:GetAllEntities()

    local result = {}

    Insert(result, self.entity)

    for index=1,#self.linesEntities do

        local entity = self.linesEntities[index]

        Insert(result, entity)
    end

    return result
end

function floor_tool:GetAllFreeGrids(floorEntities)

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

function floor_tool:BuildFloorEntites(floorEntities)

    local hashAllFreeGrids = self:GetAllFreeGrids(floorEntities)

    local listSelledEntities = {}

    for i=1,#floorEntities do

        local ghostEntity = floorEntities[i]

        local ghostTransform = EntityService:GetWorldTransform( ghostEntity )

        local test = BuildingService:CheckGhostFloorStatus( self.playerId, ghostEntity, ghostTransform, self.floorBlueprintName )

        if ( test ) then

            local testBuildable = reflection_helper(test:ToTypeInstance())

            self:BuildFloor( testBuildable, hashAllFreeGrids, listSelledEntities )
        end
    end
end

function floor_tool:BuildFloor(testBuildable, hashAllFreeGrids, listSelledEntities)

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

function floor_tool:FindBlueprint(baseBlueprintName)

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

function floor_tool:OnActivateSelectorRequest()

    self:FinishLineBuild()
end

function floor_tool:ClearGridEntities()

    if ( self.linesEntities ~= nil) then
        for ghost in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghost)
        end
    end
    self.linesEntities = {}
end

function floor_tool:OnRelease()

    self:ClearGridEntities()

    self.currentCellCount = 0
    self.currentCellCountMarkerBlueprint = ""

    if (self.currentCellCountMarker ~= nil) then

        EntityService:RemoveEntity(self.currentCellCountMarker)
        self.currentCellCountMarker = nil
    end

    self.currentSize = 0
end

return floor_tool