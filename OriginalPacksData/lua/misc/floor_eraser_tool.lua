
local tool = require("lua/misc/tool.lua")

class 'floor_eraser' ( tool )

function floor_eraser:__init()
    tool.__init(self,self)
end

function floor_eraser:OnInit()
    self.baseSearch = false
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser", self.entity)
end

function floor_eraser:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end


function floor_eraser:FillWithFloors( blueprint, indexes )
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
            QueueEvent("BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function floor_eraser:SellFloor()
    local transform = EntityService:GetWorldTransform( self.entity )

    local toRecreate ={}

    local gridToErase = FindService:GetEntityCellIndexes(self.entity )

    for i = 1, #self.selectedEntities do
        local entityToSell = self.selectedEntities[i]
        if (entityToSell == nil or  not EntityService:IsAlive( entityToSell) ) then goto continue end

        local indexes = EntityService:GetEntityCellIndexes( entityToSell )
        local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
        if( #indexes == 0 or entityBlueprint == "" ) then goto continue end

        local freeGrids = {}
        for i=#indexes,1,-1 do 
            local add = true
            for j=1,#gridToErase do
                if ( gridToErase[j] == indexes[i]) then
                    add = false
                    break
                end
            end
            if (add ) then
                Insert(freeGrids, indexes[i] )
            end
        end
        if ( #freeGrids > 0 ) then
            Insert(toRecreate, {["bp"]=entityBlueprint,["indexes"] = freeGrids })
        end

        QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        ::continue::
    end
    
    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end 

    self.buildPosition = currentPosition
end

function floor_eraser:FindEntitiesToSelect( selectorComponent )
    local position = selectorComponent.position 
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale))
    
    return FindService:FindFloorsByBox( min, max )
end

function floor_eraser:AddedToSelection( entity )
	local meshEntity = BuildingService:GetMeshEntity(entity);
    EntityService:SetMaterial( meshEntity, "hologram/blue", "selected")
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:SetMaterial( child, "hologram/blue", "selected")
    end
end

function floor_eraser:RemovedFromSelection( entity )
	local meshEntity = BuildingService:GetMeshEntity(entity);
    EntityService:RemoveMaterial(meshEntity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial(child, "selected" )
    end
end

function floor_eraser:OnUpdate()
    if ( self.activated ) then
        self:SellFloor()
    end

    self.repairCosts = {}
    for entity in Iter(self.selectedEntities ) do
        local list = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list) do
            if ( self.repairCosts[resourceCost.first] == nil ) then
               self.repairCosts[resourceCost.first ] = resourceCost.second 
            else
               self.repairCosts[resourceCost.first ] = self.repairCosts[resourceCost.first ] + resourceCost.second 
            end
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.repairCosts)
        BuildingService:OperateSellCosts( self.corners, self.playerId, {})
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId,{})
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.repairCosts)
    end
end

function floor_eraser:OnRotate()
end

function floor_eraser:OnActivateEntity( entity)
end

return floor_eraser
 
