require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'portal_base_tool' ( LuaEntityObject )

function portal_base_tool:__init()
    LuaEntityObject.__init(self,self)
end

function portal_base_tool:init()

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

function portal_base_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity , false )

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    self.portalBlueprintName = "buildings/defense/portal"

    self:FillPortalBuildingDesc( self.portalBlueprintName )

    self:FindMinDistance()
end

function portal_base_tool:FindMinDistance()

    self.radius = BuildingService:FindEnergyRadius( self.portalBlueprintName )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max( bounds.x, bounds.z ) / 2.0
    end
end

function portal_base_tool:FillPortalBuildingDesc(portalBlueprintName)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( portalBlueprintName ) )

    self.ghostBlueprintName = buildingDesc.ghost_bp
    self.buildingDesc = buildingDesc
end

function portal_base_tool:SpawnGhostPortalEntity(position, orientation)

    local buildingEntity = EntityService:SpawnAndAttachEntity( self.ghostBlueprintName, self.selector )

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )

    EntityService:SetPosition( buildingEntity, position )
    EntityService:SetOrientation( buildingEntity, orientation )
    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    return buildingEntity
end

function portal_base_tool:OnWorkExecute()

    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function portal_base_tool:CheckEntityBuildable( entity, transform, id )

    id = id or 1
    local test = nil

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, buildingComponent.bp, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper(test:ToTypeInstance(), test )

    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

    local skinned = EntityService:IsSkinned(entity)

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_pass")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_pass")
            end
        else
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_deny")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_deny")
            end
        end
    else
        if ( canBuildOverride ) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_active_skinned")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_active")
            end
        elseif ( canBuild ) then
            EntityService:ChangeMaterial( entity, "selector/hologram_blue")
        else
            EntityService:ChangeMaterial( entity, "selector/hologram_red")
        end
    end

    return testBuildable
end

function portal_base_tool:BuildEntity(entity, transform, createCube)

    createCube = createCube or false

    local testBuildable = self:CheckEntityBuildable( entity, transform )

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

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

    elseif( testBuildable.flag == CBF_OVERRIDES ) then

        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function portal_base_tool:OnActivateSelectorRequest()
end

function portal_base_tool:OnDeactivateSelectorRequest()
end

function portal_base_tool:BuildDesertFloor(spot)

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

function portal_base_tool:BuildFloor(testBuildable, antiQuickSandFloor2)
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

function portal_base_tool:FillWithFloors( blueprint, indexes )
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
            transform.scale = {x=1,y=1,z=1}
            QueueEvent("BuildFloorRequest", self.entity, self.playerId, currentBlueprint, transform )
        end
        ::continue2::
    end
end

function portal_base_tool:ShouldBuildDesertFloor( position )

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

function portal_base_tool:ShouldBuildDesertFloorOnCell( position )

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

return portal_base_tool