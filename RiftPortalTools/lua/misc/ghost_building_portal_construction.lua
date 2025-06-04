local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_portal_construction' ( ghost )

function ghost_building_portal_construction:__init()
    ghost.__init(self,self)
end

function ghost_building_portal_construction:FindMinDistance()
    self.radius = BuildingService:FindEnergyRadius( self.blueprint )
    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max(bounds.x, bounds.z ) / 2.0
    end
end

function ghost_building_portal_construction:OnInit()
    -- action line
    self.data:SetString("action", "portal_construction")

    self:FindMinDistance()
    
    self:RegisterHandler( INVALID_ID, "StartBuildingEvent", "OnBuildingStartEvent" )
    ShowBuildingDisplayRadiusAround( self.entity, self.blueprint )
end

function ghost_building_portal_construction:OnBuildingStartEvent( evt)

    local entity = evt:GetEntity()

    local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent")
    local owner = -1
    if (playerReferenceComponent) then
        local helper = reflection_helper(playerReferenceComponent)
        owner = helper.player_id
    end
    if ( owner ~= self.playerId or not self.activated) then
        return
    end

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( blueprintName == self.blueprint ) then

        local transform = EntityService:GetWorldTransform( entity )

        self:BuildDesertFloor(transform)
    end
end

function ghost_building_portal_construction:OnUpdate()
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform )

    if ( self.activated and self.buildPosition ~= nil ) then
        local currentPosition = EntityService:GetWorldTransform( self.entity )
        local spots = BuildingService:FindSpotsByDistance( self.buildPosition, currentPosition, self.radius, self.blueprint)
        for spot in Iter( spots ) do
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true )
            self.buildPosition = spot
        end
    end
end

function ghost_building_portal_construction:OnActivate()
    
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable =  self:GetBuildInfo(self.entity )

    self.buildPosition = transform

    if ( self.activated  ) then
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )

        elseif( testBuildable.flag == CBF_REPAIR ) then
            QueueEvent("RepairBuildingByPlayerRequest", testBuildable.entity_to_repair, self.playerId, -1 )
        end
    end
    
end

function ghost_building_portal_construction:OnDeactivate()
    self.buildPosition = nil
end

function ghost_building_portal_construction:OnRelease()
    HideBuildingDisplayRadiusAround( self.entity, self.blueprint )
end

function ghost_building_portal_construction:BuildDesertFloor(spot)

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"
    local antiQuickSandFloor2 = "buildings/decorations/floor_desert_2x2"

    if ( BuildingService:IsBuildingAvailable( self.playerId, antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then

        local buildDesertFloor, positions = self:ShouldBuildDesertFloor( spot.position )

        if ( buildDesertFloor ) then

            local transformFloor = {}
            transformFloor.position = spot.position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=2, y=1, z=2}

            local test = BuildingService:CheckGhostFloorStatus( self.playerId, self.entity, transformFloor, antiQuickSandFloor )

            if ( test ) then

                local testBuildable = reflection_helper(test:ToTypeInstance())

                self:BuildFloor( testBuildable, antiQuickSandFloor2 )
            end
        end
    end
end

function ghost_building_portal_construction:BuildFloor(testBuildable, antiQuickSandFloor2)
    local toRecreate ={}

    local removedCount =0
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
        local indexes = gridCullerComponentHelper.terrain_cell_entities
        local freeGrids = {}
        for i=indexes.count,1,-1 do 
            local add = true
            for j=1,testBuildable.free_grids.count do
                if ( testBuildable.free_grids[j] == indexes[i].id) then
                    add = false
                    break
                end
            end
            if (add ) then
                Insert(freeGrids, indexes[i].id )
            end
        end
        if ( #freeGrids > 0 ) then
            Insert(toRecreate, {["bp"]=entityBlueprint,["indexes"] = freeGrids })
        end

        removedCount = removedCount + 1
        QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        ::continue::
    end

    Assert(removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )

    self:FillWithFloors( antiQuickSandFloor2, testBuildable.free_grids )

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end 
end

function ghost_building_portal_construction:FillWithFloors( blueprint, indexes )
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

function ghost_building_portal_construction:ShouldBuildDesertFloor( position )

    local result = false

    local positions = {}

    local arrayDelta = { -1, 1 }

    for deltaX in Iter(arrayDelta) do

        for deltaZ in Iter(arrayDelta) do

            local newPosition = {}
            newPosition.x = position.x + deltaX
            newPosition.y = position.y
            newPosition.z = position.z + deltaZ

            Insert( positions, newPosition )

            if ( self:ShouldBuildDesertFloorOnCell( newPosition ) ) then
                
                result = true
            end
        end
    end

    return result, positions
end

function ghost_building_portal_construction:ShouldBuildDesertFloorOnCell( position )

    local terrainType = ""

    local overrideTerrains = {}

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(position)

    if ( terrainCellEntityId ~= nil and terrainCellEntityId ~= INVALID_ID ) then

        local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

        if ( terrainTypeLayerComponent ~= nil ) then

            local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

            if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

                terrainType = terrainTypeLayerComponentRef.terrain_type.resource.name
            end
        end

        local overrideTerrainComponent = EntityService:GetComponent( terrainCellEntityId, "OverrideTerrainComponent" )

        if ( overrideTerrainComponent ~= nil ) then

            local overrideTerrainComponentRef = reflection_helper(overrideTerrainComponent)

            if ( overrideTerrainComponentRef.terrain_overrides ) then

                for i=1,overrideTerrainComponentRef.terrain_overrides.count do

                    local terrainTypeHolder = overrideTerrainComponentRef.terrain_overrides[i]

                    if ( terrainTypeHolder and terrainTypeHolder.resource and terrainTypeHolder.resource.name ) then

                        if ( IndexOf( overrideTerrains, terrainTypeHolder.resource.name ) == nil ) then
                            Insert( overrideTerrains, terrainTypeHolder.resource.name )
                        end
                    end
                end
            end
        end
    end

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        return true
    end

    return false
end

return ghost_building_portal_construction
