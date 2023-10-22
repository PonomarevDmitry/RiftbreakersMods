local energy_connector_base_tool = require("lua/buildings/energy/energy_connector_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'energy_connector_tool' ( energy_connector_base_tool )

function energy_connector_tool:__init()
    energy_connector_base_tool.__init(self,self)
end

function energy_connector_tool:OnInit()

    EntityService:SetVisible( self.entity , false )

    self.linesEntities = {}

    self.configNameSize = "$energy_connector_tool_size"

    self.type = self.data:GetIntOrDefault("type", 1)

    self.defaultRadius = math.ceil( (self.radius - 1) / 2 )

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.currentSize = selectorDB:GetIntOrDefault(self.configNameSize, self.defaultRadius)
    self.currentSize = self:CheckSizeExists(self.currentSize)

    self:SpawnGhostConnectorEntities()
end

function energy_connector_tool:CheckSizeExists( currentSize )

    currentSize = currentSize or self.defaultRadius

    if ( currentSize < 1) then
        currentSize = 1
    elseif ( currentSize > self.radius) then
        currentSize = self.radius
    end

    return currentSize
end

function energy_connector_tool:SpawnGhostConnectorEntities()

    local currentSize = self:CheckSizeExists(self.currentSize)

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local orientation = currentTransform.orientation

    local newPositions = self:FindPositionsToBuildLine( currentSize )

    if ( #self.linesEntities > #newPositions ) then

        for i=#self.linesEntities,#newPositions + 1,-1 do
            local lineEnt = self.linesEntities[i]
            EntityService:RemoveEntity(lineEnt)
            self.linesEntities[i] = nil
        end

    elseif ( #self.linesEntities < #newPositions ) then

        for i=#self.linesEntities + 1 ,#newPositions do

            local lineEnt = self:SpawnGhostConnectorEntity(newPositions[i], orientation)

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
    end

    self.buildCost = {}

    local list = BuildingService:GetBuildCosts( self.connectorBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end
end

function energy_connector_tool:FindPositionsToBuildLine(currentSize)

    if ( self.type == 2 ) then

        return self:FindPositionsType2(currentSize)

    elseif ( self.type == 3 ) then

        return self:FindPositionsType3(currentSize)
    end

    return self:FindPositionsType1(currentSize)
end

function energy_connector_tool:FindPositionsType1(currentSize)

    local result = {}

    local delta = currentSize * 2

    local newPosition = nil

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = - delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = - delta

    Insert( result, newPosition )

    return result
end

function energy_connector_tool:FindPositionsType2(currentSize)

    local result = {}

    local delta = currentSize * 2

    local newPosition = nil

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = delta
    newPosition.z = 0

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = 0
    newPosition.z = - delta

    Insert( result, newPosition )

    newPosition = {}
    newPosition.y = 0
    newPosition.x = - delta
    newPosition.z = 0

    Insert( result, newPosition )

    return result
end

function energy_connector_tool:FindPositionsType3(currentSize)

    local result = {}

    local delta = currentSize * 2

    for indexX = 0,1 do
        for indexZ = 0,1 do

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

function energy_connector_tool:OnUpdate()

    for number=1,#self.linesEntities do

        local lineEnt = self.linesEntities[number]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, number )
    end



    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end



    if ( self.activated and self.buildPosition ~= nil ) then

        local currentPosition = EntityService:GetWorldTransform( self.entity )

        local spots = BuildingService:FindSpotsByDistance( self.buildPosition, currentPosition, self.radius, self.connectorBlueprintName )

        for spot in Iter( spots ) do

            local currentSize = self:CheckSizeExists(self.currentSize)
            local newPositions = self:FindPositionsToBuildLine( currentSize )

            for i=1,#newPositions do

                local newPosition = newPositions[i]

                local transform = {}
                transform.scale = spot.scale
                transform.orientation = spot.orientation

                transform.position = {}
                transform.position.x = spot.position.x + newPosition.x
                transform.position.y = spot.position.y + newPosition.y
                transform.position.z = spot.position.z + newPosition.z

                local lineEnt = self.linesEntities[i]

                self:BuildEntity(lineEnt, transform, true)
            end

            self.buildPosition = spot
        end
    end
end

function energy_connector_tool:OnActivateSelectorRequest()

    self:FinishLineBuild()

    self.buildPosition = EntityService:GetWorldTransform( self.entity )
    self.activated = true
end

function energy_connector_tool:OnDeactivateSelectorRequest()

    self.buildPosition = nil
    self.activated = false
end

function energy_connector_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentSize = self:CheckSizeExists(self.currentSize)

    local newValue = currentSize + change

    if ( newValue < 1 ) then
        newValue = 1
    elseif ( newValue > self.radius ) then
        newValue = self.radius
    end

    self.currentSize = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameSize, newValue)

    self:SpawnGhostConnectorEntities()
end

function energy_connector_tool:FinishLineBuild()

    local count = #self.linesEntities

    for i=1,count do

        local ghostEntity = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( ghostEntity )

        self:BuildEntity(ghostEntity, transform, true)
    end
end

function energy_connector_tool:OnRelease()

    if ( self.linesEntities ~= nil) then
        for ghostEntity in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghostEntity)
        end
    end
    self.linesEntities = {}

    if ( energy_connector_base_tool.OnRelease ) then
        energy_connector_base_tool.OnRelease(self)
    end
end

return energy_connector_tool