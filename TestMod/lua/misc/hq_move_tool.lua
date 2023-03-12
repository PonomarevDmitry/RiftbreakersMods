require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'hq_move_tool' ( LuaEntityObject )

function hq_move_tool:__init()
    LuaEntityObject.__init(self,self)
end

function hq_move_tool:init()
    
    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function hq_move_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper( EntityService:GetComponent( self.entity, "BuildingComponent") )
    self.blueprint = buildingComponent.bp 

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue")
    EntityService:SetVisible( self.entity , false )
    
    local markerBlueprint = "misc/marker_selector_buildings_builder_tool_01"
    self.markerEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
    
    self.hq = nil

    self:SpawnBuildinsTemplates()
end

function hq_move_tool:SpawnBuildinsTemplates()

    local markerDB = EntityService:GetDatabase( self.markerEntity )
    
    local findResult = FindService:FindEntityByName( "headquarters" )

    if ( findResult == nil or findResult == INVALID_ID ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/building_impossible")
        markerDB:SetInt("message_visible", 1)
        return
    end

    self.hq = findResult

    local skinned = EntityService:IsSkinned( self.hq )
    if ( skinned ) then
        EntityService:SetMaterial( self.hq, "selector/hologram_active_skinned", "selected")
    else
        EntityService:SetMaterial( self.hq, "selector/hologram_active", "selected")
    end

    local hqBlueprint = EntityService:GetBlueprintName( self.hq )

    local transform = EntityService:GetWorldTransform( self.hq )

    local position = transform.position
    local orientation = transform.orientation

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( hqBlueprint )
    local buildingDesc = reflection_helper( blueprintBuildingDesc )


    local team = EntityService:GetTeam( self.entity )

    local newPosition = EntityService:GetWorldTransform( self.entity ).position

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnEntity( buildingDesc.ghost_bp, newPosition, team )
    else
        buildingEntity = EntityService:SpawnEntity( buildingDesc.bp, newPosition, team )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )
    
    self.buildingDesc = buildingDesc
    self.ghostHQ = buildingEntity
    self.hqBlueprint = hqBlueprint


    local gridSize = BuildingService:GetBuildingGridSize( self.hq )

    EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z)

    markerDB:SetString("message_text", "")
    markerDB:SetInt("message_visible", 0)
end

function hq_move_tool:OnWorkExecute()

    local currentTransform = EntityService:GetWorldTransform( self.entity )

    self:CheckEntityBuildable( self.entity, currentTransform, self.blueprint )

    if ( self.ghostHQ ~= nil ) then

        EntityService:SetPosition( self.ghostHQ, currentTransform.position )

        local currentTransform = EntityService:GetWorldTransform( self.ghostHQ )

        currentTransform.position = currentTransform.position

        local testBuildable = self:CheckEntityBuildable( self.ghostHQ, currentTransform, self.hqBlueprint )
    end
end

function hq_move_tool:CheckEntityBuildable( entity, transform, blueprint, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprint, id)

    if ( checkStatus == nil ) then
        return nil
    end

    local testBuildable = reflection_helper(checkStatus:ToTypeInstance(), checkStatus )

    
    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_OVERRIDES or testBuildable.flag == CBF_REPAIR)
    
    local skinned = EntityService:IsSkinned(entity)

    if ( testBuildable.flag == CBF_REPAIR  ) then

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
        elseif ( canBuild  ) then
            EntityService:ChangeMaterial( entity, "selector/hologram_blue")
        else
            EntityService:ChangeMaterial( entity, "selector/hologram_red")
        end
    end

    return testBuildable
end

function hq_move_tool:OnActivateSelectorRequest()

    if ( self.ghostHQ == nil or self.hq == nil ) then
        return
    end

    local currentTransform = EntityService:GetWorldTransform( self.ghostHQ )

    local testBuildable = self:CheckEntityBuildable( self.ghostHQ, currentTransform, self.hqBlueprint )

    --EntityService:SetPosition( self.hq, currentTransform.position )
    --EntityService:SetOrientation( self.hq, currentTransform.orientation )
    --BuildingService:CheckAndFixBuildingConnection( self.hq )
    
    local component = EntityService:GetComponent( self.hq, "BuildingComponent" )
    if ( component ~= nil ) then
        component:GetField("m_isSellable"):SetValue("true")
        local componentRef = reflection_helper( component )

        LogService:Log(tostring(componentRef))
    
        if ( componentRef.build_costs ~= nil and componentRef.build_costs.resource ~= nil ) then

            local container = rawget( componentRef.build_costs.resource, "__ptr" );

            if ( container ~= nil ) then
                for i=container:GetItemCount(),-1,0 do
                    container:EraseItem(i)
                end
            end
        end
    end

    EntityService:RemoveMaterial( self.hq, "selected" )

    --QueueEvent("SellBuildingRequest", self.hq, self.playerId, false )
    EntityService:DissolveEntity(self.hq, 0.5)
    --EntityService:RemoveEntity( self.hq )

    self.hq = nil

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.buildingDesc.bp, currentTransform, true )

    EntityService:RemoveEntity(self.ghostHQ)
    self.ghostHQ = nil
end

function hq_move_tool:OnDeactivateSelectorRequest()
end

function hq_move_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    degree = -degree

    EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, degree )

    if ( self.ghostHQ ~= nil ) then
        EntityService:Rotate( self.ghostHQ, 0.0, 1.0, 0.0, degree )
    end

    self:OnWorkExecute()
end

function hq_move_tool:OnRelease()

    if ( self.ghostHQ ~= nil ) then
        EntityService:RemoveEntity(self.ghostHQ)
        self.ghostHQ = nil
    end

    if ( self.hq ~= nil ) then
        EntityService:RemoveMaterial( self.hq, "selected" )
    end

    if ( self.markerEntity ~= nil) then
        EntityService:RemoveEntity(self.markerEntity)
    end
end

return hq_move_tool