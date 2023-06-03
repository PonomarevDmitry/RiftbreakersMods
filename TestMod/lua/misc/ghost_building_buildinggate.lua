local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_buildinggate' ( ghost )

function ghost_building_buildinggate:__init()
    ghost.__init(self,self)
end

function ghost_building_buildinggate:OnInit()

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue")

    local transform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity , transform )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function ghost_building_buildinggate:OnUpdate()

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

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

                local lineEnt = gridEntitiesZ[zIndex]
                EntityService:SetPosition( lineEnt, newPosition )
                EntityService:SetOrientation( lineEnt, transform.orientation )

                LogService:Log("transform.orientation w " .. tostring(transform.orientation.w) .. " y " .. tostring(transform.orientation.y) )

                local id = (xIndex -1 ) * #arrayX + zIndex

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, false, id, false )

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

function ghost_building_buildinggate:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.ghostBlueprint ~= "" and self.ghostBlueprint ~= nil ) then

        result = EntityService:SpawnEntity( self.ghostBlueprint, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.blueprint, newPosition, team )
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    EntityService:ChangeMaterial( result, "selector/hologram_blue" )

    return result
end

function ghost_building_buildinggate:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

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

function ghost_building_buildinggate:GetXZSigns(positionStart, positionEnd)

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

function ghost_building_buildinggate:AddToEntitiesToSellList(testBuildable)

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

function ghost_building_buildinggate:BuildEntity(entity)

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
    elseif( testBuildable.flag == CBF_REPAIR ) then
        QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
    end

    return testBuildable.flag
end

function ghost_building_buildinggate:OnActivate()

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

function ghost_building_buildinggate:FinishLineBuild()

    if ( self.nowBuildingLine == nil ) then
        self.nowBuildingLine = false
    end

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        for i=1,count do

            local ghostEntity = allEntities[i]

            self:BuildEntity(ghostEntity)

            EntityService:RemoveEntity(ghostEntity)
        end
    end

    EntityService:SetVisible( self.entity , true )

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false
end

function ghost_building_buildinggate:GetAllEntities()

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

function ghost_building_buildinggate:OnDeactivate()

    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function ghost_building_buildinggate:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
        end
    end
end

function ghost_building_buildinggate:OnRelease()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghostEntity in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghostEntity)
            end
        end
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

return ghost_building_buildinggate