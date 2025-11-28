require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_base_tool' ( LuaEntityObject )

function wall_base_tool:__init()
    LuaEntityObject.__init(self,self)
end

function wall_base_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    if ( self.OnPreInit ) then
        self:OnPreInit()
    end

    self:InitializeValues()

    if ( self.OnInit ) then
        self:OnInit()
    end
end

function wall_base_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )
    EntityService:SetVisible( self.entity , false )

    self:CreateInfoChild()

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.wallBlueprintName = self:GetWallBlueprintName( selectorDB )

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( self.wallBlueprintName ) )

    self.ghostBlueprintName = buildingDesc.ghost_bp
    self.buildingDesc = buildingDesc

    self.randomRotation = 0

    local database = EntityService:GetBlueprintDatabase( self.wallBlueprintName )
    if ( database and database:HasInt("random_rotation") ) then

        self.randomRotation = database:GetIntOrDefault( "random_rotation", 0 )

        if ( self.randomRotation == 1 ) then

            local vector = { x=0, y=1, z=0 }

            self.randomOrientationArray = {
                CreateQuaternion( vector, 0 ),
                CreateQuaternion( vector, 90 ),
                CreateQuaternion( vector, 180 ),
                CreateQuaternion( vector, 270 )
            }
        end
    end
end

function wall_base_tool:CreateInfoChild()

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end
end

function wall_base_tool:GetWallBlueprintName( selectorDB )

    local defaultWall = "buildings/defense/wall_small_straight_01"

    local parameterName = "$selected_wall_small_blueprint"

    local blueprintName = ""


    local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

            blueprintName = globalPlayerEntityDB:GetStringOrDefault(parameterName, defaultWall)
        end
    end


    if ( blueprintName == "" ) then

        if ( selectorDB and selectorDB:HasString(parameterName) ) then

            blueprintName = selectorDB:GetStringOrDefault(parameterName, defaultWall)
        end
    end


    if ( blueprintName == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                blueprintName = campaignDatabase:GetStringOrDefault(parameterName, defaultWall)
            end
        end
    end

    if ( blueprintName == "" ) then
        return defaultWall
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultWall
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultWall
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultWall
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return defaultWall
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return defaultWall
    end

    return blueprintName
end

function wall_base_tool:SpawnGhostWallEntity()

    if ( self.ghostWall ~= nil) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local buildingEntity = EntityService:SpawnAndAttachEntity( self.ghostBlueprintName, self.selector )

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )
    self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

    self:RemoveUselessComponents(buildingEntity)

    self.ghostWall = buildingEntity
end

function wall_base_tool:RemoveUselessComponents(entity)

    if ( EntityService:HasComponent( entity, "DisplayRadiusComponent" ) ) then
        EntityService:RemoveComponent( entity, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( entity, "GhostLineCreatorComponent" ) ) then
        EntityService:RemoveComponent( entity, "GhostLineCreatorComponent" )
    end
end

function wall_base_tool:DestroyGhostWall()

    if ( self.ghostWall ~= nil) then
        EntityService:RemoveEntity(self.ghostWall)
        self.ghostWall = nil
    end
end

function wall_base_tool:OnWorkExecute()

    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function wall_base_tool:GetXZSigns(positionStart, positionEnd)

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

function wall_base_tool:AddToEntitiesToSellList(testBuildable)

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

function wall_base_tool:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function wall_base_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function wall_base_tool:CheckEntityBuildable( entity, transform, id )

    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprintName, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper(test:ToTypeInstance(), test )

    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

    local materialToSet = "hologram/blue"

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then

            materialToSet = "hologram/pass"

        else

            materialToSet = "hologram/deny"
        end
    else
        if ( canBuildOverride ) then

            materialToSet = "hologram/active"

        elseif ( canBuild ) then

            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end
    end

    self:ChangeEntityMaterial( entity, materialToSet )

    return testBuildable
end

function wall_base_tool:BuildEntity(entity, createCube, ignoreRandomRotation)

    createCube = createCube or false
    ignoreRandomRotation = ignoreRandomRotation or false

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity , transform )

    if ( testBuildable == nil ) then

        return
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count  == 1 ) then

            local singleMissingResource = missingResources[1]

            if ( self.announcements and self.announcements[singleMissingResource] ~= nil and self.announcements[singleMissingResource] ~= "" ) then

                soundAnnouncement = self.announcements[singleMissingResource]
            end
        end

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, self.playerEntity, false )

        return testBuildable.flag
    end

    if ( self.randomRotation == 1 and ignoreRandomRotation == false ) then
        transform.orientation = self.randomOrientationArray[RandInt(1,4)]
    end

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )

    elseif( testBuildable.flag == CBF_OVERRIDES ) then

        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )

    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function wall_base_tool:OnActivateSelectorRequest()
end

function wall_base_tool:OnDeactivateSelectorRequest()
end

function wall_base_tool:OnRotateSelectorRequest(evt)
end

function wall_base_tool:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
            local children = EntityService:GetChildren( entityToSell, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end
    self.oldBuildingsToSell = {}
end

function wall_base_tool:GetConnectType( blueprintName )

    for i=1,self.buildingDesc.connect.count do

        local connectRecord = self.buildingDesc.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( connectBlueprintName == blueprintName ) then
                return connectRecord.key
            end
        end
    end

    return -1
end

function wall_base_tool:GetBlueprintByConnectType( connectType )

    for i=1,self.buildingDesc.connect.count do

        local connectRecord = self.buildingDesc.connect[i]

        if ( connectRecord.key == connectType and connectRecord.value.count > 0 ) then

            local connectBlueprintName = connectRecord.value[1]

            local buildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( connectBlueprintName ) )

            return buildingDescRef.ghost_bp
        end
    end

    return self.buildingDesc.ghost_bp
end

function wall_base_tool:FindSingleDiagonalLine( buildStartPosition, buildEndPosition, positionPlayer )

    local xSignPlayer, zSignPlayer = self:GetXZSigns(positionPlayer, buildStartPosition)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local zPriority = (xSignPlayer * xSign) < 0 and (zSignPlayer * zSign) > 0

    local x0 = buildStartPosition.x
    local z0 = buildStartPosition.z

    local x1 = buildEndPosition.x
    local z1 = buildEndPosition.z

    local deltaX = 2 * xSign
    local deltaZ = 2 * zSign

    local dx = math.abs(x1 - x0)
    local dz = -math.abs(z1 - z0)

    local dzAbs = math.abs(z1 - z0)

    local result = {}

    local positionY = buildStartPosition.y

    local positionX = x0
    local positionZ = z0

    local error = dx + dz

    while ( true ) do

        local position = {}

        position.x = positionX
        position.y = positionY
        position.z = positionZ

        Insert(result, position)

        if ( positionX == x1 and positionZ == z1 ) then
            break
        end

        local errorMul2 = 2 * error

        if ( zPriority ) then

            if ( errorMul2 <= dx ) then
                if ( positionZ == z1 ) then
                    break
                end
                error = error +  dx
                positionZ = positionZ + deltaZ
                goto continue
            end

            if ( errorMul2 >= dz ) then
                if positionX == x1 then
                    break
                end
                error = error + dz
                positionX = positionX + deltaX
                goto continue
            end
        else

            if ( errorMul2 >= dz ) then
                if positionX == x1 then
                    break
                end
                error = error + dz
                positionX = positionX + deltaX
                goto continue
            end

            if ( errorMul2 <= dx ) then
                if ( positionZ == z1 ) then
                    break
                end
                error = error +  dx
                positionZ = positionZ + deltaZ
                goto continue
            end
        end

        ::continue::
    end

    return result
end

function wall_base_tool:OnRelease()

    self:RemoveMaterialFromOldBuildingsToSell()

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    self:DestroyGhostWall()
end

return wall_base_tool 