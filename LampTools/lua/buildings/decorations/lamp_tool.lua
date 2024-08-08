local lamp_base_tool = require("lua/buildings/decorations/lamp_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'lamp_tool' ( lamp_base_tool )

function lamp_tool:__init()
    lamp_base_tool.__init(self,self)
end

function lamp_tool:OnInit()

    EntityService:SetVisible( self.entity , false )

    self.linesEntities = {}

    self.configNameSize = "$lamp_tool_size"

    self.type = self.data:GetIntOrDefault("type", 1)

    self.defaultRadius = 6

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.currentSize = selectorDB:GetIntOrDefault(self.configNameSize, self.defaultRadius)
    self.currentSize = self:CheckSizeExists(self.currentSize)

    self.currentMarker = nil
    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    self:SpawnGhostLampEntities()
end

function lamp_tool:CheckSizeExists( currentSize )

    currentSize = currentSize or self.defaultRadius

    if ( currentSize < 1) then
        currentSize = 1
    elseif ( currentSize > self.radius) then
        currentSize = self.radius
    end

    return currentSize
end

function lamp_tool:SpawnGhostLampEntities()

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

            local lineEnt = self:SpawnGhostLampEntity(newPositions[i], orientation)

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

    local list = BuildingService:GetBuildCosts( self.lampBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end

    self:UpdateMarker(currentSize)
end

function lamp_tool:FindPositionsToBuildLine(currentSize)

    if ( self.type == 2 ) then

        return self:FindPositionsType2(currentSize)

    elseif ( self.type == 3 ) then

        return self:FindPositionsType3(currentSize)
    end

    return self:FindPositionsType1(currentSize)
end

function lamp_tool:FindPositionsType1(currentSize)

    local result = {}

    local delta = currentSize * 2

    local newPosition = nil

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

function lamp_tool:FindPositionsType2(currentSize)

    local result = {}

    local delta = currentSize * 2

    local newPosition = nil

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

function lamp_tool:FindPositionsType3(currentSize)

    local result = {}

    local delta = currentSize * 2

    for indexX = 0,1 do
        for indexZ = 0,1 do

            local maxIndex = math.max(indexX, indexZ)
            local totalIndex = indexX + indexZ

            local newPosition = nil

            if ( indexX ~= 0 or indexZ ~= 0 ) then

                newPosition = {}
                newPosition.y = 0
                newPosition.x = indexX * delta
                newPosition.z = indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end

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

function lamp_tool:UpdateMarker(currentSize)

    if ( self.currentMarkerSize ~= currentSize ) then

        self.currentMarkerSize = currentSize

        local markerBlueprint = "misc/marker_selector_lamp_tool_radius_" .. tostring(currentSize)

        if ( currentSize > 16 ) then
            markerBlueprint = "misc/marker_selector_lamp_tool_radius_g16"
        end

        if ( self.currentMarkerBlueprint ~= markerBlueprint or self.currentMarker == nil ) then

            -- Destroy old marker
            if (self.currentMarker ~= nil) then

                EntityService:RemoveEntity(self.currentMarker)
                self.currentMarker = nil
            end

            self.currentMarkerBlueprint = markerBlueprint

            self.currentMarker = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )
            EntityService:SetPosition( self.currentMarker, 0, 0, -2 )
        end
    end
end

function lamp_tool:OnUpdate()

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

        local currentSize = self:CheckSizeExists(self.currentSize)

        local spots = BuildingService:FindSpotsByDistance( self.buildPosition, currentPosition, (currentSize + 2) * 2, self.lampBlueprintName )

        for spot in Iter( spots ) do
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

function lamp_tool:OnActivateSelectorRequest()

    self:FinishLineBuild()

    self.buildPosition = EntityService:GetWorldTransform( self.entity )
    self.activated = true
end

function lamp_tool:OnDeactivateSelectorRequest()

    self.buildPosition = nil
    self.activated = false
end

function lamp_tool:OnRotateSelectorRequest(evt)

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

    self:SpawnGhostLampEntities()
end

function lamp_tool:FinishLineBuild()

    local count = #self.linesEntities

    for i=1,count do

        local ghostEntity = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( ghostEntity )

        self:BuildEntity(ghostEntity, transform, true)
    end
end

function lamp_tool:OnRelease()

    if ( self.linesEntities ~= nil) then
        for ghostEntity in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghostEntity)
        end
    end
    self.linesEntities = {}

    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    if (self.currentMarker ~= nil) then

        EntityService:RemoveEntity(self.currentMarker)
        self.currentMarker = nil
    end

    if ( lamp_base_tool.OnRelease ) then
        lamp_base_tool.OnRelease(self)
    end
end

return lamp_tool