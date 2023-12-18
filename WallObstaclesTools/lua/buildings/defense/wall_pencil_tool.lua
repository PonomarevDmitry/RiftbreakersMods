local wall_base_tool = require("lua/buildings/defense/wall_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_pencil_tool' ( wall_base_tool )

function wall_pencil_tool:__init()
    wall_base_tool.__init(self,self)
end

function wall_pencil_tool:OnInit()

    self.linesEntities = {}
    
    self.innerEntities = {}

    self.topEntities = {}
    self.rightEntities = {}
    self.bottomEntities = {}
    self.leftEntities = {}

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsCount = "$pencil_wall_lines_count"

    local selectorDB = EntityService:GetDatabase( self.selector )

    -- Wall layers config
    self.wallLinesCount = selectorDB:GetIntOrDefault(self.configNameWallsCount, 1)
    self.wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    self.buildCost = {}

    self:SpawnGhostEntities()
end

function wall_pencil_tool:SpawnGhostEntities()

    self.buildCost = {}

    -- Wall layers config
    local wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    -- Correct Marker to show right number of wall layers
    if ( self.markerLinesConfig ~= wallLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local wallLinesCountString = tostring( wallLinesCount )

        if ( wallLinesCount > 16 ) then
            wallLinesCountString = "g16"
        end

        local markerBlueprint = "misc/marker_selector_wall_pencil_size_" .. wallLinesCountString

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )

        -- Save number of wall layers
        self.markerLinesConfig = wallLinesCount
    end



    local scale = 2 - (wallLinesCount % 2)

    EntityService:SetScale( self.entity, scale, 1, scale )


    if ( wallLinesCount == 1 ) then

        self:ClearList(self.topEntities)
        self:ClearList(self.rightEntities)
        self:ClearList(self.bottomEntities)
        self:ClearList(self.leftEntities)

        local innerPositions = {}

        Insert(innerPositions, 0)

        self:AdjustInnerList(self.innerEntities, innerPositions)
    else
        
        local innerPositions,topPositions,rightPositions,bottomPositions,leftPositions = self:FindPositionsToBuildLine( wallLinesCount )

        self:AdjustInnerList(self.innerEntities, innerPositions)

        self:AdjustEdgeList(self.topEntities, topPositions, 270, 180)
        self:AdjustEdgeList(self.rightEntities, rightPositions, 180, 90)
        self:AdjustEdgeList(self.bottomEntities, bottomPositions, 90, 0)
        self:AdjustEdgeList(self.leftEntities, leftPositions, 0, 270)
    end

    self:FillLinesEntities()

    self.buildCost = {}

    local list = BuildingService:GetBuildCosts( self.wallBlueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #self.linesEntities )
    end
end

function wall_pencil_tool:FindPositionsToBuildLine(wallLinesCount)

    local innerPositions = {}

    local topPositions = {}
    local rightPositions = {}
    local bottomPositions = {}
    local leftPositions = {}

    local cellSize = 2

    local center = wallLinesCount - 1

    for i=0,wallLinesCount-2 do

        local newPosition = {}

        newPosition.x = (wallLinesCount - 1) * cellSize - center
        newPosition.y = 0
        newPosition.z = i * cellSize - center

        Insert(topPositions, newPosition)
    end

    for i=0,wallLinesCount-2 do

        local newPosition = {}

        newPosition.x = (wallLinesCount - 1) * cellSize - i * cellSize - center
        newPosition.y = 0
        newPosition.z = (wallLinesCount - 1) * cellSize - center

        Insert(rightPositions, newPosition)
    end

    for i=0,wallLinesCount-2 do

        local newPosition = {}

        newPosition.x = - center
        newPosition.y = 0
        newPosition.z = (wallLinesCount - 1) * cellSize - i * cellSize - center

        Insert(bottomPositions, newPosition)
    end

    for i=0,wallLinesCount-2 do

        local newPosition = {}

        newPosition.x = i * cellSize - center
        newPosition.y = 0
        newPosition.z = - center

        Insert(leftPositions, newPosition)
    end

    for i=1,wallLinesCount-2 do

        local x = i * cellSize - center

        Insert(innerPositions, x)
    end

    return innerPositions, topPositions, rightPositions, bottomPositions, leftPositions
end

function wall_pencil_tool:AdjustEdgeList(list, newPositions, degreeCorner, degreeT)
    
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

function wall_pencil_tool:AdjustInnerList(gridArray, arrayX)
    
    local connectType = 16

    local blueprintName = self:GetBlueprintByConnectType( connectType )

    local positionX, positionZ

    if ( #gridArray > #arrayX ) then

        for xIndex=#gridArray,#arrayX + 1,-1 do

            local gridEntitiesZ = gridArray[xIndex]

            for zIndex=1,#gridEntitiesZ do

                EntityService:RemoveEntity(gridEntitiesZ[zIndex])

                gridEntitiesZ[zIndex] = nil
            end

            gridArray[xIndex] = nil
        end

    elseif ( #gridArray < #arrayX ) then

        for xIndex=#gridArray + 1 ,#arrayX do

            positionX = arrayX[xIndex]

            local gridEntitiesZ = {}

            gridArray[xIndex] = gridEntitiesZ

            for zIndex=1,#arrayX do

                positionZ = arrayX[zIndex]

                local newPosition = {}

                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ

                local lineEnt = EntityService:SpawnAndAttachEntity( blueprintName, self.selector )

                EntityService:RemoveComponent( lineEnt, "LuaComponent" )
                EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
                EntityService:SetPosition( lineEnt, newPosition)

                Insert(gridEntitiesZ, lineEnt)
            end
        end
    end

    for xIndex=1,#arrayX do

        positionX = arrayX[xIndex]

        local gridEntitiesZ = gridArray[xIndex]

        if ( #gridEntitiesZ > #arrayX ) then

            for zIndex=#gridEntitiesZ,#arrayX + 1,-1 do
                EntityService:RemoveEntity(gridEntitiesZ[zIndex])
                gridEntitiesZ[zIndex] = nil
            end

        elseif ( #gridEntitiesZ < #arrayX ) then

            for zIndex=#gridEntitiesZ + 1 ,#arrayX do

                positionZ = arrayX[zIndex]

                local newPosition = {}

                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ

                local lineEnt = EntityService:SpawnAndAttachEntity( blueprintName, self.selector )

                EntityService:RemoveComponent( lineEnt, "LuaComponent" )
                EntityService:ChangeMaterial( lineEnt, "selector/hologram_blue" )
                EntityService:SetPosition( lineEnt, newPosition)

                Insert(gridEntitiesZ, lineEnt)
            end
        end
    end

    for xIndex=1,#arrayX do

        positionX = arrayX[xIndex]

        local gridEntitiesZ = gridArray[xIndex]

        for zIndex=1,#arrayX do

            positionZ = arrayX[zIndex]

            local newPosition = {}

            newPosition.x = positionX
            newPosition.y = positionY
            newPosition.z = positionZ

            local lineEnt = gridEntitiesZ[zIndex]

            EntityService:SetPosition( lineEnt, newPosition)
        end
    end
end

function wall_pencil_tool:FillLinesEntities()

    self.linesEntities = {}

    for gridEntitiesZ in Iter(self.innerEntities) do

        for entity in Iter(gridEntitiesZ) do
            Insert(self.linesEntities, entity)
        end
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

function wall_pencil_tool:ClearList(list)

    for i=#list,1,-1 do

        local lineEnt = list[i]

        EntityService:RemoveEntity(lineEnt)

        list[i] = nil
    end
end

function wall_pencil_tool:OnUpdate()

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

function wall_pencil_tool:CheckConfigExists( wallLinesCount )

    wallLinesCount = wallLinesCount or 1

    if ( wallLinesCount < 1 ) then

        wallLinesCount = 1
    end

    return wallLinesCount
end

function wall_pencil_tool:OnActivateSelectorRequest()

    self.activated = true

    self:FinishLineBuild()
end

function wall_pencil_tool:FinishLineBuild()

    for i=1,#self.linesEntities do

        local lineEnt = self.linesEntities[i]

        local createCube = (i == 1)

        self:BuildEntity(lineEnt, createCube)
    end
end

function wall_pencil_tool:OnDeactivateSelectorRequest()

    self.activated = false
end

function wall_pencil_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentWallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    local newValue = currentWallLinesCount + change
    if( newValue < 1 ) then
        newValue = 1
    end

    self.wallLinesCount = newValue

    -- Wall layers config
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameWallsCount, newValue)

    self:SpawnGhostEntities()
end

function wall_pencil_tool:OnRelease()

    for gridEntitiesZ in Iter(self.innerEntities) do

        self:ClearList(gridEntitiesZ)
    end
    
    self:ClearList(self.topEntities)
    self:ClearList(self.rightEntities)
    self:ClearList(self.bottomEntities)
    self:ClearList(self.leftEntities)

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_pencil_tool