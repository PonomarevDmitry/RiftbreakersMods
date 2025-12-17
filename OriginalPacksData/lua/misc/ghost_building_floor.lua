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

    local scale_x = self.data:GetFloatOrDefault("resize_scale_x", 8)
    local scale_y = self.data:GetFloatOrDefault("resize_scale_y", 1)
    local scale_z = self.data:GetFloatOrDefault("resize_scale_z", 8)
    EntityService:SetScale( self.entity, scale_x, scale_y, scale_z)

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

function ghost_building_floor:BuildFloor(currentPosition, testBuildable)
    --local toRecreate ={}
--
    --local removedCount =0
    --local buildingToSellCount = testBuildable.entities_to_sell.count
    --for i = 1,buildingToSellCount do
    --    local entityToSell = testBuildable.entities_to_sell[i]
    --    --LogService:Log("Test: " .. tostring(i) .. "/" .. tostring(testBuildable.entities_to_sell.count ) .. ":" ..tostring(entityToSell))
    --    if (entityToSell == nil  ) then 
    --        --LogService:Log("Entity to sell nil!  do not remove! " ..tostring(entityToSell)  )
    --        goto continue 
    --    end
    --    if (not EntityService:IsAlive( entityToSell) ) then 
    --        --LogService:Log("Entity to sell not alive!  do not remove! " )
    --        goto continue 
    --    end
    --    local buildingComponent = EntityService:GetComponent( entityToSell, "BuildingComponent" )
    --    
    --    if ( buildingComponent ~= nil ) then
    --        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    --        if ( mode >= BM_SELLING ) then 
    --        --    LogService:Log("Mode: " .. tostring( mode ) .. ", do not remove!" )
    --            goto continue
    --         end 
    --    end
--
    --    local gridCullerComponent = EntityService:GetComponent( entityToSell, "GridCullerComponent")
    --    local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
    --    if( gridCullerComponent == nil or entityBlueprint == "" ) then 
    --       -- LogService:Log("No grid culler or entity blueprint! Do not remove!" )
    --        goto continue 
    --    end
--
    --    local gridCullerComponentHelper = reflection_helper(gridCullerComponent)
    --    local indexes = gridCullerComponentHelper.terrain_cell_entities
    --    local freeGrids = {}
    --    for i=indexes.count,1,-1 do 
    --        local add = true
    --        for j=1,testBuildable.free_grids.count do
    --            if ( testBuildable.free_grids[j] == indexes[i].id) then
    --                add = false
    --                break
    --            end
    --        end
    --        if (add ) then
    --            Insert(freeGrids, indexes[i].id )
    --        end
    --    end
    --    if ( #freeGrids > 0 ) then
    --        Insert(toRecreate, {["bp"]=entityBlueprint,["indexes"] = freeGrids })
    --    end
--
    --    removedCount = removedCount + 1
    --    QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
    --    ::continue::
    --end
    --Assert(removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )
    --self:FillWithFloors(self:FindBlueprint(), testBuildable.free_grids )
--
    --for recreateRequest in Iter( toRecreate ) do
    --    self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    --end 
    local currentPosition = EntityService:GetWorldTransform( self.entity )
    QueueEvent("BuildFloorRequest", self.entity, self.playerId,  self:FindBlueprint(), currentPosition )
    self.buildPosition = currentPosition
end

function ghost_building_floor:OnUpdate()
    local currentPosition = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , currentPosition, true )
    if ( self.activated and self.buildPosition ~= nil ) then
        self:FindMinDistance()
        if( BuildingService:ShouldBuildFloor( self.buildPosition, currentPosition, self.radius - 0.25 )) then
            self:BuildFloor(currentPosition , testBuildable)
        end
    end
end

function ghost_building_floor:OnActivate()
    if ( self.buildPosition == nil ) then
        self.buildPosition = EntityService:GetWorldTransform( self.selector )
        local toCreatePos = EntityService:GetWorldTransform( self.entity )
        local test = BuildingService:CheckGhostFloorStatus( self.playerId, self.entity, toCreatePos, self.blueprint )
        local testReflection = reflection_helper(test:ToTypeInstance())
        self:BuildFloor(toCreatePos, testReflection )
    else
        self.buildPosition = nil;
    end

end

function ghost_building_floor:OnDeactivate()
    self.buildPosition = nil
end

function ghost_building_floor:OnRelease()
end

return ghost_building_floor
 