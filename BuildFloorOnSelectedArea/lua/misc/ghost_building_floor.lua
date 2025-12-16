local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")

class 'ghost_building_floor' ( ghost )

function ghost_building_floor:__init()
    ghost.__init(self,self)
end

function ghost_building_floor:FindMinDistance()
    self.radius = BuildingService:FindEnergyRadius( self.blueprint )
    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max(bounds.x, bounds.z )
    end
end

function ghost_building_floor:OnInit()
    self.data:SetString("action", "floor")

    local scale_x = self.data:GetFloatOrDefault("resize_scale_x", 4)
    local scale_y = self.data:GetFloatOrDefault("resize_scale_y", 1)
    local scale_z = self.data:GetFloatOrDefault("resize_scale_z", 4)
    EntityService:SetScale( self.entity, scale_x, scale_y, scale_z )

    local infoChildSize = math.min(scale_x, 4)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -infoChildSize, 0, infoChildSize )

    self.nowBuildingLine = false
    self.gridEntities = {}

    self.currentSize = 0
    self.currentSizeMarker = nil
    self.currentSizeMarkerBlueprint = ""
end

function ghost_building_floor:FindBlueprint()
    local scale = EntityService:GetScale( self.entity )

    local next = 1
    if ( scale.x > 4 ) then
        next = 4
    else
        next = scale.x
    end

    for i=1,4 do
        local prevId = tostring(i)
        if ( string.find(self.blueprint, prevId) ) then
            local currentId = tostring(next)
            local blueprint = string.gsub( self.blueprint, prevId, currentId )
            return blueprint
        end
    end

    return self.blueprint
end

function ghost_building_floor:OnUpdate()

    self.buildCost = {}

    local currentScale = EntityService:GetScale(self.entity).x

    if ( self.currentSize ~= currentScale ) then

        if ( self.gridEntities ~= nil ) then
            for gridEntitiesZ in Iter(self.gridEntities) do
                for ghostEntity in Iter(gridEntitiesZ) do
                    EntityService:RemoveEntity(ghostEntity)
                end
            end
        end

        self.gridEntities = {}
        self.nowBuildingLine = false
        self.buildStartPosition = nil

        EntityService:SetVisible( self.entity , true )

        self.currentSize = currentScale

        local markerBlueprint = "misc/marker_selector_floor_size_" .. currentScale

        if ( currentScale > 16 ) then
            markerBlueprint = "misc/marker_selector_floor_size_g16"
        end

        if ( self.currentSizeMarkerBlueprint ~= markerBlueprint or self.currentSizeMarker == nil ) then

            -- Destroy old marker
            if (self.currentSizeMarker ~= nil) then

                EntityService:RemoveEntity(self.currentSizeMarker)
                self.currentSizeMarker = nil
            end

            self.currentSizeMarker = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

            EntityService:CreateComponent(self.currentSizeMarker, "EffectReferenceComponent")
        end
    end

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

                    local lineEnt = EntityService:SpawnEntity( self.ghostBlueprint, newPosition, team )
                    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale )

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

                    local lineEnt = EntityService:SpawnEntity( self.ghostBlueprint, newPosition, team )
                    EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale )

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
                transform.scale = {x=1,y=1,z=1}
                transform.orientation = currentTransform.orientation
                transform.position = newPosition

                local lineEnt = gridEntitiesZ[zIndex];
                EntityService:SetPosition( lineEnt, newPosition )
                EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale )

                local id = ( xIndex -1 ) * #arrayX + zIndex

                self:CheckEntityBuildable(lineEnt, transform, true, id, true)
            end
        end

        local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ * currentScale * currentScale )
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local testBuildable = self:CheckEntityBuildable( self.entity , currentTransform, true )
    end

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    end

    local infoChildSize = math.min(currentScale, 4)

    EntityService:SetPosition( self.infoChild, -infoChildSize, 0, infoChildSize )

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild , self.playerId, {} )
    end
end

function ghost_building_floor:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

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

function ghost_building_floor:GetXZSigns(positionStart, positionEnd)

    local xSign = -1
    local zSign = -1

    if ( positionEnd.x >= positionStart.x ) then
        xSign = 1
    end

    if ( positionEnd.z >= positionStart.z ) then
        zSign = 1
    end

    return xSign, zSign
end

function ghost_building_floor:OnActivate()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function ghost_building_floor:FinishLineBuild()

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    EntityService:SetVisible( self.entity, true )

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

        self:BuildFloorEntites(allEntities)
    end

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function ghost_building_floor:GetAllEntities()

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

function ghost_building_floor:BuildFloorEntites(floorEntities)

    local count = #floorEntities

    self.buildPosition = EntityService:GetWorldTransform( self.selector )

    local blueprintName = self:FindBlueprint()

    for i=1,count do

        local ghostEntity = floorEntities[i]

        local currentPosition = EntityService:GetWorldTransform( ghostEntity )

        QueueEvent( "BuildFloorRequest", self.entity, self.playerId, blueprintName, currentPosition )

        EntityService:RemoveEntity(ghostEntity)
    end
end

function ghost_building_floor:OnDeactivate()
    self.buildPosition = nil

    self:FinishLineBuild()
end

function ghost_building_floor:OnRelease()

    if ( self.gridEntities ~= nil ) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghostEntity in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghostEntity)
            end
        end
    end

    self.gridEntities = {}
    self.nowBuildingLine = false
    self.buildStartPosition = nil

    self.currentSize = 0
    self.currentSizeMarkerBlueprint = ""

    if (self.currentSizeMarker ~= nil) then

        EntityService:RemoveEntity(self.currentSizeMarker)
        self.currentSizeMarker = nil
    end

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( ghost.OnRelease ) then
        ghost.OnRelease(self)
    end
end

return ghost_building_floor