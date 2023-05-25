local wall_base_tool = require("lua/buildings/defense/wall_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_area_tool' ( wall_base_tool )

function wall_area_tool:__init()
    wall_base_tool.__init(self,self)
end

function wall_area_tool:OnInit()

    self.nowBuildingLine = false
    self.gridEntities = {}
end

function wall_area_tool:OnUpdate()

    self:RemoveMaterialFromOldBuildingsToSell()

    self.buildCost = {}

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)

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
                transform.scale = currentTransform.scale
                transform.orientation = currentTransform.orientation
                transform.position = newPosition

                local lineEnt = gridEntitiesZ[zIndex];
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetOrientation( lineEnt, transform.orientation )

                local id = (xIndex -1 ) * #arrayX + zIndex

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, id )

                if ( testBuildable ~= nil) then
                    self:AddToEntitiesToSellList(testBuildable)
                end

                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        local list = BuildingService:GetBuildCosts( self.wallBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ )
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.ghostWall, currentTransform )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end

        --BuildingService:CheckAndFixBuildingConnection(self.ghostWall)
    end

    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function wall_area_tool:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.ghostBlueprintName ~= "" and self.ghostBlueprintName ~= nil ) then

        result = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.wallBlueprintName, newPosition, team )
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    EntityService:ChangeMaterial( result, "selector/hologram_blue" )

    return result
end

function wall_area_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.ghostWall)

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

function wall_area_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.ghostWall )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall, false )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function wall_area_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function wall_area_tool:OnRotateSelectorRequest(evt)
end

function wall_area_tool:FinishLineBuild()

    if ( self.nowBuildingLine == nil ) then
        self.nowBuildingLine = false
    end

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        local step = count

        if ( count > 5 )  then
            local additionalCubesCount = math.ceil( count / 5 )
            step = math.ceil( count / additionalCubesCount)
        end

        for i=1,count do

            local createCube = ((i == 1) or (i == count) or (i % step == 0))

            local ghost = allEntities[i]

            self:BuildEntity(ghost, createCube)

            EntityService:RemoveEntity(ghost)
        end
    end

    EntityService:SetVisible( self.ghostWall, true )

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function wall_area_tool:GetAllEntities()

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

function wall_area_tool:OnRelease()

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

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_area_tool