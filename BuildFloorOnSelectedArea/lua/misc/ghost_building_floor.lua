local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")

class 'ghost_building_floor' ( ghost )

function ghost_building_floor:__init()
    ghost.__init(self,self)
end

function ghost_building_floor:FindMinDistance()
    self.radius = BuildingService:FindEnergyRadius( self.blueprint )
    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max(bounds.x, bounds.z )
    end
end

function ghost_building_floor:OnInit()
    self.data:SetString("action", "floor")

    local scale_x = self.data:GetFloatOrDefault("resize_scale_x", 4)
    local scale_y = self.data:GetFloatOrDefault("resize_scale_y", 1)
    local scale_z = self.data:GetFloatOrDefault("resize_scale_z", 4)
    EntityService:SetScale( self.entity, scale_x, scale_y, scale_z)

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self.nowBuildingLine = false
    self.gridEntities = {}
    
    self.currentSize = 0
    self.currentSizeMarker = nil
    self.currentSizeMarkerBlueprint = ""
end

function ghost_building_floor:FindBlueprint()
    local scale = EntityService:GetScale( self.entity )

    local next = 1 
    if ( scale.x > 4 ) then
        next = 4 
    else
        next = scale.x
    end
 
    for i=1,4 do
        local prevId = tostring(i)
        if ( string.find(self.blueprint, prevId)) then
            local currentId = tostring(next)
            local blueprint = string.gsub(self.blueprint, prevId, currentId )
            return blueprint
        end
    end

    return self.blueprint
end

function ghost_building_floor:FillWithFloors( blueprint, indexes )
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

                    local checkPos =  VectorAdd( currentPos, VectorMulByNumber(down, y))
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

    for replaced = 1,toReplace do
        local data = toCreate[replaced]
        if ( data == nil ) then goto continue2 end
        local currentBlueprint = string.gsub( blueprint, tostring(toReplace), tostring(replaced) )
        for vIdx = 1,#data do
            local v = data[vIdx]
            local transform = self.buildPosition
            transform.orientation = {x=0,y=0,z=0,w=1}
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
            transform.scale = {x=1,y=1,z=1}
            QueueEvent("BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function ghost_building_floor:BuildFloor(currentPosition, testBuildable, hashAllFreeGrids, listSelledEntities)

    local toRecreate = {}

    local removedCount = 0

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        --LogService:Log("Test: " .. tostring(i) .. "/" .. tostring(testBuildable.entities_to_sell.count ) .. ":" ..tostring(entityToSell))
        if (entityToSell == nil  ) then 
            --LogService:Log("Entity to sell nil!  do not remove! " ..tostring(entityToSell)  )
            goto continue 
        end
        if (not EntityService:IsAlive( entityToSell) ) then 
            --LogService:Log("Entity to sell not alive!  do not remove! " )
            goto continue 
        end
        local buildingComponent = EntityService:GetComponent( entityToSell, "BuildingComponent" )
        
        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode >= BM_SELLING ) then 
            --    LogService:Log("Mode: " .. tostring( mode ) .. ", do not remove!" )
                goto continue
             end 
        end

        local gridCullerComponent = EntityService:GetComponent( entityToSell, "GridCullerComponent")
        local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
        if( gridCullerComponent == nil or entityBlueprint == "" ) then 
           -- LogService:Log("No grid culler or entity blueprint! Do not remove!" )
            goto continue 
        end

        local gridCullerComponentHelper = reflection_helper(gridCullerComponent)
        local indexes = gridCullerComponentHelper.indexes
        local freeGrids = {}
        for i=indexes.count,1,-1 do 

            local idx = indexes[i]
            
            if ( hashAllFreeGrids[idx] == nil ) then

                Insert( freeGrids, idx )
            end
        end

        if ( #freeGrids > 0 ) then
            Insert(toRecreate, {["bp"]=entityBlueprint,["indexes"] = freeGrids })
        end

        removedCount = removedCount + 1

        if ( IndexOf( listSelledEntities, entityToSell ) == nil ) then 
            
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )

            Insert(listSelledEntities, entityToSell )
        end
        
        ::continue::
    end
    Assert(removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )
    self:FillWithFloors(self:FindBlueprint(), testBuildable.free_grids )

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end 

    self.buildPosition = currentPosition
end

function ghost_building_floor:OnUpdate()

    self.buildCost = {}
    
    local currentScale = EntityService:GetScale(self.entity).x
    
    if ( self.currentSize ~= currentScale ) then

        if ( self.gridEntities ~= nil) then
            for gridEntitiesZ in Iter(self.gridEntities) do
                for ghost in Iter(gridEntitiesZ) do
                    EntityService:RemoveEntity(ghost)
                end
            end
        end
        
        self.gridEntities = {}        
        self.nowBuildingLine = false
        self.buildStartPosition = nil
        
        EntityService:SetVisible( self.entity , true )
        
        self.currentSize = currentScale
        
        local markerBlueprint = "misc/marker_selector_floor_size_" .. currentScale
        
        if ( currentScale > 16 ) then        
            markerBlueprint = "misc/marker_selector_floor_size_g16"
        end
        
        if ( self.currentSizeMarkerBlueprint ~= markerBlueprint or self.currentSizeMarker == nil) then
    
            -- Destroy old marker
            if (self.currentSizeMarker ~= nil) then
            
                EntityService:RemoveEntity(self.currentSizeMarker)
                self.currentSizeMarker = nil
            end
            
            self.currentSizeMarker = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
        end
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
        
            for xIndex=#self.gridEntities + 1 ,#arrayX do
                
                positionX = arrayX[xIndex]
            
                local gridEntitiesZ = {}
                
                self.gridEntities[xIndex] = gridEntitiesZ
                
                for zIndex=1,#arrayZ do
                
                    positionZ = arrayZ[zIndex]
            
                    local newPosition = {}
                    
                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ
                
                    local lineEnt = EntityService:SpawnEntity(self.ghostBlueprint, newPosition, team )
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
            
                for zIndex=#gridEntitiesZ + 1 ,#arrayZ do
                
                    positionZ = arrayZ[zIndex]
            
                    local newPosition = {}
                    
                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ
                
                    local lineEnt = EntityService:SpawnEntity(self.ghostBlueprint, newPosition, team )
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
                
                local id = (xIndex -1 ) * #arrayX + zIndex
                
                self:CheckEntityBuildable(lineEnt, transform, true, id, true)
            end
        end

        local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ ) 
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        
        local testBuildable = self:CheckEntityBuildable( self.entity , currentTransform, true )        
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

function ghost_building_floor:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

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

function ghost_building_floor:GetXZSigns(positionStart, positionEnd)
                
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

function ghost_building_floor:OnActivate()

    if ( self.buildStartPosition == nil ) then
    
        self.nowBuildingLine = true;
    
        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )

        self:OnUpdate()
    else
        self:FinishLineBuild() 
    end    
end

function ghost_building_floor:FinishLineBuild()

    if ( self.nowBuildingLine == nil ) then
        self.nowBuildingLine = false
    end

    if ( self.nowBuildingLine ~= true ) then
    
        return
    end

    EntityService:SetVisible( self.entity , true )
    
    local allEntities = self:GetAllEntities()
    
    local count = #allEntities
    
    if ( count > 0 ) then
    
        local hashAllFreeGrids = self:GetAllFreeGrids(allEntities)
        
        self:BuildFloorEntites(allEntities, hashAllFreeGrids)
    end
    
    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function ghost_building_floor:GetAllEntities()

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

function ghost_building_floor:GetAllFreeGrids(floorEntities)

    local hashAllFreeGrids = {}

    local count = #floorEntities
    
    for i=1,count do
    
        local ghost = floorEntities[i]        
        
        local ghostTransform = EntityService:GetWorldTransform( ghost )
        
        local test = BuildingService:CheckGhostFloorStatus( self.playerId, ghost, ghostTransform, self.blueprint )
        
        local testBuildable = reflection_helper(test:ToTypeInstance())
        
        local indexesCount = testBuildable.free_grids.count
            
        for i = 1,indexesCount do
            
            local idx = testBuildable.free_grids[i]

            hashAllFreeGrids[idx] = true
        end
    end
    
    return hashAllFreeGrids
end

function ghost_building_floor:BuildFloorEntites(floorEntities, hashAllFreeGrids)

    local count = #floorEntities
            
    self.buildPosition = EntityService:GetWorldTransform( self.selector )
            
    local entityTransform = EntityService:GetWorldTransform( self.entity )

    local listSelledEntities = {}

    for i=1,count do
    
        local ghost = floorEntities[i]        
        
        local ghostTransform = EntityService:GetWorldTransform( ghost )
        
        local test = BuildingService:CheckGhostFloorStatus( self.playerId, ghost, ghostTransform, self.blueprint )
        
        local testBuildable = reflection_helper(test:ToTypeInstance())
        
        self:BuildFloor(entityTransform, testBuildable, hashAllFreeGrids, listSelledEntities )
    
        EntityService:RemoveEntity(ghost)
    end
end

function ghost_building_floor:OnDeactivate()
    self.buildPosition = nil
    
    self:FinishLineBuild()
end

function ghost_building_floor:OnRelease()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghost in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghost)
            end
        end
    end
    
    self.gridEntities = {}
    self.nowBuildingLine = false
    self.buildStartPosition = nil
    
    self.currentSize = 0
    self.currentSizeMarkerBlueprint = ""
    
    if (self.currentSizeMarker ~= nil) then        
    
        EntityService:RemoveEntity(self.currentSizeMarker)
        self.currentSizeMarker = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end
end

return ghost_building_floor
 