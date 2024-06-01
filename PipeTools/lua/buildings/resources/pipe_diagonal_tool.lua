local pipe_base_tool = require("lua/buildings/resources/pipe_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'pipe_diagonal_tool' ( pipe_base_tool )

function pipe_diagonal_tool:__init()
    pipe_base_tool.__init(self,self)
end

function pipe_diagonal_tool:OnInit()

    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    self.buildStartPosition = nil
    self.positionPlayer = nil

    -- Marker with number of pipe layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNamePipesCount = "$diagonal_pipe_lines_count"

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Pipe layers config
    self.pipeLinesCount = selectorDB:GetIntOrDefault(self.configNamePipesCount, 1)
    self.pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    self:SpawnGhostPipeEntity()
end

function pipe_diagonal_tool:OnUpdate()

    self.buildCost = {}

    -- Pipe layers config
    local pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    -- Correct Marker to show right number of pipe layers
    if ( self.markerLinesConfig ~= pipeLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local markerBlueprint = "misc/marker_selector_diagonal_pipe_lines_" .. tostring( pipeLinesCount )

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
        EntityService:SetPosition( self.currentMarkerLines, 0, 0, -2 )

        -- Save number of pipe layers
        self.markerLinesConfig = pipeLinesCount
    end

    self:RemoveMaterialFromOldBuildingsToSell()

    if ( self.buildStartPosition ) then

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.ghostPipe )

        local buildEndPosition = currentTransform.position

        local newPositionsArray, hashPositions = self:FindPositionsToBuildLine( buildEndPosition, pipeLinesCount )

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

                lineEnt = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
                EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
                EntityService:RemoveComponent(lineEnt, "LuaComponent")

                EntityService:SetOrientation(lineEnt, currentTransform.orientation )
                EntityService:SetPosition( lineEnt, newPosition)
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

        for i=1,#newLinesEntities do

            local lineEnt = newLinesEntities[i]

            local transform = EntityService:GetWorldTransform( lineEnt )

            local testBuildable = self:CheckEntityBuildable( lineEnt, transform, i )

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end

            BuildingService:CheckAndFixBuildingConnection( lineEnt )
        end

        self.linesEntities = newLinesEntities
        self.linesEntityInfo = newLinesEntityInfo
        self.gridEntities = newGridEntities

        local list = BuildingService:GetBuildCosts( self.pipeBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #newPositionsArray )
        end
    else
        local transform = EntityService:GetWorldTransform( self.ghostPipe )
        local testBuildable = self:CheckEntityBuildable( self.ghostPipe, transform )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end
    end



    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function pipe_diagonal_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        return nil
    end

    local arrayXPosition = gridEntities[newPositionX]

    if ( arrayXPosition[newPositionZ] == nil ) then

        return nil
    end

    return arrayXPosition[newPositionZ]
end

function pipe_diagonal_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        gridEntities[newPositionX] = {}
    end

    local arrayXPosition = gridEntities[newPositionX]

    arrayXPosition[newPositionZ] = lineEnt
end

function pipe_diagonal_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then

        return false
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        return false
    end

    return true
end

function pipe_diagonal_tool:FindPositionsToBuildLine( buildEndPosition, pipeLinesCount )

    local positionPlayer = self.positionPlayer
    if (positionPlayer == nil) then
        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        positionPlayer = EntityService:GetPosition( player )
    end

    local hashPositions = {}

    local pathFromStartPositionToEndPosition = self:FindSingleDiagonalLine( self.buildStartPosition.position, buildEndPosition, positionPlayer )
    if ( pipeLinesCount == 1 ) then

        for i=1,#pathFromStartPositionToEndPosition do

            local position = pathFromStartPositionToEndPosition[i]

            self:AddToHash( hashPositions, position.x, position.z )
        end

        return pathFromStartPositionToEndPosition, hashPositions
    end

    local x0 = self.buildStartPosition.position.x
    local z0 = self.buildStartPosition.position.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    self.coefX = (z1 - z0)
    self.coefZ = -(x1 - x0)
    self.const = x1*z0 - x0*z1

    local playerValue = self:CalcFunction( positionPlayer.x, positionPlayer.z )

    local newPositionX = x0 + self.coefX * 3
    local newPositionZ = z0 + self.coefZ * 3

    local secondValue = self:CalcFunction( newPositionX, newPositionZ )

    if ( secondValue * playerValue > 0 ) then

        newPositionX = x0 - self.coefX * 3
        newPositionZ = z0 - self.coefZ * 3
    end

    local endPositionMulti = {}
    endPositionMulti.x = newPositionX
    endPositionMulti.y = self.buildStartPosition.position.y
    endPositionMulti.z = newPositionZ

    local pathMulti = self:FindSingleDiagonalLine( self.buildStartPosition.position, endPositionMulti, positionPlayer )

    self:MakeRelativePath( pathMulti, x0, z0 )

    local multiPipesArray = self:GetPathWithNumberChanges( pathMulti, pipeLinesCount - 1 )



    local result = {}

    for i=1,#pathFromStartPositionToEndPosition do

        local position = pathFromStartPositionToEndPosition[i]

        -- Add if position has not been added yet
        if ( self:AddToHash( hashPositions, position.x, position.z ) ) then

            table.insert(result, position)
        end

        for vector in Iter( multiPipesArray ) do

            local newPositionX = position.x + vector.x
            local newPositionZ = position.z + vector.z

            self:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, position.y)
        end
    end

    return result, hashPositions
end

function pipe_diagonal_tool:GetPathWithNumberChanges( pathMulti, changesCount )

    if ( #pathMulti == 0 or #pathMulti == 1 ) then
        return pathMulti
    end

    local x0 = 0
    local z0 = 0

    local changesX = 0
    local changesZ = 0

    local index = 1
    local previousPosition = nil


    local result = {}

    local countCalcs = 0

    while ( true ) do

        local position = pathMulti[index]

        local newPositionX = x0 + position.x
        local newPositionZ = z0 + position.z

        local vector = {}
        vector.x = newPositionX
        vector.z = newPositionZ

        Insert( result, vector )

        if (previousPosition ~= nil) then

            if ( previousPosition.x ~= newPositionX ) then
                changesX = changesX + 1
            end

            if ( previousPosition.z ~= newPositionZ ) then
                changesZ = changesZ + 1
            end
        end

        if ( changesX >= changesCount or changesZ >= changesCount ) then
            break;
        end

        previousPosition = vector

        index = index + 1

        if ( index > #pathMulti ) then
            index = 2;

            x0 = newPositionX
            z0 = newPositionZ
        end

        countCalcs = countCalcs + 1

        if ( countCalcs > 50 ) then
            break
        end
    end

    return result
end

function pipe_diagonal_tool:MakeRelativePath( pathMulti, x0, z0 )

    for position in Iter( pathMulti ) do

        local newPositionX = position.x - x0
        local newPositionZ = position.z - z0

        position.x = newPositionX
        position.z = newPositionZ
    end
end

function pipe_diagonal_tool:AddNewPositionToResult(hashPositions, result, newPositionX, newPositionZ, newPositionY)

    -- Add if position has not been added yet
    if ( not self:AddToHash(hashPositions, newPositionX, newPositionZ ) ) then
        return
    end

    local newPosition = {}
    newPosition.x = newPositionX
    newPosition.y = newPositionY
    newPosition.z = newPositionZ

    table.insert(result, newPosition)
end

-- Check position has not already been added to hashPositions
function pipe_diagonal_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

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

function pipe_diagonal_tool:CalcFunction( positionX, positionZ )

    local result = self.coefX * positionX + self.coefZ * positionZ + self.const

    if ( result > 0 ) then
        return 1
    elseif ( result < 0 ) then
        return -1
    end

    return 0
end

function pipe_diagonal_tool:SetLineParameters( buildStartPosition, buildEndPosition )

    local x0 = buildStartPosition.x
    local z0 = buildStartPosition.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    self.coefX = (z1 - z0)
    self.coefZ = -(x1 - x0)
    self.const = x1*z0 - x0*z1
end

function pipe_diagonal_tool:CheckConfigExists( pipeLinesCount )

    pipeLinesCount = pipeLinesCount or 1

    local scalePipeLines = self:GetPipeConfigArray()

    local index = IndexOf( scalePipeLines, pipeLinesCount )

    if ( index == nil ) then

        return scalePipeLines[1]
    end

    return pipeLinesCount
end

function pipe_diagonal_tool:GetPipeConfigArray()

    if ( self.scalePipeLines == nil ) then

        self.scalePipeLines = {
            1,
            2,
            3,
            --4,
            --5,
            --6,
        }
    end

    return self.scalePipeLines
end

function pipe_diagonal_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostPipe, false )

        local player = PlayerService:GetPlayerControlledEnt(self.playerId)
        self.positionPlayer = EntityService:GetPosition( player )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function pipe_diagonal_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function pipe_diagonal_tool:FinishLineBuild()

    EntityService:SetVisible( self.ghostPipe, true )

    local count = #self.linesEntities
    local step = count

    if ( count > 5 ) then
        local additionalCubesCount = math.ceil( count / 5 )
        step = math.ceil( count / additionalCubesCount)
    end

    for i=1,count do

        local ghostEntity = self.linesEntities[i]
        local createCube = ((i == 1) or (i == count) or (i % step == 0))

        self:BuildEntity(ghostEntity, createCube)

        EntityService:RemoveEntity(ghostEntity)
    end

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}
    self.buildStartPosition = nil
    self.positionPlayer = nil
end

function pipe_diagonal_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentLinesConfig = self:CheckConfigExists(self.pipeLinesCount)

    local scalePipeLines = self:GetPipeConfigArray()

    local index = IndexOf( scalePipeLines, currentLinesConfig )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #scalePipeLines

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex < 1 ) then
        newIndex = 1
    end

    local newValue = scalePipeLines[newIndex]

    self.pipeLinesCount = newValue

    -- Pipe layers config
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNamePipesCount, newValue)

    self:OnUpdate()
end

function pipe_diagonal_tool:OnRelease()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( pipe_base_tool.OnRelease ) then
        pipe_base_tool.OnRelease(self)
    end
end

return pipe_diagonal_tool