local portal_base_tool = require("lua/misc/portal_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

class 'portal_builder_tool' ( portal_base_tool )

function portal_builder_tool:__init()
    portal_base_tool.__init(self,self)
end

function portal_builder_tool:OnInit()

    self:RegisterHandler( self.selector, "RotateSelectorRequest",   "OnRotateSelectorRequest" )

    local selectorDB = EntityService:GetDatabase( self.selector )

    EntityService:SetVisible( self.entity, false )
    EntityService:SetScale( self.entity, 2, 1, 2 )

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.configNameDirection = "$portal_builder_tool_direction"
    self.configNameSize = "$portal_builder_tool_size"

    self.currentDirection = selectorDB:GetIntOrDefault(self.configNameDirection, 1)
    self.currentDirection = self:CheckDirectionExists(self.currentDirection)

    self.currentSize = selectorDB:GetIntOrDefault(self.configNameSize, 1)
    self.currentSize = self:CheckSizeExists(self.currentSize)

    self.currentMarkerSize = 0

    self.currentCellCountMarkerPlus = nil
    self.currentCellCountMarkerNumber1 = nil
    self.currentCellCountMarkerNumber2 = nil
    self.currentCellCountMarkerNumber3 = nil

    -- 36,22   0,44

    self:SpawnGhostEntities()
end

function portal_builder_tool:GetDirectionConfigArray()

    if ( self.configDirectionArray == nil ) then

        local vectorZ = { ["x"] = 0, ["z"] = 44 }
        local vector_Z = { ["x"] = 0, ["z"] = -44 }

        local vectorXZ = { ["x"] = 36, ["z"] = 22 }
        local vector_XZ = { ["x"] = -36, ["z"] = 22 }
        local vectorX_Z = { ["x"] = 36, ["z"] = -22 }
        local vector_X_Z = { ["x"] = -36, ["z"] = -22 }

        self.configDirectionArray = {

            { vector_Z },
            { vector_Z, vectorX_Z },

            { vectorX_Z },
            { vectorX_Z, vectorXZ },

            { vectorXZ },
            { vectorXZ, vectorZ },

            { vectorZ },
            { vectorZ, vector_XZ },

            { vector_XZ },
            { vector_XZ, vector_X_Z },

            { vector_X_Z },
            { vector_X_Z, vector_Z },

            { vector_Z, vectorX_Z, vectorXZ, vectorZ, vector_XZ, vector_X_Z },
        }
    end

    return self.configDirectionArray
end

function portal_builder_tool:CheckDirectionExists( currentDirection )

    currentDirection = tonumber(currentDirection)

    currentDirection = currentDirection or 1

    local directionConfigArray = self:GetDirectionConfigArray()

    local maxIndex = #directionConfigArray

    if ( currentDirection > maxIndex ) then
        currentDirection = 1
    elseif( currentDirection < 1 ) then
        currentDirection = maxIndex
    end

    return currentDirection
end

function portal_builder_tool:CheckSizeExists( currentSize )

    if ( currentSize == nil ) then
        return 1
    end

    currentSize = tonumber(currentSize)

    currentSize = currentSize or 1

    if ( currentSize < 1 ) then

        currentSize = 1
    end

    return currentSize
end

function portal_builder_tool:SpawnGhostEntities()

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local orientation = currentTransform.orientation



    local currentDirection = self:CheckDirectionExists(self.currentDirection)
    local currentSize = self:CheckSizeExists(self.currentSize)

    local newPositionsArray,hashPositions = self:FindPositionsToBuildLine( currentDirection, currentSize )




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

            lineEnt = self:SpawnGhostPortalEntity(newPosition, orientation)

            EntityService:SpawnAndAttachEntity( "misc/marked_portal_builder_tool_ghost_minimap_icon", lineEnt )

            self:RemoveUselessComponents(lineEnt)
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





    self.buildCost = {}

    local list = BuildingService:GetBuildCosts( self.portalBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end

    self:UpdateMarker(currentSize)
end

function portal_builder_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        return nil
    end

    local arrayXPosition = gridEntities[newPositionX]

    if ( arrayXPosition[newPositionZ] == nil ) then

        return nil
    end

    return arrayXPosition[newPositionZ]
end

function portal_builder_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        gridEntities[newPositionX] = {}
    end

    local arrayXPosition = gridEntities[newPositionX]

    arrayXPosition[newPositionZ] = lineEnt
end

function portal_builder_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then

        return false
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        return false
    end

    return true
end

function portal_builder_tool:RemoveUselessComponents(entity)

    if ( EntityService:HasComponent( entity, "DisplayRadiusComponent" ) ) then
        EntityService:RemoveComponent( entity, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( entity, "GhostLineCreatorComponent" ) ) then
        EntityService:RemoveComponent( entity, "GhostLineCreatorComponent" )
    end
end

function portal_builder_tool:FindPositionsToBuildLine(currentDirection, currentSize)

    local directionConfigArray = self:GetDirectionConfigArray()

    LogService:Log("currentDirection " .. tostring(currentDirection))

    local vectorsArrays = directionConfigArray[currentDirection]

    LogService:Log("vectorsArrays " .. debug_serialize_utils:SerializeObject(vectorsArrays))

    local result = {}
    local hashPositions = {}

    local newPosition = nil

    newPosition = {}
    newPosition.x = 0
    newPosition.z = 0

    Insert( result, newPosition )

    local tempArray = {}

    Insert( tempArray, newPosition )

    self:AddToHash(hashPositions, newPosition.x, newPosition.z )

    for i=1,currentSize do

        local newPositions = {}

        for position in Iter(tempArray) do

            for vector in Iter(vectorsArrays) do

                newPosition = {}
                newPosition.x = position.x + vector.x
                newPosition.z = position.z + vector.z

                if ( self:AddToHash( hashPositions, newPosition.x, newPosition.z ) ) then

                    Insert( result, newPosition )
                    Insert( newPositions, newPosition )
                end
            end
        end

        tempArray = newPositions
    end

    return result, hashPositions
end

function portal_builder_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

    if ( hashPositions[newPositionX] == nil) then

        hashPositions[newPositionX] = {}
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] ~= nil ) then

        return false
    end

    hashXPosition[newPositionZ] = true

    return true
end

function portal_builder_tool:UpdateMarker(currentSize)

    if ( self.currentMarkerSize ~= currentSize ) then

        self.currentMarkerSize = currentSize 
        
        
        number = tonumber(currentSize)


        local number1 = number % 10
        number = number - number1

        local number2 = math.floor( (number % 100) / 10 )
        number = number - number2

        local number3 = math.floor( (number % 1000) / 100 )
        number = number - number3

        if ( currentSize > 999 ) then
        
            number1 = 9
            number2 = 9
            number3 = 9

            if ( self.currentCellCountMarkerPlus == nil ) then

                self.currentCellCountMarkerPlus = EntityService:SpawnAndAttachEntity("misc/marker_selector_portal_builder_tool_number_plus", self.selector)
            end
        else

            if ( self.currentCellCountMarkerPlus ~= nil ) then
                EntityService:RemoveEntity(self.currentCellCountMarkerPlus)
                self.currentCellCountMarkerPlus = nil
            end
        end

        markerBlueprint = "misc/marker_selector_portal_builder_tool_number_" .. tostring(number1)

        if ( self.currentCellCountMarkerNumber1 == nil or EntityService:GetBlueprintName(self.currentCellCountMarkerNumber1) ~= markerBlueprint ) then

            if ( self.currentCellCountMarkerNumber1 ~= nil) then
                EntityService:RemoveEntity(self.currentCellCountMarkerNumber1)
                self.currentCellCountMarkerNumber1 = nil
            end  

            self.currentCellCountMarkerNumber1 = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)

            EntityService:SetPosition( self.currentCellCountMarkerNumber1, 0, 0, -2.9 )
        end

        if ( number2 ~= 0 or number3 ~= 0 ) then

            markerBlueprint = "misc/marker_selector_portal_builder_tool_number_" .. tostring(number2)

            if ( self.currentCellCountMarkerNumber2 == nil or EntityService:GetBlueprintName(self.currentCellCountMarkerNumber2) ~= markerBlueprint ) then

                if ( self.currentCellCountMarkerNumber2 ~= nil) then
                    EntityService:RemoveEntity(self.currentCellCountMarkerNumber2)
                    self.currentCellCountMarkerNumber2 = nil
                end

                self.currentCellCountMarkerNumber2 = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)

                EntityService:SetPosition( self.currentCellCountMarkerNumber2, 0, 0, -2.9 )
            end
        else

            if ( self.currentCellCountMarkerNumber2 ~= nil) then
                EntityService:RemoveEntity(self.currentCellCountMarkerNumber2)
                self.currentCellCountMarkerNumber2 = nil
            end            
        end

        if ( number3 ~= 0 ) then

            markerBlueprint = "misc/marker_selector_portal_builder_tool_number_" .. tostring(number3)

            if ( self.currentCellCountMarkerNumber3 == nil or EntityService:GetBlueprintName(self.currentCellCountMarkerNumber3) ~= markerBlueprint ) then

                if ( self.currentCellCountMarkerNumber3 ~= nil) then
                    EntityService:RemoveEntity(self.currentCellCountMarkerNumber3)
                    self.currentCellCountMarkerNumber3 = nil
                end

                self.currentCellCountMarkerNumber3 = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)

                EntityService:SetPosition( self.currentCellCountMarkerNumber3, 0, 0, -3.8 )
            end
        else

            if ( self.currentCellCountMarkerNumber3 ~= nil) then
                EntityService:RemoveEntity(self.currentCellCountMarkerNumber3)
                self.currentCellCountMarkerNumber3 = nil
            end            
        end

        
    end
end

function portal_builder_tool:OnUpdate()

    for number=1,#self.linesEntities do

        local lineEnt = self.linesEntities[number]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, number )
    end





    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function portal_builder_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.sizeChanged = false

        self.buildTransform = EntityService:GetWorldTransform( self.entity )
        self.activated = true
    else
        self:FinishLineBuild()
    end
end

function portal_builder_tool:FinishLineBuild()

    for i=1,#self.linesEntities do

        local ghostEntity = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( ghostEntity )

        self:BuildEntity(ghostEntity, transform, true)
    end
end

function portal_builder_tool:OnDeactivateSelectorRequest()

    self.buildTransform = nil
    self.activated = false

    if ( not self.sizeChanged ) then

        self:FinishLineBuild()
    end
end

function portal_builder_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    if ( self.activated ) then

        local currentSize = self:CheckSizeExists(self.currentSize)

        local newValue = currentSize + change

        if ( newValue < 0 ) then
            newValue = 0
        end

        self.currentSize = newValue

        local selectorDB = EntityService:GetDatabase( self.selector )
        selectorDB:SetInt(self.configNameSize, newValue)

        self.sizeChanged = true
    else

        -- Inverting rotation
        if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
            change = -change
        end

        local currentDirection = self:CheckDirectionExists(self.currentDirection)

        local configArray = self:GetDirectionConfigArray()

        local maxIndex = #configArray

        local newIndex = currentDirection + change
        if ( newIndex > maxIndex ) then
            newIndex = 1
        elseif( newIndex < 1 ) then
            newIndex = maxIndex
        end

        self.currentDirection = newIndex

        local selectorDB = EntityService:GetDatabase( self.selector )
        selectorDB:SetInt(self.configNameDirection, newIndex)
    end

    self:SpawnGhostEntities()
end

function portal_builder_tool:OnRelease()

    if ( self.linesEntities ~= nil) then
        for ghostEntity in Iter(self.linesEntities) do
            EntityService:RemoveEntity(ghostEntity)
        end
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.currentMarkerSize = 0
    self.currentMarkerBlueprint = ""

    if (self.currentMarker ~= nil) then

        EntityService:RemoveEntity(self.currentMarker)
        self.currentMarker = nil
    end

    if (self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if (self.currentCellCountMarkerNumber1 ~= nil) then

        EntityService:RemoveEntity(self.currentCellCountMarkerNumber1)
        self.currentCellCountMarkerNumber1 = nil
    end

    if (self.currentCellCountMarkerNumber2 ~= nil) then

        EntityService:RemoveEntity(self.currentCellCountMarkerNumber2)
        self.currentCellCountMarkerNumber2 = nil
    end

    if (self.currentCellCountMarkerNumber3 ~= nil) then

        EntityService:RemoveEntity(self.currentCellCountMarkerNumber3)
        self.currentCellCountMarkerNumber3 = nil
    end

    if (self.currentCellCountMarkerPlus ~= nil) then
        EntityService:RemoveEntity(self.currentCellCountMarkerPlus)
        self.currentCellCountMarkerPlus = nil
    end

    if ( portal_base_tool.OnRelease ) then
        portal_base_tool.OnRelease(self)
    end
end

return portal_builder_tool