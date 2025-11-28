local wall_base_tool = require("lua/buildings/defense/wall_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_obstacles_stairs_tool' ( wall_base_tool )

function wall_obstacles_stairs_tool:__init()
    wall_base_tool.__init(self,self)
end

function wall_obstacles_stairs_tool:OnInit()

    self:SpawnGhostWallEntity()

    self.nowBuildingLine = false
    self.gridEntities = {}

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.stairsBlueprintName = self:GetStairsBlueprintName( selectorDB )

    self:FillStairsTemplates( self.stairsBlueprintName )

    -- Marker with number of wall layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil

    self.configNameWallsConfig = "$wall_obstacles_lines_count"

    -- Wall layers config
    self.wallLinesCount = selectorDB:GetIntOrDefault(self.configNameWallsConfig, 1)
    self.wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function wall_obstacles_stairs_tool:GetStairsBlueprintName( selectorDB )

    local defaultStairs = "buildings/defense/wall_small_floor_01"

    local parameterName = "$selected_wall_small_floor_blueprint"

    local blueprintName = ""


    local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

            blueprintName = globalPlayerEntityDB:GetStringOrDefault(parameterName, defaultStairs)
        end
    end


    if ( blueprintName == "" ) then

        if ( selectorDB and selectorDB:HasString(parameterName) ) then

            blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultStairs)
        end
    end


    if ( blueprintName == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultStairs)
            end
        end
    end

    if ( blueprintName == "" ) then
        return defaultStairs
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultStairs
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultStairs
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultStairs
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return defaultStairs
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return defaultStairs
    end

    return blueprintName
end

function wall_obstacles_stairs_tool:FillStairsTemplates(stairsBlueprintName)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( stairsBlueprintName ) )
    
    self.stairsGhostBlueprintName = buildingDesc.ghost_bp
    self.stairsBuildingDesc = buildingDesc
end

function wall_obstacles_stairs_tool:OnUpdate()

    -- Wall layers config
    local wallLinesCount = self:CheckConfigExists(self.wallLinesCount)

    -- Correct Marker to show right number of wall layers
    if ( self.markerLinesConfig ~= wallLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local markerBlueprint = "misc/marker_selector_diagonal_wall_lines_" .. tostring( wallLinesCount )

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
        EntityService:SetPosition( self.currentMarkerLines, 0, 0, -2 )

        -- Save number of wall layers
        self.markerLinesConfig = wallLinesCount

        self:ClearGridEntities()
    end

    self:RemoveMaterialFromOldBuildingsToSell()

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local buildEndPosition = currentTransform.position

        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition )

        self.gridEntities = self.gridEntities or {}

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team, xIndex, zIndex, wallLinesCount)

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team, xIndex, zIndex, wallLinesCount)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        local hashBlueprintsNumber = {}

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

                self:RemoveUselessComponents(lineEnt)

                local buildingComponent = reflection_helper( EntityService:GetComponent( lineEnt, "BuildingComponent" ) )

                local blueprintName = buildingComponent.bp

                hashBlueprintsNumber[blueprintName] = (hashBlueprintsNumber[blueprintName] or 0) + 1

                local id = (xIndex -1 ) * #arrayX + zIndex

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, id )

                if ( testBuildable ~= nil) then
                    self:AddToEntitiesToSellList(testBuildable)
                end

                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        for blueprintName,blueprintCount in pairs( hashBlueprintsNumber ) do

            local list = self:GetBuildCosts( blueprintName )

            for resourceCost in Iter(list) do

                if ( self.buildCost[resourceCost.first] == nil ) then
                    self.buildCost[resourceCost.first] = 0
                end

                self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + resourceCost.second * blueprintCount
            end
        end
    else

        if ( self.ghostWall ~= nil ) then

            local currentTransform = EntityService:GetWorldTransform( self.ghostWall )
            local testBuildable = self:CheckEntityBuildable( self.ghostWall, currentTransform )

            if ( testBuildable ~= nil) then
                self:AddToEntitiesToSellList(testBuildable)
            end

            --BuildingService:CheckAndFixBuildingConnection(self.ghostWall)
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

function wall_obstacles_stairs_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = BuildingService:GetBuildCosts( blueprintName, self.playerId )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function wall_obstacles_stairs_tool:CreateNewEntity(newPosition, orientation, team, xIndex, zIndex, wallLinesCount)

    local result = nil

    local isStairs = self:IsLast(xIndex, wallLinesCount) or self:IsLast(zIndex, wallLinesCount)

    if ( isStairs ) then

        if ( self.stairsGhostBlueprintName ~= "" and self.stairsGhostBlueprintName ~= nil ) then

            result = EntityService:SpawnEntity( self.stairsGhostBlueprintName, newPosition, team )
        else
            result = EntityService:SpawnEntity( self.stairsBlueprintName, newPosition, team )
        end
    else

        if ( self.ghostBlueprintName ~= "" and self.ghostBlueprintName ~= nil ) then

            result = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
        else
            result = EntityService:SpawnEntity( self.wallBlueprintName, newPosition, team )
        end
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    self:ChangeEntityMaterial( result, "hologram/blue" )

    self:RemoveUselessComponents(result)

    return result
end

function wall_obstacles_stairs_tool:IsLast(index, wallLinesCount)

    return ( (index - 1) % (wallLinesCount + 1) == wallLinesCount )
end

function wall_obstacles_stairs_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)

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

function wall_obstacles_stairs_tool:CheckConfigExists( wallLinesCount )

    wallLinesCount = wallLinesCount or 1

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf(scaleWallLines, wallLinesCount )

    if ( index == nil ) then

        return scaleWallLines[1]
    end

    return wallLinesCount
end

function wall_obstacles_stairs_tool:GetWallConfigArray()

    if ( self.scaleWallLines == nil ) then

        self.scaleWallLines = {
            1,
            2,
            3,
            4,
            5,
            6,
        }
    end

    return self.scaleWallLines
end

function wall_obstacles_stairs_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform


        self:DestroyGhostWall()

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function wall_obstacles_stairs_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function wall_obstacles_stairs_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentLinesConfig = self:CheckConfigExists(self.wallLinesCount)

    local scaleWallLines = self:GetWallConfigArray()

    local index = IndexOf( scaleWallLines, currentLinesConfig )

    index = index or 1

    local maxIndex = #scaleWallLines

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = 1
    elseif( newIndex == 0 ) then
        newIndex = maxIndex
    end

    local newValue = scaleWallLines[newIndex]

    self.wallLinesCount = newValue

    -- Wall layers config
    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameWallsConfig, newValue)

    self:OnUpdate()
end

function wall_obstacles_stairs_tool:FinishLineBuild()

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

            local ghostEntity = allEntities[i]

            local buildingComponent = reflection_helper( EntityService:GetComponent( ghostEntity, "BuildingComponent" ) )

            local ignoreRandomRotation = (buildingComponent.bp == self.stairsBlueprintName or buildingComponent.bp == self.stairsGhostBlueprintName)

            self:BuildEntity(ghostEntity, createCube, ignoreRandomRotation)

            EntityService:RemoveEntity(ghostEntity)
        end
    end

    self:SpawnGhostWallEntity()

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function wall_obstacles_stairs_tool:GetAllEntities()

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

function wall_obstacles_stairs_tool:ClearGridEntities()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghostEntity in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghostEntity)
            end
        end
    end

    self.gridEntities = {}
end

function wall_obstacles_stairs_tool:OnRelease()

    self:ClearGridEntities()

    self.nowBuildingLine = false
    self.buildStartPosition = nil

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( wall_base_tool.OnRelease ) then
        wall_base_tool.OnRelease(self)
    end
end

return wall_obstacles_stairs_tool