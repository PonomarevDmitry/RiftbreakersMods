require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/database_utils.lua")

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
    
    self.annoucements = { 
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",
        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",
        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium" 
    }

    self:SpawnBuildinsTemplates()

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
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

    self.buildCost = {}

    if ( self.ghostHQ ~= nil ) then

        EntityService:SetPosition( self.ghostHQ, currentTransform.position )

        local currentTransform = EntityService:GetWorldTransform( self.ghostHQ )

        currentTransform.position = currentTransform.position

        local testBuildable = self:CheckEntityBuildable( self.ghostHQ, currentTransform, self.hqBlueprint )

        BuildingService:CheckAndFixBuildingConnection( self.ghostHQ )

        local list = BuildingService:GetBuildCosts( self.buildingDesc.bp, self.playerId )

        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + resourceCost.second
        end
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

function hq_move_tool:CheckEntityBuildable( entity, transform, blueprint, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprint, id)

    if ( checkStatus == nil ) then
        return nil
    end

    local testBuildable = reflection_helper(checkStatus:ToTypeInstance(), checkStatus )
    
    if ( testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_LIMITS  ) then
        EntityService:ChangeMaterial( entity, "selector/hologram_blue")
    else
        EntityService:ChangeMaterial( entity, "selector/hologram_red")
    end

    return testBuildable
end

function hq_move_tool:OnActivateSelectorRequest()

    if ( self.ghostHQ == nil or self.hq == nil ) then
        return
    end
    
    LogService:Log("CBF_CAN_BUILD " .. tostring(CBF_CAN_BUILD))
    LogService:Log("CBF_OVERRIDES " .. tostring(CBF_OVERRIDES))
    LogService:Log("CBF_REPAIR " .. tostring(CBF_REPAIR))

    LogService:Log("CBF_TO_CLOSE " .. tostring(CBF_TO_CLOSE))
    LogService:Log("CBF_LIMITS " .. tostring(CBF_LIMITS))
    
    

    local transformToNewHQ = EntityService:GetWorldTransform( self.ghostHQ )

    local testBuildable = self:CheckEntityBuildable( self.ghostHQ, transformToNewHQ, self.hqBlueprint )

    LogService:Log(tostring(testBuildable))

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        LogService:Log("CBF_TO_CLOSE " .. tostring(CBF_TO_CLOSE))
            
        LogService:Log("self.buildingDesc.min_radius_effect " .. tostring(self.buildingDesc.min_radius_effect))

        if ( self.buildingDesc.min_radius_effect ~= "" ) then
            LogService:Log("CBF_TO_CLOSE " .. tostring(CBF_TO_CLOSE))
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.buildingDesc.min_radius_effect, self.ghostHQ, false)
        else
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/portal_too_close", self.ghostHQ, false)
        end

        return
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        if ( missingResources.count  > 1 ) then

            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/not_enough_resources", self.ghostHQ, false )

        elseif ( self.annoucements[missingResources[1]] ~= nil and self.annoucements[missingResources[1]] ~= "" ) then

            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.annoucements[missingResources[1]], self.ghostHQ, false )
        end

        return
    end

    local gridCullerComponent = EntityService:GetComponent( self.ghostHQ, "GridCullerComponent")
    if( gridCullerComponent ~= nil ) then

        local gridCullerComponentRef = reflection_helper( gridCullerComponent )
        LogService:Log("gridCullerComponent " .. tostring(gridCullerComponentRef))
    end

    if ( testBuildable.free_grids.count  ~= 56 ) then
        return
    end

    local listCosts = BuildingService:GetBuildCosts( self.buildingDesc.bp, self.playerId )

    for resourceCost in Iter( listCosts ) do

        LogService:Log("PlayerService AddResourceAmount " .. tostring(resourceCost.first) .. " amount " .. tostring(-resourceCost.second) )

        PlayerService:AddResourceAmount( resourceCost.first, -resourceCost.second )
    end

    --unsigned int SpawnEntity(EntityService&,custom [class Exor::Math::Vector3<float>] const&)
    --unsigned int SpawnEntity(EntityService&,unsigned int)
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,unsigned int,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [struct Exor::TeamId])
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,unsigned int,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&)
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,unsigned int,custom [struct Exor::TeamId])
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,unsigned int,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&)
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&)
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [float],custom [float],custom [float],custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&)
    --unsigned int SpawnEntity(EntityService&,custom [class Exor::UtfString<char,class Exor::utf_traits<char>,class Exor::StlAllocatorProxy<char> >] const&,custom [class Exor::Math::Vector3<float>] const&,custom [struct Exor::TeamId])

    local builder = EntityService:SpawnEntity( "buildings/tools/hq_move_tool/builder", transformToNewHQ.position, EntityService:GetTeam(self.entity) )

    EntityService:SetOrientation( builder, transformToNewHQ.orientation )
    
    local database = EntityService:GetDatabase( builder )
    
    database:SetInt("playerId", self.playerId )
    
    database:SetInt("hq", self.hq )
    database:SetInt("ghostHQ", self.ghostHQ )
    
    database:SetString("hq_blueprint", self.buildingDesc.bp )
    
    database:SetFloat("position.x", transformToNewHQ.position.x )
    database:SetFloat("position.y", transformToNewHQ.position.y )
    database:SetFloat("position.z", transformToNewHQ.position.z )
    
    database:SetFloat("orientation.x", transformToNewHQ.orientation.x )
    database:SetFloat("orientation.y", transformToNewHQ.orientation.y )
    database:SetFloat("orientation.z", transformToNewHQ.orientation.z )
    database:SetFloat("orientation.w", transformToNewHQ.orientation.w )
    
    DatabaseFullLog( database )
    
    self.ghostHQ = nil
    
    EntityService:RemoveMaterial( self.hq, "selected" )
    self.hq = nil

    EntityService:RemoveEntity( self.entity )
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

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

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