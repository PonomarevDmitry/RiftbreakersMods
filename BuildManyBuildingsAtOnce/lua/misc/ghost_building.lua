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
    self:CheckEntityBuildable( self.entity , transform )
    self:RegisterHandler( INVALID_ID, "StartBuildingEvent", "OnBuildingStartEvent" )

    self.originalGhostBlueprint = self.ghostBlueprint

    self.ghostBlueprint = self.data:GetStringOrDefault("building_blueprint", "")
    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    local typeName = ""
    local buildingDesc = BuildingService:GetBuildingDesc( self.blueprint )
    if( buildingDesc ~= nil ) then
        local buildingDescHelper = reflection_helper(buildingDesc)
        typeName = buildingDescHelper.type
    end

    self.isBuildingWithGaps = false

    if ( mod_build_with_gaps ~= nil and mod_build_with_gaps == 1 ) then

        if ( typeName == "tower" or typeName == "trap" ) then

            self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

            self.isBuildingWithGaps = true

            local lowName = BuildingService:FindLowUpgrade( self.blueprint )

            self.configNameCellGaps = "$" .. typeName .. "s_" .. lowName .. "_construction_cell_count"

            local selectorDB = EntityService:GetDatabase( self.selector )

            self.cellGapsCount = selectorDB:GetIntOrDefault(self.configNameCellGaps, 0)
            self.cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

            self.markerGapsConfig = -1
            self.currentMarkerGaps = nil
        end
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

            EntityService:SetPosition( self.currentMarkerGaps, -2, 0, 0 )

            -- Save number of wall layers
            self.markerGapsConfig = cellGapsCount
        end
    end



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

            for xNumber=#self.gridEntities + 1 ,#arrayX do

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

                for zNumber=#gridEntitiesZ + 1 ,#arrayZ do

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

        local idCheckBuildable = 1

        for xNumber=1,#arrayX do

            positionX = arrayX[xNumber]

            local gridEntitiesZ = self.gridEntities[xNumber]

            for zNumber=1,#arrayZ do

                positionZ = arrayZ[zNumber]

                local newPosition = {}

                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ

                local transform = {}
                transform.scale = currentTransform.scale
                transform.orientation = entityOrientation
                transform.position = newPosition

                local lineEnt = gridEntitiesZ[zNumber]
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetOrientation( lineEnt, entityOrientation )

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, false, idCheckBuildable, false )

                idCheckBuildable = idCheckBuildable + 1

                if ( testBuildable ~= nil) then
                    self:AddToEntitiesToSellList(testBuildable)
                end

                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ )
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.entity , currentTransform, false )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end

        BuildingService:CheckAndFixBuildingConnection(self.entity)
    end

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function ghost_building:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.originalGhostBlueprint ~= "" and self.originalGhostBlueprint ~= nil ) then

        result = EntityService:SpawnEntity( self.originalGhostBlueprint, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.blueprint, newPosition, team )
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

function ghost_building:BuildEntity(entity)

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity , transform, false )

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
        local healthComponent = EntityService:GetComponent(testBuildable.entity_to_repair, "HealthComponent")
        if ( healthComponent ~= nil ) then

            local healthComponentRef = reflection_helper(healthComponent)

            if ( healthComponentRef.health < healthComponentRef.max_health ) then
                QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
            end
        end
    end

    return testBuildable.flag
end

function ghost_building:OnActivate()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )

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

                self:BuildEntity(ghostEntity)

                EntityService:RemoveEntity(ghostEntity)
            end
        end
    end

    EntityService:SetVisible( self.entity , true )

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

    if ( not self.isBuildingWithGaps ) then
        return;
    end

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( not self.nowBuildingLine ) then
        return;
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
        newIndex = 1
    elseif( newIndex == 0 ) then
        newIndex = maxIndex
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