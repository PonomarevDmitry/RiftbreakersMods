local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building' ( ghost )

function ghost_building:__init()
    ghost.__init(self,self)
end

function ghost_building:OnInit()

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector)
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue")
    local transform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity, transform )
    self:RegisterHandler( INVALID_ID, "StartBuildingEvent", "OnBuildingStartEvent" )

    self.originalGhostBlueprint = self.ghostBlueprint

    self.ghostBlueprint = self.data:GetStringOrDefault("building_blueprint", "")
    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z )

    local typeName = ""
    if( self.desc ~= nil ) then
        typeName = self.desc.type
    end

    self.cellsMinRadius = 0

    if ( self.desc ~= nil and self.desc.min_radius ~= nil and self.desc.min_radius ~= 0 ) then

        local maxSize = math.max(gridSize.x, gridSize.z)

        while ((maxSize + self.cellsMinRadius) * 2 < self.desc.min_radius) do

            self.cellsMinRadius = self.cellsMinRadius + 1
        end
    end

    local lowName = BuildingService:FindLowUpgrade( self.blueprint )
    if ( lowName == "repair_facility" ) then
        typeName = "tower"
    end

    self.isBuildingWithGaps = false

    local buildWithGaps = ( typeName == "tower" and mod_build_towers_with_gaps ~= nil and mod_build_towers_with_gaps == 1 ) or ( typeName == "trap" and mod_build_traps_with_gaps ~= nil and mod_build_traps_with_gaps == 1 )

    if ( buildWithGaps ) then

        self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

        self.isBuildingWithGaps = true

        self.configNameCellGaps = "$" .. typeName .. "s_" .. lowName .. "_construction_cell_count"

        local selectorDB = EntityService:GetDatabase( self.selector )

        self.cellGapsCount = selectorDB:GetIntOrDefault(self.configNameCellGaps, 0)
        self.cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

        self.markerGapsConfig = -1
        self.currentMarkerGaps = nil
    end

    self.isBuildingGate = false
    if ( lowName == "wall_gate" and mod_building_gateconstruction ~= nil and mod_building_gateconstruction == 1 ) then
        self.isBuildingGate = true
    end

    if ( mod_ghost_building_count ~= nil and mod_ghost_building_count == 1 ) then
        self.currentMarkerBuildingCount = EntityService:SpawnAndAttachEntity( "misc/ghost_building_menu", self.selector )
        EntityService:SetPosition( self.currentMarkerBuildingCount, -gridSize.x, 0, gridSize.z )
    end
end

function ghost_building:OnBuildingStartEvent( evt )
    local playerReferenceComponent = EntityService:GetComponent( evt:GetEntity(), "PlayerReferenceComponent")
    local owner = -1
    if (playerReferenceComponent) then
        local helper = reflection_helper(playerReferenceComponent)
        owner = helper.player_id
    end
    if ( owner ~= self.playerId or not self.activated) then
        return
    end

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    local transform = EntityService:GetWorldTransform( evt:GetEntity() )
    self:SetLastBuildSpot(transform)
end

function ghost_building:SetLastBuildSpot(transform)
    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item == nil ) then item = container:CreateItem() end

    local itemHelper = reflection_helper(item)
    itemHelper.x = transform.position.x
    itemHelper.y = transform.position.y
    itemHelper.z = transform.position.z
end

function ghost_building:OnUpdate()

    local cellGapsCount = 0

    if ( self.isBuildingWithGaps ) then

        cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

        -- Correct Marker to show right number of wall layers
        if ( self.markerGapsConfig ~= cellGapsCount or self.currentMarkerGaps == nil) then

            -- Destroy old marker
            if (self.currentMarkerGaps ~= nil) then

                EntityService:RemoveEntity(self.currentMarkerGaps)
                self.currentMarkerGaps = nil
            end

            local markerBlueprint = "misc/marker_selector_gaps_count_" .. tostring( cellGapsCount )

            -- Create new marker
            self.currentMarkerGaps = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

            EntityService:SetPosition( self.currentMarkerGaps, 0, 0, -2 )

            -- Save number of wall layers
            self.markerGapsConfig = cellGapsCount
        end
    end

    cellGapsCount = cellGapsCount + self.cellsMinRadius

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local buildEndPosition = currentTransform.position

        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition, cellGapsCount )

        self.gridEntities = self.gridEntities or {}

        local entityOrientation = currentTransform.orientation

        if ( self.isBuildingWithGaps ) then
            entityOrientation = self.buildStartPosition.orientation

            EntityService:SetOrientation( self.entity, entityOrientation )
        end

        local positionX, positionZ

        if ( #self.gridEntities > #arrayX ) then

            for xNumber=#self.gridEntities,#arrayX + 1,-1 do

                local gridEntitiesZ = self.gridEntities[xNumber]

                for zNumber=1,#gridEntitiesZ do

                    EntityService:RemoveEntity(gridEntitiesZ[zNumber])

                    gridEntitiesZ[zNumber] = nil
                end

                self.gridEntities[xNumber] = nil
            end

        elseif ( #self.gridEntities < #arrayX ) then

            for xNumber=#self.gridEntities + 1,#arrayX do

                positionX = arrayX[xNumber]

                local gridEntitiesZ = {}

                self.gridEntities[xNumber] = gridEntitiesZ

                for zNumber=1,#arrayZ do

                    positionZ = arrayZ[zNumber]

                    local newPosition = {}

                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = self:CreateNewEntity(newPosition, entityOrientation, team)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        for xNumber=1,#arrayX do

            positionX = arrayX[xNumber]

            local gridEntitiesZ = self.gridEntities[xNumber]

            if ( #gridEntitiesZ > #arrayZ ) then

                for zNumber=#gridEntitiesZ,#arrayZ + 1,-1 do
                    EntityService:RemoveEntity(gridEntitiesZ[zNumber])
                    gridEntitiesZ[zNumber] = nil
                end

            elseif ( #gridEntitiesZ < #arrayZ ) then

                for zNumber=#gridEntitiesZ + 1,#arrayZ do

                    positionZ = arrayZ[zNumber]

                    local newPosition = {}

                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = self:CreateNewEntity(newPosition, entityOrientation, team)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        local boundsSize = { x=1.0, y=100.0, z=1.0 }

        local vectorBounds = VectorMulByNumber(boundsSize , 2)

        local exitVector = self:GetExitVector( entityOrientation )

        local idCheckBuildable = 1

        local countBuildable = 0

        for xNumber=1,#arrayX do

            positionX = arrayX[xNumber]

            local gridEntitiesZ = self.gridEntities[xNumber]

            for zNumber=1,#arrayZ do

                positionZ = arrayZ[zNumber]

                local newPosition = {}

                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ

                local orientation = entityOrientation

                if ( self.isBuildingGate ) then

                    local min = VectorSub(newPosition, vectorBounds)
                    local max = VectorAdd(newPosition, vectorBounds)

                    local possibleSelectedEnts = self:GetPosibleWalls( min, max )

                    local invertTransform = self:IsInvertTransform( exitVector, possibleSelectedEnts, positionX, positionZ )

                    if ( invertTransform ) then
                        orientation = self:GetInvertedOrientation( exitVector.x, exitVector.z )
                    end
                end

                local transform = {}
                transform.scale = currentTransform.scale
                transform.orientation = orientation
                transform.position = newPosition

                local lineEnt = gridEntitiesZ[zNumber]
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetOrientation( lineEnt, orientation )

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, false, idCheckBuildable, false, true )

                idCheckBuildable = idCheckBuildable + 1

                if ( testBuildable ~= nil) then

                    self:AddToEntitiesToSellList(testBuildable)

                    if ( testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_OVERRIDES or ( testBuildable.missing_resources and testBuildable.missing_resources.count > 0 ) ) then

                        countBuildable = countBuildable + 1
                    end
                end

                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        if ( countBuildable > 0 ) then

            local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
            for resourceCost in Iter(list) do

                if ( self.buildCost[resourceCost.first] == nil ) then
                   self.buildCost[resourceCost.first] = 0
                end

                self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * countBuildable )
            end
        end

        self:UpdateBuildingCount( #arrayX * #arrayZ )
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.entity, currentTransform, false )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end

        BuildingService:CheckAndFixBuildingConnection(self.entity)

        self:UpdateBuildingCount( 0 )
    end

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    if ( self.infoChild == nil ) then

        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    end

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)
    
    EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z)
    if ( self.currentMarkerBuildingCount ~= nil ) then
        EntityService:SetPosition( self.currentMarkerBuildingCount, -gridSize.x, 0, gridSize.z)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function ghost_building:UpdateBuildingCount( buildingCount )

    if ( self.currentMarkerBuildingCount == nil) then
        return
    end

    local markerDB = EntityService:GetDatabase( self.currentMarkerBuildingCount )

    if ( markerDB == nil ) then
        return
    end

    if ( buildingCount == 0 ) then

        markerDB:SetInt("building_visible", 0)
        markerDB:SetString("message_text", "")
        return
    end

    
    local menuIcon = self.desc.menu_icon
    
    local messageText = '<img="' .. menuIcon .. '">x' .. tostring(buildingCount)

    markerDB:SetInt("building_visible", 1)
    markerDB:SetString("message_text", messageText)
end

function ghost_building:IsInvertTransform( exitVector, possibleSelectedEnts, positionX, positionZ )

    local diffs = { 1, -1 }

    local wallPlacement = {}

    for diffX in Iter( diffs ) do

        wallPlacement[diffX] = wallPlacement[diffX] or {}

        for diffZ in Iter( diffs ) do

            wallPlacement[diffX][diffZ] = false
        end
    end

    for entity in Iter( possibleSelectedEnts ) do

        local entityPosition = EntityService:GetPosition( entity )

        local diffX = entityPosition.x - positionX
        local diffZ = entityPosition.z - positionZ

        wallPlacement[diffX] = wallPlacement[diffX] or {}

        wallPlacement[diffX][diffZ] = true
    end

    for diffX in Iter( diffs ) do

        for diffZ in Iter( diffs ) do

            local mult = diffX * exitVector.x + diffZ * exitVector.z

            if ( mult > 0 and wallPlacement[diffX][diffZ] ) then

                return false
            end
        end
    end

    for diffX in Iter( diffs ) do

        for diffZ in Iter( diffs ) do

            local mult = diffX * exitVector.x + diffZ * exitVector.z

            if ( mult < 0 and wallPlacement[diffX][diffZ] ) then

                return true
            end
        end
    end

    return false
end

function ghost_building:GetPosibleWalls( min, max )

    self.suffixGhost = self.suffixGhost or "ghost"

    local result = {}

    local possibleSelectedEnts = FindService:FindGridOwnersByBox( min, max )

    for entity in Iter( possibleSelectedEnts ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        if ( blueprintName:sub(-#self.suffixGhost) == self.suffixGhost ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName == "wall_small_floor" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingRef = reflection_helper(buildingDesc)

        if ( buildingRef.type ~= "wall" or buildingRef.category == "decorations" ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function ghost_building:GetInvertedOrientation( vectorX, vectorZ )

    self.cacheInverted = self.cacheInverted or {}

    self.cacheInverted[vectorX] = self.cacheInverted[vectorX] or {}

    if ( self.cacheInverted[vectorX][vectorZ] ) then

        return self.cacheInverted[vectorX][vectorZ]
    end

    local result = {}
    result.x = 0
    result.z = 0

    -- GetExitVector    exitVector.x   1    exitVector.z   0      orientation.y 2.0861625671387e-07     orientation.w -1.0000001192093
    -- GetExitVector    exitVector.x  -1    exitVector.z   0      orientation.y 1.0000001192093         orientation.w 2.3841857910156e-07

    -- GetExitVector    exitVector.x   0    exitVector.z   1      orientation.y 0.70710700750351        orientation.w -0.70710670948029
    -- GetExitVector    exitVector.x   0    exitVector.z  -1      orientation.y -0.70710676908493       orientation.w -0.70710694789886

    -- GetExitVector    exitVector.x   1    exitVector.z   0      orientation.y 0                       orientation.w -1
    -- GetExitVector    exitVector.x  -1    exitVector.z   0      orientation.y 1                       orientation.w 0

    -- GetExitVector    exitVector.x   0    exitVector.z   1      orientation.y 0.707107                orientation.w -0.707107
    -- GetExitVector    exitVector.x   0    exitVector.z  -1      orientation.y -0.707107               orientation.w -0.707107


    if ( vectorX == 1 ) then

        result.y = 1
        result.w = 0

    elseif ( vectorX == -1 ) then

        result.y = 0
        result.w = -1

    elseif ( vectorZ == 1 ) then

        result.y = -0.707107
        result.w = -0.707107

    elseif ( vectorZ == -1 ) then

        result.y = 0.707107
        result.w = -0.707107
    end

    self.cacheInverted[vectorX][vectorZ] = result

    return result
end

function ghost_building:GetExitVector( orientation )

    local result = { x = 1, z = 0 }

    if ( -0.01 <= orientation.y and orientation.y <= 0.01 ) then

        result = { x = 1, z = 0 }

    elseif ( -0.01 <= orientation.w and orientation.w <= 0.01 ) then

        result = { x = -1, z = 0 }

    elseif ( 0.5 <= orientation.y ) then

        if ( 0 < orientation.w ) then

            result = { x = 0, z = -1 }

        elseif ( orientation.w < 0 ) then

            result = { x = 0, z = 1 }
        end

    elseif ( orientation.y <= -0.5 ) then

        if ( 0 < orientation.w ) then

            result = { x = 0, z = 1 }

        elseif ( orientation.w < 0 ) then

            result = { x = 0, z = -1 }
        end
    end

    return result
end

function ghost_building:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.originalGhostBlueprint ~= "" and self.originalGhostBlueprint ~= nil ) then

        result = EntityService:SpawnEntity( self.originalGhostBlueprint, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.blueprint, newPosition, team )
    end

    if ( EntityService:HasComponent( result, "DisplayRadiusComponent" ) ) then

        EntityService:RemoveComponent( result, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( result, "GhostLineCreatorComponent" ) ) then

        EntityService:RemoveComponent( result, "GhostLineCreatorComponent" )
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    EntityService:ChangeMaterial( result, "selector/hologram_blue" )

    return result
end

function ghost_building:FindPositionsToBuildLine(buildStartPosition, buildEndPosition, cellGapsCount)

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local deltaX = (gridSize.x + cellGapsCount) * 2 * xSign
    local deltaZ = (gridSize.z + cellGapsCount) * 2 * zSign

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

function ghost_building:GetXZSigns(positionStart, positionEnd)

    local xSign = -1
    local zSign = -1

    if( positionEnd.x >= positionStart.x ) then
        xSign = 1
    end

    if( positionEnd.z >= positionStart.z ) then
        zSign = 1
    end

    return xSign, zSign
end

function ghost_building:AddToEntitiesToSellList(testBuildable)

    if( testBuildable == nil or testBuildable.flag ~= CBF_OVERRIDES ) then

        return
    end

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell ~= nil and EntityService:IsAlive( entityToSell) ) then

            if ( IndexOf( self.oldBuildingsToSell, entityToSell ) == nil ) then

                local skinned = EntityService:IsSkinned(entityToSell)

                if ( skinned ) then
                    EntityService:SetMaterial( entityToSell, "selector/hologram_active_skinned", "selected")
                else
                    EntityService:SetMaterial( entityToSell, "selector/hologram_active", "selected")
                end

                Insert(self.oldBuildingsToSell, entityToSell)
            end
        end
    end
end

function ghost_building:BuildEntity(entity, idCheckBuildable)

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity, transform, false, idCheckBuildable, false, true )

    if ( testBuildable == nil ) then

        return
    end

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        if ( self.toCloseAnnoucement ~= "" ) then
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.toCloseAnnoucement, self.playerEntity, false )
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", self.playerEntity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count == 1 ) then

            local singleMissingResource = missingResources[1]

            if ( self.annoucements and self.annoucements[singleMissingResource] ~= nil and self.annoucements[singleMissingResource] ~= "" ) then

                soundAnnouncement = self.annoucements[singleMissingResource]
            end
        end

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, self.playerEntity, false )

        return testBuildable.flag
    end

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_OVERRIDES ) then
        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent( "SellBuildingRequest", entityToSell, self.playerId, false )
        end
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function ghost_building:OnActivate()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity, false )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function ghost_building:FinishLineBuild()

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        if ( self.desc ~= nil and self.desc.limit ~= nil and self.desc.limit > 0 ) then

            local delimiterEntities = "|"

            local entitiesListArray = {}

            for entityId in Iter( allEntities ) do

                if ( #entitiesListArray > 0 ) then

                    Insert( entitiesListArray, delimiterEntities )
                end

                local entityString = tostring(entityId)

                Insert( entitiesListArray, entityString )
            end

            local entitiesListString = table.concat( entitiesListArray )

            local builder = EntityService:SpawnEntity( "misc/mass_limited_buildings_builder", self.entity, "" )

            local database = EntityService:GetDatabase( builder )

            database:SetInt( "playerId", self.playerId )

            database:SetString( "entities_list", entitiesListString )

        else

            for i=1,count do

                local ghostEntity = allEntities[i]

                self:BuildEntity(ghostEntity, i)

                EntityService:RemoveEntity(ghostEntity)
            end
        end
    end

    EntityService:SetVisible( self.entity, true )

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false
end

function ghost_building:GetAllEntities()

    local result = {}

    for xNumber=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xNumber]

        for zNumber=1,#gridEntitiesZ do

            local entity = gridEntitiesZ[zNumber]

            Insert(result, entity)
        end
    end

    return result
end

function ghost_building:ClearLastBuildPos()
    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item ~= nil ) then
         container:EraseItem(0)
    end
end

function ghost_building:OnDeactivate()
    self:ClearLastBuildPos()

    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function ghost_building:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
        end
    end
end

function ghost_building:OnRotateSelectorRequest(evt)

    if ( ghost.OnRotateSelectorRequest ) then

        ghost.OnRotateSelectorRequest(self, evt)
    end

    if ( not self.isBuildingWithGaps ) then
        return
    end

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( not self.nowBuildingLine ) then
        return
    end

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentGapsConfig = self:CheckConfigExists(self.cellGapsCount)

    local scaleWallGaps = self:GetGapsConfigArray()

    local index = IndexOf( scaleWallGaps, currentGapsConfig )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #scaleWallGaps

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = scaleWallGaps[newIndex]

    self.cellGapsCount = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:OnUpdate()
end

function ghost_building:CheckConfigExists( cellGapsCount )

    local scaleWallGaps = self:GetGapsConfigArray()

    cellGapsCount = cellGapsCount or scaleWallGaps[1]

    local index = IndexOf(scaleWallGaps, cellGapsCount )

    if ( index == nil ) then

        return scaleWallGaps[1]
    end

    return cellGapsCount
end

function ghost_building:GetGapsConfigArray()

    if ( self.scaleWallGaps == nil ) then

        self.scaleWallGaps = {
            0,
            1,
            2,
            3,
            4,
            5,
            6,
        }
    end

    return self.scaleWallGaps
end

function ghost_building:OnRelease()
    self:ClearLastBuildPos()

    HideBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghostEntity in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghostEntity)
            end
        end
    end

    -- Destroy Marker with layers count
    if (self.currentMarkerGaps ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerGaps)
        self.currentMarkerGaps = nil
    end

    if ( self.currentMarkerBuildingCount ~= nil) then
        EntityService:RemoveEntity(self.currentMarkerBuildingCount)
        self.currentMarkerBuildingCount = nil
    end

    self.gridEntities = {}
    self.nowBuildingLine = false
    self.buildStartPosition = nil

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( ghost.OnRelease ) then
        ghost.OnRelease(self)
    end
end

return ghost_building