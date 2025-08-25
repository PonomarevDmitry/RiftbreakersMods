require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_trapsconstruction' ( LuaEntityObject )

function ghost_building_trapsconstruction:__init()
    LuaEntityObject.__init(self,self)
end

function ghost_building_trapsconstruction:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", {enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function ghost_building_trapsconstruction:InitializeValues()
    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent"))
    self.blueprintName = buildingComponent.bp

    self.desc = reflection_helper(BuildingService:GetBuildingDesc( self.blueprintName ))

    self.name = self.desc.name
    self.ghostBlueprintName = self.desc.ghost_bp

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )

    local transform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity, transform )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    self.gridSize = BuildingService:GetBuildingGridSize(self.entity)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )

    self.configNameCellGaps = "$trapsconstruction_cell_count"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.cellGapsCount = selectorDB:GetIntOrDefault(self.configNameCellGaps, 0)
    self.cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

    self.markerGapsConfig = -1
    self.currentMarkerGaps = nil
end

function  ghost_building_trapsconstruction:CheckEntityBuildable( entity, transform, id )
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

function ghost_building_trapsconstruction:OnWorkEnter()
end

function ghost_building_trapsconstruction:OnWorkExit()
end

function ghost_building_trapsconstruction:OnWorkExecute()
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function ghost_building_trapsconstruction:OnUpdate()

    -- Wall layers config
    local cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

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

        local entityOrientation = self.buildStartPosition.orientation

        EntityService:SetOrientation( self.entity, entityOrientation )

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
                transform.position = newPosition

                transform.orientation = entityOrientation

                local lineEnt = gridEntitiesZ[zNumber]
                EntityService:SetPosition( lineEnt, newPosition )
                EntityService:SetOrientation( lineEnt, transform.orientation )

                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, idCheckBuildable )

                idCheckBuildable = idCheckBuildable + 1

                if ( testBuildable ~= nil) then
                    self:AddToEntitiesToSellList(testBuildable)
                end
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

function ghost_building_trapsconstruction:CreateNewEntity(newPosition, orientation, team)

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

function ghost_building_trapsconstruction:FindPositionsToBuildLine(buildStartPosition, buildEndPosition, cellGapsCount)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local deltaX = (self.gridSize.x + cellGapsCount) * 2 * xSign
    local deltaZ = (self.gridSize.z + cellGapsCount) * 2 * zSign

    local smallDeltaX = (self.gridSize.x * xSign) / 2
    local smallDeltaZ = (self.gridSize.z * zSign) / 2

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

function ghost_building_trapsconstruction:GetXZSigns(positionStart, positionEnd)

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

function ghost_building_trapsconstruction:AddToEntitiesToSellList(testBuildable)

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

function ghost_building_trapsconstruction:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function ghost_building_trapsconstruction:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function ghost_building_trapsconstruction:OnActivateSelectorRequest()

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

function ghost_building_trapsconstruction:OnDeactivateSelectorRequest()

    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function ghost_building_trapsconstruction:OnRotateSelectorRequest(evt)

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
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = scaleWallGaps[newIndex]

    self.cellGapsCount = newValue

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:OnUpdate()
end

function ghost_building_trapsconstruction:FinishLineBuild()

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( self.nowBuildingLine ~= true ) then

        return
    end

    local allEntities = self:GetAllEntities()

    local count = #allEntities

    if ( count > 0 ) then

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

        local database = EntityService:GetOrCreateDatabase( builder )

        database:SetInt( "playerId", self.playerId )

        database:SetString( "entities_list", entitiesListString )
    end

    EntityService:SetVisible( self.entity , true )

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false
end

function ghost_building_trapsconstruction:GetAllEntities()

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

function ghost_building_trapsconstruction:RemoveMaterialFromOldBuildingsToSell()

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

function ghost_building_trapsconstruction:CheckConfigExists( cellGapsCount )

    local scaleWallGaps = self:GetGapsConfigArray()

    cellGapsCount = cellGapsCount or scaleWallGaps[1]

    local index = IndexOf(scaleWallGaps, cellGapsCount )

    if ( index == nil ) then

        return scaleWallGaps[1]
    end

    return cellGapsCount
end

function ghost_building_trapsconstruction:GetGapsConfigArray()

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

function ghost_building_trapsconstruction:OnRelease()

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

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end
end

return ghost_building_trapsconstruction