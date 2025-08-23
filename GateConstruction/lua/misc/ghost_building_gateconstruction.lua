require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_gateconstruction' ( LuaEntityObject )

function ghost_building_gateconstruction:__init()
    LuaEntityObject.__init(self,self)
end

function ghost_building_gateconstruction:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", {enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function ghost_building_gateconstruction:InitializeValues()
    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent"))
    self.blueprintName = buildingComponent.bp

    self.desc = reflection_helper(BuildingService:GetBuildingDesc( self.blueprintName ))

    Assert(self.desc ~= nil, "ERROR: " .. self.blueprintName .. " doesn't have BuildingDesc! It will crash now!")

    self.overrides = self.desc.overrides
    self.erases = self.desc.erase_type
    self.name = self.desc.name
    self.toCloseAnnoucement = self.desc.min_radius_effect
    self.ghostBlueprintName = self.desc.ghost_bp

    self.annoucements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    --showed_change_info
    if ( self.desc.rotate_info == true and ConsoleService:GetConfig( "showed_rotate_info" ) == "0" ) then
        self.rotateInfoChild = EntityService:SpawnAndAttachEntity("misc/rotate_info", self.entity )
    end

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )

    local transform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity, transform )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function  ghost_building_gateconstruction:CheckEntityBuildable( entity, transform, id )
    id = id or 1

    local test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.blueprintName, id )

    if ( test == nil ) then
        return
    end

    local testReflection = reflection_helper( test:ToTypeInstance(), test )

    --LogService:Log("Flag: " .. tostring(testReflection.flag ))
    --LogService:Log("Missing resources: " .. tostring(testReflection.missing_resources))
    --LogService:Log("Entity to repair: " .. tostring(testReflection.entity_to_repair )  )
    --LogService:Log("Entity to sell: " .. tostring(testReflection.entities_to_sell ))
    --LogService:Log("Free grids: " .. tostring(testReflection.free_grids ))


    local canBuildOverride = (testReflection.flag == CBF_OVERRIDES)
    local canBuild = (testReflection.flag == CBF_CAN_BUILD or testReflection.flag == CBF_ONE_GRID_FLOOR or testReflection.flag == CBF_OVERRIDES)

    local materialToSet = "hologram/blue"

    if ( testReflection.flag == CBF_REPAIR  ) then
        if ( BuildingService:CanAffordRepair( testReflection.entity_to_repair, self.playerId, -1 )) then

            materialToSet = "hologram/pass"

        else

            materialToSet = "hologram/deny"
        end
    else
        if ( canBuildOverride ) then

            materialToSet = "hologram/active"

        elseif ( canBuild  ) then

            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end
    end

    self:ChangeEntityMaterial( entity, materialToSet )

    return testReflection
end

function ghost_building_gateconstruction:OnWorkEnter()
end

function ghost_building_gateconstruction:OnWorkExit()
end

function ghost_building_gateconstruction:OnWorkExecute()
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function ghost_building_gateconstruction:OnUpdate()

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y

        local team = EntityService:GetTeam(self.entity)

        local currentTransform = EntityService:GetWorldTransform( self.entity )

        local exitVector = self:GetExitVector( currentTransform.orientation )

        local buildEndPosition = currentTransform.position

        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition )

        self.gridEntities = self.gridEntities or {}

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)

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

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)

                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end

        local boundsSize = { x=1.0, y=100.0, z=1.0 }

        local vectorBounds = VectorMulByNumber(boundsSize , 2)

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
                transform.position = newPosition

                transform.orientation = currentTransform.orientation

                local min = VectorSub(newPosition, vectorBounds)
                local max = VectorAdd(newPosition, vectorBounds)

                local possibleSelectedEnts = self:GetPosibleWalls( min, max )

                local invertTransform = self:IsInvertTransform( exitVector, possibleSelectedEnts, positionX, positionZ )

                if ( invertTransform ) then
                    transform.orientation = self:GetInvertedOrientation( exitVector.x, exitVector.z )
                end

                local lineEnt = gridEntitiesZ[zNumber]
                EntityService:SetPosition( lineEnt, newPosition )
                EntityService:SetOrientation( lineEnt, transform.orientation )

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, idCheckBuildable )

                idCheckBuildable = idCheckBuildable + 1

                if ( testBuildable ~= nil) then
                    self:AddToEntitiesToSellList(testBuildable)
                end

                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        local list = BuildingService:GetBuildCosts( self.blueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ )
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.entity , currentTransform )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end

        BuildingService:CheckAndFixBuildingConnection(self.entity)
    end

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -2, 0, 2)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function ghost_building_gateconstruction:IsInvertTransform( exitVector, possibleSelectedEnts, positionX, positionZ )

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

function ghost_building_gateconstruction:GetPosibleWalls( min, max )

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

function ghost_building_gateconstruction:GetInvertedOrientation( vectorX, vectorZ )

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

function ghost_building_gateconstruction:GetExitVector( orientation )

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

function ghost_building_gateconstruction:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.ghostBlueprintName ~= "" and self.ghostBlueprintName ~= nil ) then

        result = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.blueprintName, newPosition, team )
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    self:ChangeEntityMaterial( result, "hologram/blue" )

    return result
end

function ghost_building_gateconstruction:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

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

function ghost_building_gateconstruction:GetXZSigns(positionStart, positionEnd)

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

function ghost_building_gateconstruction:AddToEntitiesToSellList(testBuildable)

    if( testBuildable == nil or testBuildable.flag ~= CBF_OVERRIDES ) then

        return
    end

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell ~= nil and EntityService:IsAlive( entityToSell) ) then

            if ( IndexOf( self.oldBuildingsToSell, entityToSell ) == nil ) then

                self:SetEntitySelectedMaterial( entityToSell, "hologram/active" )

                Insert(self.oldBuildingsToSell, entityToSell)
            end
        end
    end
end

function ghost_building_gateconstruction:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function ghost_building_gateconstruction:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function ghost_building_gateconstruction:BuildEntity(entity)

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity , transform )

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
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true, {} )
    elseif( testBuildable.flag == CBF_OVERRIDES ) then
        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent( "SellBuildingRequest", entityToSell, self.playerId, false )
        end
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true, {} )
    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function ghost_building_gateconstruction:OnActivateSelectorRequest()

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

function ghost_building_gateconstruction:OnDeactivateSelectorRequest()

    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function ghost_building_gateconstruction:OnRotateSelectorRequest()
    if (self.rotateInfoChild ~= nil and EntityService:IsAlive(self.rotateInfoChild ) ) then
        EntityService:RemoveEntity(self.rotateInfoChild)
        self.rotateInfoChild = nil
        ConsoleService:ExecuteCommand( "showed_rotate_info 1" )
    end
end

function ghost_building_gateconstruction:FinishLineBuild()

    self.nowBuildingLine = self.nowBuildingLine or false

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

function ghost_building_gateconstruction:GetAllEntities()

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

function ghost_building_gateconstruction:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial( entityToSell, "selected" )
            local children = EntityService:GetChildren( entityToSell, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end
end

function ghost_building_gateconstruction:OnRelease()

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

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end
end

return ghost_building_gateconstruction