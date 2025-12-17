local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_portal_construction' ( ghost )

function ghost_building_portal_construction:__init()
    ghost.__init(self,self)
end

function ghost_building_portal_construction:FindMinDistance()
    self.radius = BuildingService:FindEnergyRadius( self.blueprint )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max(bounds.x, bounds.z ) / 2.0
    end
end

function ghost_building_portal_construction:OnInit()
    -- action line
    self.data:SetString("action", "portal_construction")

    self:FindMinDistance()
    
    self:RegisterHandler( INVALID_ID, "StartBuildingEvent", "OnBuildingStartEvent" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    ShowBuildingDisplayRadiusAround( self.entity, self.blueprint )
    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    self:FillArrays()

    self.configName = "ghost_building_portal_construction_config"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedMode = selectorDB:GetStringOrDefault(self.configName, "none")
    self.selectedMode = self:CheckModeValueExists(self.selectedMode)

    selectorDB:SetString(self.configName, self.selectedMode)

    self.currentModeValuesArray = self:CreateModeValuesArray()

    self.linesEntities = {}

    self:UpdateGhostEntities()
end

function ghost_building_portal_construction:FillArrays()

    self.modeValuesArray = {

        "none",
        "wall_small",
        "wall_energy",
        "wall_crystal",
        "wall_vine"
    }

    self.wallConfig = {
    
        ["wall_small"] = "buildings/defense/wall_small_straight_01",

        ["wall_energy"] = "buildings/defense/wall_energy_straight_01",

        ["wall_crystal"] = "buildings/defense/wall_crystal_straight_01",

        ["wall_vine"] = "buildings/defense/wall_vine_straight_01",
    }

    self.gateConfig = {
    
        ["wall_small"] = "buildings/defense/wall_gate",

        ["wall_energy"] = "buildings/defense/wall_gate_energy",

        ["wall_crystal"] = "buildings/defense/wall_gate_crystal",
    }

    self.gatePositions = {
    
        {
            x = 0,
            y = 0,
            z = -4,
            degree = 90,
        },
    
        {
            x = -4,
            y = 0,
            z = 0,
            degree = 180,
        },
    
        {
            x = 0,
            y = 0,
            z = 4,
            degree = 270,
        },
    
        {
            x = 4,
            y = 0,
            z = 0,
            degree = 0,
        },
    }

    self.wallPositions = {

        ["_x_"] = {

            {
                x = -3,
                y = 0,
                z = -3,
                degree = 0,
            },

            {
                x = 3,
                y = 0,
                z = -3,
                degree = 0,
            },

            {
                x = 3,
                y = 0,
                z = 3,
                degree = 0,
            },

            {
                x = -3,
                y = 0,
                z = 3,
                degree = 0,
            },
        },

        ["_t_"] = {

            {
                x = -5,
                y = 0,
                z = -3,
                degree = 0,
            },

            {
                x = -5,
                y = 0,
                z = 3,
                degree = 0,
            },



            {
                x = -3,
                y = 0,
                z = -5,
                degree = 270,
            },

            {
                x = 3,
                y = 0,
                z = -5,
                degree = 270,
            },



            {
                x = 5,
                y = 0,
                z = -3,
                degree = 180,
            },

            {
                x = 5,
                y = 0,
                z = 3,
                degree = 180,
            },



            {
                x = 3,
                y = 0,
                z = 5,
                degree = 90,
            },

            {
                x = -3,
                y = 0,
                z = 5,
                degree = 90,
            },
        },

        ["corner"] = {

            {
                x = -5,
                y = 0,
                z = -5,
                degree = 0,
            },

            {
                x = 5,
                y = 0,
                z = -5,
                degree = 270,
            },

            {
                x = 5,
                y = 0,
                z = 5,
                degree = 180,
            },

            {
                x = -5,
                y = 0,
                z = 5,
                degree = 90,
            },
        },
    }

    self.vineWallsPositions = {
    
        {
            x = -1,
            y = 0,
            z = -3,
        },
        
        {
            x = 1,
            y = 0,
            z = -3,
        },
        
        
        
        {
            x = 3,
            y = 0,
            z = -1,
        },
        
        {
            x = 3,
            y = 0,
            z = 1,
        },
        
        
        
        {
            x = 1,
            y = 0,
            z = 3,
        },
        
        {
            x = -1,
            y = 0,
            z = 3,
        },
        
        
        
        {
            x = -3,
            y = 0,
            z = 1,
        },
        
        {
            x = -3,
            y = 0,
            z = -1,
        },
    
        -- corners

        {
            x = -3,
            y = 0,
            z = -3,
        },
        
        {
            x = 3,
            y = 0,
            z = -3,
        },
        
        {
            x = 3,
            y = 0,
            z = 3,
        },
        
        {
            x = -3,
            y = 0,
            z = 3,
        },
    
        -- second line

        {
            x = -1,
            y = 0,
            z = -5,
        },
        
        {
            x = 1,
            y = 0,
            z = -5,
        },
        
        
        
        {
            x = 5,
            y = 0,
            z = -1,
        },
        
        {
            x = 5,
            y = 0,
            z = 1,
        },
        
        
        
        {
            x = -1,
            y = 0,
            z = 5,
        },
        
        {
            x = 1,
            y = 0,
            z = 5,
        },
        
        
        
        {
            x = -5,
            y = 0,
            z = -1,
        },
        
        {
            x = -5,
            y = 0,
            z = 1,
        },
    
        -- second line 2

        {
            x = -3,
            y = 0,
            z = -5,
        },
        
        {
            x = 3,
            y = 0,
            z = -5,
        },
        
        
        
        {
            x = 5,
            y = 0,
            z = -3,
        },
        
        {
            x = 5,
            y = 0,
            z = 3,
        },
        
        
        
        {
            x = -3,
            y = 0,
            z = 5,
        },
        
        {
            x = 3,
            y = 0,
            z = 5,
        },
        
        
        
        {
            x = -5,
            y = 0,
            z = -3,
        },
        
        {
            x = -5,
            y = 0,
            z = 3,
        },

        -- corners 2

        {
            x = -5,
            y = 0,
            z = -5,
        },
        
        {
            x = 5,
            y = 0,
            z = -5,
        },
        
        {
            x = 5,
            y = 0,
            z = 5,
        },
        
        {
            x = -5,
            y = 0,
            z = 5,
        },
    }

    local vector = { x=0, y=1, z=0 }

    self.vectorByDegree = {}

    self.vectorByDegree[0] = CreateQuaternion( vector, 0 )
    self.vectorByDegree[90] = CreateQuaternion( vector, 90 )
    self.vectorByDegree[180] = CreateQuaternion( vector, 180 )
    self.vectorByDegree[270] = CreateQuaternion( vector, 270 )

    self.randomOrientationArray = {
        self.vectorByDegree[0],
        self.vectorByDegree[90],
        self.vectorByDegree[180],
        self.vectorByDegree[270]
    }
end

function ghost_building_portal_construction:UpdateGhostEntities()

    self:ClearGhostEntities()

    self.selectedMode = self:CheckModeValueExists(self.selectedMode)

    if ( self.selectedMode == "none" ) then

        return
    end

    local wallBlueprintName = self.wallConfig[self.selectedMode]
    wallBlueprintName = self:GetMaxAvailableLevel(wallBlueprintName)

    local wallBlueprintNameGhost = wallBlueprintName .. "_ghost"

    if ( self.selectedMode == "wall_vine" ) then

        for newPosition in Iter(self.vineWallsPositions) do

            self:SpawnAndAttachGhostEntity(wallBlueprintNameGhost, newPosition)
        end
        
        return
    end

    local gateBlueprintName = self.gateConfig[self.selectedMode]
    gateBlueprintName = self:GetMaxAvailableLevel(gateBlueprintName)

    gateBlueprintNameGhost = gateBlueprintName .. "_ghost"

    for newPosition in Iter(self.gatePositions) do

        self:SpawnAndAttachGhostEntity(gateBlueprintNameGhost, newPosition)
    end




    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( wallBlueprintName ) )

    local connectTypeCorner = 4
    local connectTypeT = 8
    local connectTypeX = 16

    local blueprintNameCorner = self:GetBlueprintByConnectType( buildingDesc, connectTypeCorner )
    local blueprintNameT = self:GetBlueprintByConnectType( buildingDesc, connectTypeT )
    local blueprintNameX = self:GetBlueprintByConnectType( buildingDesc, connectTypeX )

    local blueprintNameCornerGhost = blueprintNameCorner .. "_ghost"
    local blueprintNameTGhost = blueprintNameT .. "_ghost"
    local blueprintNameXGhost = blueprintNameX .. "_ghost"

    for newPosition in Iter(self.wallPositions["_x_"]) do
        
        self:SpawnAndAttachGhostEntity(blueprintNameXGhost, newPosition)
    end

    for newPosition in Iter(self.wallPositions["_t_"]) do
        
        self:SpawnAndAttachGhostEntity(blueprintNameTGhost, newPosition)
    end
    
    for newPosition in Iter(self.wallPositions["corner"]) do
        
        self:SpawnAndAttachGhostEntity(blueprintNameCornerGhost, newPosition)
    end
end

function ghost_building_portal_construction:SpawnAndAttachGhostEntity(blueprintName, newPosition)
        
    local lineEnt = EntityService:SpawnAndAttachEntity( blueprintName, self.entity )
    
    self:RemoveUselessComponents(lineEnt)
    
    self:ChangeEntityMaterial( lineEnt, "hologram/blue" )
    EntityService:SetPosition( lineEnt, newPosition )
    
    if ( newPosition.degree ~= nil ) then

        EntityService:Rotate( lineEnt, 0, 1, 0, newPosition.degree )
    end
    
    Insert(self.linesEntities, lineEnt)
end

function ghost_building_portal_construction:BuildWalls(transform)

    self.selectedMode = self:CheckModeValueExists(self.selectedMode)

    if ( self.selectedMode == "none" ) then

        return
    end

    local wallBlueprintName = self.wallConfig[self.selectedMode]
    wallBlueprintName = self:GetMaxAvailableLevel(wallBlueprintName)

    local randomRotation = 0

    local database = EntityService:GetBlueprintDatabase( wallBlueprintName )
    if ( database and database:HasInt("random_rotation") ) then

        randomRotation = database:GetIntOrDefault( "random_rotation", 0 )
    end

    if ( self.selectedMode == "wall_vine" ) then

        for newPosition in Iter(self.vineWallsPositions) do

            self:BuildWallEntity(wallBlueprintName, transform, newPosition, false, randomRotation)
        end

        for newPosition in Iter(self.gatePositions) do

            self:TryBuildDesertFloor(transform, newPosition)
        end

        self:TryBuildFloorCorners(transform)
        
        return
    end


    local gateBlueprintName = self.gateConfig[self.selectedMode]
    gateBlueprintName = self:GetMaxAvailableLevel(gateBlueprintName)

    for newPosition in Iter(self.gatePositions) do

        self:BuildWallEntity(gateBlueprintName, transform, newPosition, true, randomRotation)
    end



    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( wallBlueprintName ) )

    local connectTypeCorner = 4
    local connectTypeT = 8
    local connectTypeX = 16

    local blueprintNameCorner = self:GetBlueprintByConnectType( buildingDesc, connectTypeCorner )
    local blueprintNameT = self:GetBlueprintByConnectType( buildingDesc, connectTypeT )
    local blueprintNameX = self:GetBlueprintByConnectType( buildingDesc, connectTypeX )

    for newPosition in Iter(self.wallPositions["_x_"]) do

        self:BuildWallEntity(blueprintNameX, transform, newPosition, false, randomRotation)
    end

    for newPosition in Iter(self.wallPositions["_t_"]) do

        self:BuildWallEntity(blueprintNameT, transform, newPosition, false, randomRotation)
    end

    for newPosition in Iter(self.wallPositions["corner"]) do

        self:BuildWallEntity(blueprintNameCorner, transform, newPosition, false, randomRotation)
    end

    self:TryBuildFloorCorners(transform)
end

function ghost_building_portal_construction:TryBuildFloorCorners(transform)

    local deltas = { -4, 4}

    for deltaX in Iter(deltas) do

        for deltaZ in Iter(deltas) do

            local buildTransform = {}

            buildTransform.position = {}
        
            buildTransform.position.x = transform.position.x + deltaX
            buildTransform.position.y = transform.position.y
            buildTransform.position.z = transform.position.z + deltaZ
        
            buildTransform.scale = { x=1,y=1,z=1 }
            buildTransform.orientation = self.vectorByDegree[0]

            self:BuildDesertFloor(buildTransform)
        end
    end
end

function ghost_building_portal_construction:BuildWallEntity(blueprintName, transform, newPosition, buildFloor, randomRotation)

    local buildTransform = {}

    buildTransform.position = {}
        
    buildTransform.position.x = newPosition.x + transform.position.x
    buildTransform.position.y = transform.position.y
    buildTransform.position.z = newPosition.z + transform.position.z
        
    buildTransform.scale = { x=1,y=1,z=1 }

    if ( randomRotation == 1 ) then

        buildTransform.orientation = self.randomOrientationArray[RandInt(1,4)]

    elseif ( newPosition.degree ~= nil ) then

        buildTransform.orientation = self.vectorByDegree[newPosition.degree]
    else
        buildTransform.orientation = self.vectorByDegree[0]
    end

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, buildTransform, false, {} )

    if ( buildFloor ) then

        buildTransform.orientation = self.vectorByDegree[0]

        self:BuildDesertFloor(buildTransform)
    end
end

function ghost_building_portal_construction:TryBuildDesertFloor(transform, newPosition)

    local buildTransform = {}

    buildTransform.position = {}
        
    buildTransform.position.x = newPosition.x + transform.position.x
    buildTransform.position.y = transform.position.y
    buildTransform.position.z = newPosition.z + transform.position.z
        
    buildTransform.scale = { x=1,y=1,z=1 }

    buildTransform.orientation = self.vectorByDegree[0]

    self:BuildDesertFloor(buildTransform)
end

function ghost_building_portal_construction:RemoveUselessComponents(entity)

    EntityService:RemoveComponent( entity, "LuaComponent" )

    if ( EntityService:HasComponent( entity, "DisplayRadiusComponent" ) ) then
        EntityService:RemoveComponent( entity, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( entity, "GhostLineCreatorComponent" ) ) then
        EntityService:RemoveComponent( entity, "GhostLineCreatorComponent" )
    end
end

function ghost_building_portal_construction:GetBlueprintByConnectType( buildingDesc, connectType )

    for i=1,buildingDesc.connect.count do

        local connectRecord = buildingDesc.connect[i]

        if ( connectRecord.key == connectType and connectRecord.value.count > 0 ) then

            local connectBlueprintName = connectRecord.value[1]

            local buildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( connectBlueprintName ) )

            return buildingDescRef.bp
        end
    end

    return buildingDesc.bp
end

function ghost_building_portal_construction:ClearGhostEntities()

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
end

function ghost_building_portal_construction:OnBuildingStartEvent( evt )

    local entity = evt:GetEntity()

    local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent")
    local owner = -1
    if (playerReferenceComponent) then
        local helper = reflection_helper(playerReferenceComponent)
        owner = helper.player_id
    end
    if ( owner ~= self.playerId ) then
        return
    end
    
    ShowBuildingDisplayRadiusAround( self.entity, self.blueprint )
    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( blueprintName == self.blueprint ) then

        local transform = EntityService:GetWorldTransform( entity )

        self:BuildDesertFloor(transform)

        self:BuildWalls(transform)
    end
end

function ghost_building_portal_construction:OnUpdate()
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity, transform, 1 )

    if ( self.activated and self.buildPosition ~= nil ) then
        local currentPosition = EntityService:GetWorldTransform( self.entity )
        local spots = BuildingService:FindSpotsByDistance( self.buildPosition, currentPosition, self.radius, self.blueprint)
        for spot in Iter( spots ) do

            LogService:Log("BuildBuildingRequest spot.position.x" .. tostring(spot.position.x) .. " spot.position.z" .. tostring(spot.position.z))

            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true, {} )
            self.buildPosition = spot
        end
    end

    for i=1,#self.linesEntities do

        local lineEnt = self.linesEntities[i]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, i+1, true, false )

        --if ( testBuildable ~= nil) then
        --    self:AddToEntitiesToSellList(testBuildable)
        --end
    end
end

function ghost_building_portal_construction:OnActivate()
    
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable =  self:GetBuildInfo(self.entity )

    self.buildPosition = transform

    if ( self.activated ) then
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true, {} )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true, {} )

        elseif( testBuildable.flag == CBF_REPAIR ) then
            QueueEvent("RepairBuildingByPlayerRequest", testBuildable.entity_to_repair, self.playerId, -1 )
        end
    end
    
end

function ghost_building_portal_construction:OnDeactivate()
    self.buildPosition = nil
end

function ghost_building_portal_construction:OnRelease()
    HideBuildingDisplayRadiusAround( self.entity, self.blueprint )
    HideBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )

    self:ClearGhostEntities()
end

function ghost_building_portal_construction:CreateModeValuesArray()

    local result = {}

    Insert( result, "none" )

    if ( IndexOf( result, self.selectedMode ) == nil ) then

        local wallBlueprintName = self.wallConfig[self.selectedMode]

        if ( ResourceManager:ResourceExists( "EntityBlueprint", wallBlueprintName ) and self:IsBlueprintAvailable( wallBlueprintName ) ) then

            Insert( result, self.selectedMode )
        end
    end

    for mode in Iter( self.modeValuesArray ) do
        
        if ( IndexOf( result, mode ) == nil ) then

            local wallBlueprintName = self.wallConfig[mode]

            if ( ResourceManager:ResourceExists( "EntityBlueprint", wallBlueprintName ) and self:IsBlueprintAvailable( wallBlueprintName ) ) then

                Insert( result, mode )
            end
        end
    end 

    return result
end

function ghost_building_portal_construction:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf( self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function ghost_building_portal_construction:OnRotateSelectorRequest(evt)

    --LogService:Log("OnRotateSelectorRequest ")

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local selectedMode = self:CheckModeValueExists(self.selectedMode)

    local index = IndexOf( self.currentModeValuesArray, selectedMode )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.currentModeValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.currentModeValuesArray[newIndex]

    if ( self.selectedMode == newValue ) then

        return
    end

    self.selectedMode = newValue

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString(self.configName, newValue)

    self:UpdateGhostEntities()
end

function ghost_building_portal_construction:GetMaxAvailableLevel( blueprintName )

    if ( blueprintName == "" or blueprintName == nil ) then
        return ""
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    if ( buildingDescRef.upgrade ~= nil and buildingDescRef.upgrade ~= "" ) then

        if ( self:IsBlueprintAvailable( buildingDescRef.upgrade ) ) then

            local list = BuildingService:GetBuildCosts( buildingDescRef.upgrade, self.playerId )

            local allResourcesUnlocked = true

            for resourceCost in Iter(list) do
                
                if ( not PlayerService:IsResourceUnlocked(resourceCost.first) ) then

                    allResourcesUnlocked = false

                    break
                end
            end

            if ( allResourcesUnlocked ) then

                return self:GetMaxAvailableLevel( buildingDescRef.upgrade )
            end
        end
    end

    return blueprintName
end

function ghost_building_portal_construction:IsBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self:GetResearchForUpgrade( blueprintName ) or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( PlayerService:GetLeadingPlayer(), researchName ) ) then
            return true
        end
    end

    return false
end

function ghost_building_portal_construction:GetResearchForUpgrade( blueprintName )

    self.cacheBlueprintsResearches = self.cacheBlueprintsResearches or {}

    if ( self.cacheBlueprintsResearches[blueprintName] == nil ) then

        self.cacheBlueprintsResearches[blueprintName] = self:CalculateResearchForUpgrade( blueprintName )
    end

    return self.cacheBlueprintsResearches[blueprintName]
end

function ghost_building_portal_construction:CalculateResearchForUpgrade( blueprintName )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function ghost_building_portal_construction:CheckEntityBuildable( entity, transform, id, checkActive, ignoreSelectorSettingCanBuild )
    checkActive = checkActive or ( checkActive == nil and true )
    ignoreSelectorSettingCanBuild = ignoreSelectorSettingCanBuild or false
    id = id or 1
    local test = nil

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, buildingComponent.bp, id )

    if ( test == nil ) then
        return
    end

    local testReflection = reflection_helper(test:ToTypeInstance(), test )

    --LogService:Log("Flag: " .. tostring(testReflection.flag ))
    --LogService:Log("Missing resources: " .. tostring(testReflection.missing_resources))
    --LogService:Log("Entity to repair: " .. tostring(testReflection.entity_to_repair )  )
    --LogService:Log("Entity to sell: " .. tostring(testReflection.entities_to_sell ))
    --LogService:Log("Free grids: " .. tostring(testReflection.free_grids ))


    local canBuildOverride = (testReflection.flag == CBF_OVERRIDES)
    local canBuild = (testReflection.flag == CBF_CAN_BUILD or testReflection.flag == CBF_ONE_GRID_FLOOR or testReflection.flag == CBF_OVERRIDES)

    if ( ignoreSelectorSettingCanBuild == false ) then
        local buildingSelectorComponent = reflection_helper( EntityService:GetComponent(self.selector, "BuildingSelectorComponent") )
        buildingSelectorComponent.can_build = canBuild
    end

    local materialToSet = "hologram/blue"

    if ( testReflection.flag == CBF_REPAIR  ) then
        if ( BuildingService:CanAffordRepair( testReflection.entity_to_repair, self.playerId, -1 )) then

            materialToSet = "hologram/pass"

        else

            materialToSet = "hologram/deny"
        end
    else
        if ( canBuildOverride and not floor ) then

            materialToSet = "hologram/active"

        elseif ( canBuild  ) then

            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end
    end

    self:ChangeEntityMaterial( entity, materialToSet )

    if ( self.activated and checkActive ) then
        if ( BuildingService:BlinkBuildingSelector(self.selector, entity ) ) then

            if ( testReflection.flag == CBF_TO_CLOSE ) then

                if ( self.toCloseAnnoucement ~= "" ) then
                    QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.toCloseAnnoucement, entity, false)
                end
            elseif( testReflection.flag == CBF_LIMITS ) then

                QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", entity, false )
            end

            local missingResources = testReflection.missing_resources
            if ( missingResources.count  > 0 ) then

                local soundAnnouncement = "voice_over/announcement/not_enough_resources"

                if ( missingResources.count  == 1 ) then

                    local singleMissingResource = missingResources[1]

                    if ( self.annoucements and self.annoucements[singleMissingResource] ~= nil and self.annoucements[singleMissingResource] ~= "" ) then

                        soundAnnouncement = self.annoucements[singleMissingResource]
                    end
                end

                QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, entity, false )
            end
        end
    end
    return testReflection
end

function ghost_building_portal_construction:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function ghost_building_portal_construction:BuildDesertFloor(spot)

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"
    local antiQuickSandFloor2 = "buildings/decorations/floor_desert_2x2"

    if ( BuildingService:IsBuildingAvailable( self.playerId, antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then

        local buildDesertFloor = self:ShouldBuildDesertFloor( spot.position )

        if ( buildDesertFloor ) then

            local transformFloor = {}
            transformFloor.position = spot.position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=2, y=1, z=2}

            local test = BuildingService:CheckGhostFloorStatus( self.playerId, self.entity, transformFloor, antiQuickSandFloor )

            if ( test ) then

                local testBuildable = reflection_helper(test:ToTypeInstance())

                self:BuildFloor( testBuildable, antiQuickSandFloor2 )
            end
        end
    end
end

function ghost_building_portal_construction:BuildFloor(testBuildable, antiQuickSandFloor2)
    local toRecreate ={}

    local removedCount =0
    local buildingToSellCount = testBuildable.entities_to_sell.count
    for i = 1,buildingToSellCount do
        local entityToSell = testBuildable.entities_to_sell[i]
        --LogService:Log("Test: " .. tostring(i) .. "/" .. tostring(testBuildable.entities_to_sell.count ) .. ":" ..tostring(entityToSell))
        if (entityToSell == nil  ) then 
            --LogService:Log("Entity to sell nil!  do not remove! " ..tostring(entityToSell)  )
            goto continue 
        end
        if (not EntityService:IsAlive( entityToSell) ) then 
            --LogService:Log("Entity to sell not alive!  do not remove! " )
            goto continue 
        end
        local buildingComponent = EntityService:GetComponent( entityToSell, "BuildingComponent" )
        
        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode >= BM_SELLING ) then 
            --    LogService:Log("Mode: " .. tostring( mode ) .. ", do not remove!" )
                goto continue
             end 
        end

        local gridCullerComponent = EntityService:GetComponent( entityToSell, "GridCullerComponent")
        local entityBlueprint = EntityService:GetBlueprintName( entityToSell )
        if( gridCullerComponent == nil or entityBlueprint == "" ) then 
           -- LogService:Log("No grid culler or entity blueprint! Do not remove!" )
            goto continue 
        end

        local gridCullerComponentHelper = reflection_helper(gridCullerComponent)
        local indexes = gridCullerComponentHelper.terrain_cell_entities
        local freeGrids = {}
        for i=indexes.count,1,-1 do 
            local add = true
            for j=1,testBuildable.free_grids.count do
                if ( testBuildable.free_grids[j] == indexes[i].id) then
                    add = false
                    break
                end
            end
            if (add ) then
                Insert(freeGrids, indexes[i].id )
            end
        end
        if ( #freeGrids > 0 ) then
            Insert(toRecreate, {["bp"]=entityBlueprint,["indexes"] = freeGrids })
        end

        removedCount = removedCount + 1
        QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        ::continue::
    end

    Assert(removedCount == testBuildable.entities_to_sell.count, "Error: not all floors selled: " .. tostring( removedCount ) .. "/" .. tostring(buildingToSellCount ) )

    self:FillWithFloors( antiQuickSandFloor2, testBuildable.free_grids )

    for recreateRequest in Iter( toRecreate ) do
        self:FillWithFloors( recreateRequest["bp"], recreateRequest["indexes"] )
    end 
end

function ghost_building_portal_construction:FillWithFloors( blueprint, indexes )
    local toReplace = 1
    if string.find( blueprint, "4" ) then
        toReplace = 4
    elseif string.find( blueprint, "3" ) then
        toReplace = 3
    elseif string.find( blueprint, "2" ) then
        toReplace = 2
    end

    local idxToPos = {}
    local storage = {}
    local indexesCount = #indexes
    if ( indexesCount == 0 ) then
        indexesCount = indexes.count
    end 
    for i = 1,indexesCount do
        local idx = indexes[i]
        
        local pos = FindService:GetCellOrigin(idx)
        
        idxToPos[idx] = pos
        storage[idx] = pos
    end

    local sorter = function(k1,k2) 
        local p1 = idxToPos[k1]
        local p2 = idxToPos[k2]
        if ( p1.z < p2.z ) then
            return true
        elseif( p1.z == p2.z and p1.x < p2.x) then
            return true
        end
        return false
    end

    table.sort( indexes, sorter )

    local right = {x=2,y=0,z=0}
    local down = {x=0,y=0,z=2}

    local toCreate = {{}}

    for s=toReplace,0,-1 do
        local i = 1 
        while i <= indexesCount do
            local idx = indexes[i]
            if (idxToPos[idx] == nil ) then i = i + 1 goto continue end

            toUse = {}

            local pos = idxToPos[ idx ];
            for x=0,s-1 do    
                local currentPos = VectorAdd( pos, VectorMulByNumber(right, x))
                for y=0,s-1 do

                    local checkPos =  VectorAdd( currentPos, VectorMulByNumber(down, y))
                    for testIdx,testPos in pairs(idxToPos) do
                        if ( testPos.x == checkPos.x and testPos.z == checkPos.z) then
                            Insert(toUse, testIdx)
                            break
                        end
                    end
                end
            end
            if ( #toUse == s * s ) then
                if( toCreate[s] == nil ) then toCreate[s] = {} end

                table.insert(toCreate[s], toUse)
                for idx in Iter(toUse) do
                    idxToPos[idx] = nil
                end
                i = 1
            else
                i = i + 1
            end
            ::continue::
        end
    end

    for replaced = 1,toReplace do
        local data = toCreate[replaced]
        if ( data == nil ) then goto continue2 end
        local currentBlueprint = string.gsub( blueprint, tostring(toReplace), tostring(replaced) )
        for vIdx = 1,#data do
            local v = data[vIdx]
            local transform = {}
            transform.orientation = {x=0,y=0,z=0,w=1}
            local infoPos = storage[v[1]]

            if ( replaced == 1 ) then
                transform.position = infoPos
            elseif( replaced == 2 ) then
                local position = infoPos
                position = VectorAdd(position, {x=1,y=0,z=1})
                transform.position = position                
            elseif ( replaced == 3 ) then
                transform.position = storage[v[5]]
            else
                local position = infoPos
                position = VectorAdd(position, {x=3,y=0,z=3})
                transform.position = position           
            end
            transform.scale = {x=replaced,y=1,z=replaced}
            QueueEvent("BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function ghost_building_portal_construction:ShouldBuildDesertFloor( position )

    local arrayDelta = { -1, 1 }

    for deltaX in Iter(arrayDelta) do

        for deltaZ in Iter(arrayDelta) do

            local newPosition = {}
            newPosition.x = position.x + deltaX
            newPosition.y = position.y
            newPosition.z = position.z + deltaZ

            if ( self:ShouldBuildDesertFloorOnCell( newPosition ) ) then
                
                return true
            end
        end
    end

    return false
end

function ghost_building_portal_construction:ShouldBuildDesertFloorOnCell( position )

    local terrainType = ""

    local overrideTerrains = {}

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(position)

    if ( terrainCellEntityId ~= nil and terrainCellEntityId ~= INVALID_ID ) then

        local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

        if ( terrainTypeLayerComponent ~= nil ) then

            local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

            if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

                terrainType = terrainTypeLayerComponentRef.terrain_type.resource.name
            end
        end

        local overrideTerrainComponent = EntityService:GetComponent( terrainCellEntityId, "OverrideTerrainComponent" )

        if ( overrideTerrainComponent ~= nil ) then

            local overrideTerrainComponentRef = reflection_helper(overrideTerrainComponent)

            if ( overrideTerrainComponentRef.terrain_overrides ) then

                for i=1,overrideTerrainComponentRef.terrain_overrides.count do

                    local terrainTypeHolder = overrideTerrainComponentRef.terrain_overrides[i]

                    if ( terrainTypeHolder and terrainTypeHolder.resource and terrainTypeHolder.resource.name ) then

                        if ( IndexOf( overrideTerrains, terrainTypeHolder.resource.name ) == nil ) then
                            Insert( overrideTerrains, terrainTypeHolder.resource.name )
                        end
                    end
                end
            end
        end
    end

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        return true
    end

    return false
end

return ghost_building_portal_construction
