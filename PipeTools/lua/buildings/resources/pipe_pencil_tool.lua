local pipe_base_tool = require("lua/buildings/resources/pipe_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'pipe_pencil_tool' ( pipe_base_tool )

function pipe_pencil_tool:__init()
    pipe_base_tool.__init(self,self)
end

function pipe_pencil_tool:OnInit()

    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    self.linesEntities = {}
    
    self.innerEntities = {}

    self.topEntities = {}
    self.rightEntities = {}
    self.bottomEntities = {}
    self.leftEntities = {}

    -- Marker with number of pipe layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNamePipesCount = "$pencil_pipe_lines_count"

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Pipe layers config
    self.pipeLinesCount = selectorDB:GetIntOrDefault(self.configNamePipesCount, 1)
    self.pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    self.buildCost = {}

    self:SpawnGhostEntities()
end

function pipe_pencil_tool:SpawnGhostEntities()

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

        -- Save number of pipe layers
        self.markerLinesConfig = pipeLinesCount
    end



    local scale = 2 - (pipeLinesCount % 2)

    EntityService:SetScale( self.entity, scale, 1, scale )


    if ( pipeLinesCount == 1 ) then

        self:ClearList(self.topEntities)
        self:ClearList(self.rightEntities)
        self:ClearList(self.bottomEntities)
        self:ClearList(self.leftEntities)

        local innerPositions = {}

        local newPosition = {}

        newPosition.x = 0
        newPosition.y = 0
        newPosition.z = 0

        Insert(innerPositions, newPosition)

        self:AdjustList(self.innerEntities, innerPositions)
    else
        
        local innerPositions,topPositions,rightPositions,bottomPositions,leftPositions = self:FindPositionsToBuildLine( pipeLinesCount )

        self:AdjustList(self.innerEntities, innerPositions)

        self:AdjustEdgeList(self.topEntities, topPositions, 270, 180)
        self:AdjustEdgeList(self.rightEntities, rightPositions, 180, 90)
        self:AdjustEdgeList(self.bottomEntities, bottomPositions, 90, 0)
        self:AdjustEdgeList(self.leftEntities, leftPositions, 0, 270)
    end

    self:FillLinesEntities()

    self.buildCost = {}

    local list = BuildingService:GetBuildCosts( self.pipeBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end
end

function pipe_pencil_tool:FindPositionsToBuildLine(pipeLinesCount)

    local innerPositions = {}

    local topPositions = {}
    local rightPositions = {}
    local bottomPositions = {}
    local leftPositions = {}

    local cellSize = 2

    local center = pipeLinesCount - 1

    for i=0,pipeLinesCount-2 do

        local newPosition = {}

        newPosition.x = (pipeLinesCount - 1) * cellSize - center
        newPosition.y = 0
        newPosition.z = i * cellSize - center

        Insert(topPositions, newPosition)
    end

    for i=0,pipeLinesCount-2 do

        local newPosition = {}

        newPosition.x = (pipeLinesCount - 1) * cellSize - i * cellSize - center
        newPosition.y = 0
        newPosition.z = (pipeLinesCount - 1) * cellSize - center

        Insert(rightPositions, newPosition)
    end

    for i=0,pipeLinesCount-2 do

        local newPosition = {}

        newPosition.x = - center
        newPosition.y = 0
        newPosition.z = (pipeLinesCount - 1) * cellSize - i * cellSize - center

        Insert(bottomPositions, newPosition)
    end

    for i=0,pipeLinesCount-2 do

        local newPosition = {}

        newPosition.x = i * cellSize - center
        newPosition.y = 0
        newPosition.z = - center

        Insert(leftPositions, newPosition)
    end

    for xNumber=1,pipeLinesCount-2 do

        for zNumber=1,pipeLinesCount-2 do

            local newPosition = {}

            newPosition.x = xNumber * cellSize - center
            newPosition.y = 0
            newPosition.z = zNumber * cellSize - center

            Insert(innerPositions, newPosition)
        end
    end

    return innerPositions, topPositions, rightPositions, bottomPositions, leftPositions
end

function pipe_pencil_tool:AdjustEdgeList(list, newPositions, degreeCorner, degreeT)
    
    local connectTypeCorner = 4
    local connectTypeT = 8

    local blueprintNameCorner = self:GetBlueprintByConnectType( connectTypeCorner )
    local blueprintNameT = self:GetBlueprintByConnectType( connectTypeT )

    if ( #list > #newPositions ) then

        for i=#list,#newPositions + 1,-1 do
            EntityService:RemoveEntity(list[i])
            list[i] = nil
        end

    elseif ( #list < #newPositions ) then

        for i=#list + 1,#newPositions do

            local blueprintName = blueprintNameT
            local degree = degreeT

            if ( i == 1) then
                blueprintName = blueprintNameCorner
                degree = degreeCorner
            end

            local lineEnt = EntityService:SpawnAndAttachEntity( blueprintName, self.selector )

            EntityService:RemoveComponent( lineEnt, "LuaComponent" )
            EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
            EntityService:SetPosition( lineEnt, newPositions[i] )

            EntityService:Rotate( lineEnt, 0.0, 1.0, 0.0, degree )

            Insert( list, lineEnt )
        end
    end

    Assert(#list == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#list) .. "/" .. tostring(#newPositions))

    for i=1,#newPositions do

        local lineEnt = list[i]

        EntityService:SetPosition( lineEnt, newPositions[i])
    end
end

function pipe_pencil_tool:AdjustList(list, newPositions)
    
    local connectType = 16

    local blueprintName = self:GetBlueprintByConnectType( connectType )

    if ( #list > #newPositions ) then

        for i=#list,#newPositions + 1,-1 do
            EntityService:RemoveEntity(list[i])
            list[i] = nil
        end

    elseif ( #list < #newPositions ) then

        for i=#list + 1,#newPositions do

            local lineEnt = EntityService:SpawnAndAttachEntity( blueprintName, self.selector )

            EntityService:RemoveComponent( lineEnt, "LuaComponent" )
            EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
            EntityService:SetPosition( lineEnt, newPositions[i] )

            Insert( list, lineEnt )
        end
    end

    Assert(#list == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#list) .. "/" .. tostring(#newPositions))

    for i=1,#newPositions do

        local lineEnt = list[i]

        EntityService:SetPosition( lineEnt, newPositions[i])
    end
end

function pipe_pencil_tool:FillLinesEntities()

    self.linesEntities = {}

    for entity in Iter(self.innerEntities) do
        Insert(self.linesEntities, entity)
    end

    for entity in Iter(self.topEntities) do
        Insert(self.linesEntities, entity)
    end

    for entity in Iter(self.rightEntities) do
        Insert(self.linesEntities, entity)
    end

    for entity in Iter(self.bottomEntities) do
        Insert(self.linesEntities, entity)
    end

    for entity in Iter(self.leftEntities) do
        Insert(self.linesEntities, entity)
    end
end

function pipe_pencil_tool:ClearList(list)

    for i=#list,1,-1 do

        local lineEnt = list[i]

        EntityService:RemoveEntity(lineEnt)

        list[i] = nil
    end
end

function pipe_pencil_tool:OnUpdate()

    self:RemoveMaterialFromOldBuildingsToSell()

    for i=1,#self.linesEntities do

        local lineEnt = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, i )

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



    if ( self.activated ) then

        self:FinishLineBuild()
    end
end

function pipe_pencil_tool:CheckConfigExists( pipeLinesCount )

    pipeLinesCount = pipeLinesCount or 1

    local scalePipeLines = self:GetPipeConfigArray()

    local index = IndexOf( scalePipeLines, pipeLinesCount )

    if ( index == nil ) then

        return scalePipeLines[1]
    end

    return pipeLinesCount
end

function pipe_pencil_tool:GetPipeConfigArray()

    if ( self.scalePipeLines == nil ) then

        self.scalePipeLines = {
            1,
            2,
            3,
            4,
            5,
            6,
        }
    end

    return self.scalePipeLines
end

function pipe_pencil_tool:OnActivateSelectorRequest()

    self.activated = true

    self:FinishLineBuild()
end

function pipe_pencil_tool:FinishLineBuild()

    for i=1,#self.linesEntities do

        local lineEnt = self.linesEntities[i]

        local createCube = (i == 1)

        self:BuildEntity(lineEnt, createCube)
    end
end

function pipe_pencil_tool:OnDeactivateSelectorRequest()

    self.activated = false
end

function pipe_pencil_tool:OnRotateSelectorRequest(evt)

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

    self:SpawnGhostEntities()
end

function pipe_pencil_tool:OnRelease()

    self:ClearList(self.innerEntities)
    
    self:ClearList(self.topEntities)
    self:ClearList(self.rightEntities)
    self:ClearList(self.bottomEntities)
    self:ClearList(self.leftEntities)

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( pipe_base_tool.OnRelease ) then
        pipe_base_tool.OnRelease(self)
    end
end

return pipe_pencil_tool