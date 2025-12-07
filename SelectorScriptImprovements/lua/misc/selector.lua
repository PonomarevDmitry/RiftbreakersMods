class 'selector' ( LuaEntityObject )
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/building_utils.lua")

local SM_BUILD   = 1
local SM_SELECT  = 2
local SM_INVALID = 3
local BUILD_MODE_ACTION_MAPPER_NAME = BuildingService:GetBuildModeActionMapperName()


function selector:__init()
    LuaEntityObject.__init(self,self)
end

function selector:init()
    self:RegisterHandler( self.entity, "ChangeSelectorRequest",				"OnChangeSelectorRequest" )
    self:RegisterHandler( self.entity, "ChangeSelectorModeRequest",			"OnChangeSelectorModeRequest" )
    self:RegisterHandler( self.entity, "ActivateSelectorRequest",			"OnActivateSelectorRequest" )
    self:RegisterHandler( self.entity, "DeactivateSelectorRequest",			"OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.entity, "LeaveBuildModeRequest",				"OnLeaveBuildModeRequest" )
    self:RegisterHandler( self.entity, "RotateSelectorRequest",				"OnRotateSelectorRequest" )
    self:RegisterHandler( INVALID_ID, "ActivateEntityRequest",				"OnActivateEntityRequest" )
    self:RegisterHandler( INVALID_ID, "DeactivateEntityRequest",			"OnDeactivateEntityRequest" )

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "invalid", { enter="OnInvalidEnter", exit="OnInvalidExit"} )
    self.stateMachine:AddState( "select", {enter="OnSelectEnter", execute="OnSelectInProgress", exit="OnSelectExit" } )
    self.stateMachine:AddState( "build", {enter="OnBuildEnter", execute="OnBuildInProgress", exit="OnBuildExit"} )

    self:InitializeValues()
end

function selector:InitializeValues()
    self.mode = SM_INVALID
    self.selector = INVALID_ID
    self.cameraCuller = INVALID_ID
    self.actionTooltipEnt = INVALID_ID
    self.blueprint = ""
    self.ghostBlueprint = ""
    self.selectedEntities = {}
    self.activatedEntities = {}
    self.baseBlueprint = "misc/marker_selector"
    self.cornerBlueprint = "misc/marker_selector_corner"
    self.cameraCullerBlueprint = "misc/selector_camera_culler"
    self.boundsSize = {x=0,y=0,z=0}
    self.transform = EntityService:GetWorldTransform( self.entity )
    self.selectorPosition = nil
    self.category = ""
    self.type = ""
    self.activated = false
    self.resizeScale = {}
    self.rotations = {}

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.entity, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.stateMachine:ChangeState("invalid")
end

function selector:RemoveCurrentSelector()
    if ( EntityService:IsAlive( self.selector ) ) then
        EntityService:RemoveEntity( self.selector )
        self.selector = INVALID_ID
        local buildingSelectorComponent = reflection_helper(EntityService:GetComponent(self.entity, "BuildingSelectorComponent"))
        buildingSelectorComponent.blueprint_entity = self.selector
    end
end

function selector:OnChangeSelectorRequest( evt )
    if ( self.blueprint == evt:GetBlueprint()) then
        return
    end

    self.blueprint = evt:GetBlueprint()
    self.ghostBlueprint = evt:GetGhostBlueprint()
    if ( self.mode == SM_BUILD ) then
        self:ChangeBlueprint(self.blueprint, self.ghostBlueprint)
    end
end

function selector:RemoveScaleInfo()
    if ( self.showScaleInfo ~= nil ) then
        EntityService:RemoveEntity( self.showScaleInfo )
        self.showScaleInfo = nil
    end
end

function selector:OnInvalidEnter()
    self:DeselectAllEntities()
    self:DeactivateAllEntities()

    QueueEvent("RemoveEntityToTraceRequest", self.selector )
    QueueEvent("EnterFighterModeEvent", PlayerService:GetPlayerControlledEnt( self.playerId ) , self.playerId )
    self:RemoveCurrentSelector()
    PlayerService:OperateActionMapper( self.entity, BUILD_MODE_ACTION_MAPPER_NAME, false )
    self:RemoveScaleInfo()

    if EntityService:IsAlive( self.cameraCuller ) then
        EntityService:RemoveEntity( self.cameraCuller )
        self.cameraCuller = INVALID_ID
    end
end

function selector:OnInvalidExit()
    QueueEvent("EnterBuildModeEvent",  PlayerService:GetPlayerControlledEnt(self.playerId ) , self.playerId, self.entity, self.blueprint )
    QueueEvent("EnterBuildMenuEvent", self.selector )
    PlayerService:OperateActionMapper(  self.entity, BUILD_MODE_ACTION_MAPPER_NAME, true )

    if not EntityService:IsAlive( self.cameraCuller ) then
        self.cameraCuller = EntityService:SpawnAndAttachEntity( self.cameraCullerBlueprint, self.entity )
    end
end

function selector:ChangeBlueprint( blueprintName, ghostBlueprint )
    self:RemoveCurrentSelector()
    self.blueprint = blueprintName
    self.ghostBlueprint = ghostBlueprint

    if ( self.ghostBlueprint ~= "" ) then
        self.selector = EntityService:SpawnAndAttachEntity(self.ghostBlueprint, self.entity )
    else
        self.selector = EntityService:SpawnAndAttachEntity(self.blueprint, self.entity )
    end

    local boundsSize = EntityService:GetBoundsSize( self.selector)
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self.boundsSize.x = math.max( self.boundsSize.x, 1.0)
    self.boundsSize.y = 1
    self.boundsSize.z = math.max( self.boundsSize.z, 1.0)

    local buildingSelectorComponent = reflection_helper(EntityService:GetComponent(self.entity, "BuildingSelectorComponent"))
    buildingSelectorComponent.blueprint_entity = self.selector

    local database = EntityService:GetOrCreateDatabase( self.selector )

    database:SetInt("activated", self.activated and 1 or 0 )
    database:SetFloat("position_x", self.transform.position.x)
    database:SetFloat("position_y", self.transform.position.y)
    database:SetFloat("position_z", self.transform.position.z)

    if ( self.activationTransform ) then
        database:SetFloat("activation_position_x", self.activationTransform.position.x)
        database:SetFloat("activation_position_y", self.activationTransform.position.y)
        database:SetFloat("activation_position_z", self.activationTransform.position.z)
    end

    database:SetFloat("scale_x", math.floor( self.transform.scale.x + 0.5 ))
    database:SetFloat("scale_y", math.floor( self.transform.scale.y + 0.5 ))
    database:SetFloat("scale_z", math.floor( self.transform.scale.z + 0.5 ))

    if ( self.resizeScale[self.blueprint] ~= nil ) then
        local resizeScale = self.resizeScale[self.blueprint]
        database:SetFloat("resize_scale_x", math.floor( resizeScale.x + 0.5 ))
        database:SetFloat("resize_scale_y", math.floor( resizeScale.y + 0.5 ))
        database:SetFloat("resize_scale_z", math.floor( resizeScale.z + 0.5 ))
    end

    local lowBlueprint = BuildingService:FindLowUpgrade( self.blueprint )
    if (self.rotations ~= nil and self.rotations[lowBlueprint] ~= nil ) then
        local rotation = self.rotations[lowBlueprint];
        EntityService:SetOrientation( self.selector, rotation)
    end


    self.category = BuildingService:GetBuildingCategory( self.blueprint )
    self.type = BuildingService:GetBuildingType( self.selector )

    if ( self.type == nil or self.type == "" ) then

        local buildingDesc = BuildingService:GetBuildingDesc( self.blueprint )
        if( buildingDesc ~= nil ) then
            self.type = reflection_helper(buildingDesc).type
        end
    end

    -- Loading one common size for all floors
    if ( self.type == "floor" and (self.category == "decorations" or self.category == "tools") ) then

        if ( self.resizeScale ~= nil and self.resizeScale["Floors"] ~= nil ) then

            local resizeScale = self.resizeScale["Floors"]

            database:SetFloat("resize_scale_x", math.floor( resizeScale.x + 0.5 ))
            database:SetFloat("resize_scale_y", math.floor( resizeScale.y + 0.5 ))
            database:SetFloat("resize_scale_z", math.floor( resizeScale.z + 0.5 ))
        end
    end

    -- Loading one common size for all Tools
    if ( self.category == "tools" and self.type ~= "picker" and self.type ~= "sell" and self.type ~= "floor" ) then

        if ( self.resizeScale ~= nil and self.resizeScale["Tools"] ~= nil ) then

            local resizeScale = self.resizeScale["Tools"]

            database:SetFloat("resize_scale_x", math.floor( resizeScale.x + 0.5 ))
            database:SetFloat("resize_scale_y", math.floor( resizeScale.y + 0.5 ))
            database:SetFloat("resize_scale_z", math.floor( resizeScale.z + 0.5 ))
        end
    end

    QueueEvent("AddEntityToTraceRequest", self.selector, self.blueprint )

    if ( (self.type == "floor" or self.category == "tools") and ConsoleService:GetConfig( "showed_change_info" ) == "0" )then
        if ( self.showScaleInfo == nil ) then
            self.showScaleInfo = EntityService:SpawnAndAttachEntity("misc/scale_info", self.entity )
        end
    elseif ( self.showScaleInfo ~= nil ) then
        EntityService:RemoveEntity( self.showScaleInfo )
        self.showScaleInfo = nil
    end
end

function selector:OnSelectEnter()
    self:ChangeBlueprint(self.baseBlueprint, "")
    self.selectedEntities = {}
    self.activatedEntities = {}
    self.maxSelectedEntities = 1
    self.selectorPosition = nil
    self:RemoveScaleInfo()
end

function  selector:OnSelectExit()
    self:DeactivateAllEntities()
    self:DeselectAllEntities()
end

function selector:FindEntitiesToSelect( selectorComponent)
    self.position = selectorComponent.position

    local min = VectorSub(self.position, self.boundsSize )
    local max = VectorAdd(self.position, self.boundsSize )
    local possibleSelectedEnts = FindService:FindGridOwnersByBox( min, max )

    local scaleSelector = 0
    local stepScaleSelector = 0.5
    local maxScaleSelector = 2

    while (#possibleSelectedEnts == 0 and scaleSelector < maxScaleSelector) do

        local predicate = {
            signature="SelectableComponent",
            filter = function(entity)
                local pos = EntityService:GetPosition(entity )
                local distance = Distance( self.position, pos )

                local bounds = EntityService:GetBoundsSize( entity )

                if ( EntityService:GetGroup(entity ) == "##ruins##" ) then
                    local size = Length(bounds)
                    return distance <= size
                end

                if( EntityService:HasComponent( entity, "BuildingComponent" ) == true ) then
                    return false
                end

                local maxSize = math.max(bounds.x, bounds.z)

                return distance <= maxSize
            end
        };

        scaleSelector = scaleSelector + stepScaleSelector

        min = VectorSub(self.position, VectorMulByNumber( self.boundsSize, scaleSelector) )
        max = VectorAdd(self.position, VectorMulByNumber( self.boundsSize, scaleSelector) )

        possibleSelectedEnts = FindService:FindEntitiesByPredicateInBox( min, max, predicate );
    end

    if ( #possibleSelectedEnts == 0 ) then
        local cellEntity = EnvironmentService:GetTerrainCell( self.position )
        if ( EntityService:HasComponent( cellEntity, "GameplayResourceLayerComponent")) then
            local resourceLayerComponent = reflection_helper(EntityService:GetComponent(cellEntity, "GameplayResourceLayerComponent"))
            Insert(possibleSelectedEnts, resourceLayerComponent.ent.id )
        end
    end

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition(lhs )
        local p2 = EntityService:GetPosition(rhs )
        local d1 = Distance( self.position, p1 )
        local d2 = Distance( self.position, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b) return sorter(possibleSelectedEnts, a, b) end)

    local selectedEntities = {}
    for testEntity in Iter(possibleSelectedEnts ) do
        local entity = EntityService:GetAncestorWithSignature( testEntity, "SelectableComponent" )
        if ( entity == INVALID_ID ) then goto continue end

        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= 2 ) then goto continue end
        end

        Insert(selectedEntities, entity )
        ::continue::
    end

    return selectedEntities
end

function selector:DeselectEntity( entity )
    QueueEvent("DeselectEntityRequest", entity )

    HideBuildingDisplayRadiusAround( self.entity, entity )
end

function selector:DeselectAllEntities()
    for entity in Iter ( self.selectedEntities ) do
        self:DeselectEntity( entity )
    end
    Clear( self.selectedEntities )
    self:HideActionHint()
end

function selector:DeactivateEntity( entity )
    QueueEvent("DeactivateEntityRequest", entity, self.playerId  )
    self:HideActionHint()
end

function selector:DeactivateAllEntities()
    for entity in Iter ( self.activatedEntities ) do
        self:DeactivateEntity( entity )
    end
    Clear( self.activatedEntities )
end

function selector:SelectEntity( entity )
    QueueEvent("SelectEntityRequest", entity )

    self:ShowActionHint( entity )

    ShowBuildingDisplayRadiusAround( self.entity, entity )
end


function selector:ShowActionHint( entity )
    if ( entity ~= self.actionTooltipEnt ) then
        self:HideActionHint()
        self.actionTooltipEnt = EntityService:SpawnAndAttachEntity( "misc/interact_hint", entity )
    end
end

function selector:HideActionHint()
    if ( self.actionTooltipEnt ~= nil and self.actionTooltipEnt ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.actionTooltipEnt )
        self.actionTooltipEnt = INVALID_ID
    end
end

function selector:OperateSelection(selectedEntities, selectorComponent)
    if ( #selectedEntities == 0 ) then
        self:DeselectAllEntities()

        if ( self.blueprint ~= self.baseBlueprint ) then
            self:ChangeBlueprint(self.baseBlueprint, "")
        end
    else
        local maxSelected = math.min( #selectedEntities, self.maxSelectedEntities )
        for i=#selectedEntities,maxSelected+1,-1 do
            selectedEntities[i] = nil
        end

        local changed = false
        for entity in Iter(self.selectedEntities) do --deselect old selected entities
            if( IndexOf( selectedEntities, entity ) == nil ) then
                self:DeselectEntity( entity )
                changed = true
            end
        end

        if( self.maxSelectedEntities > 1 and self.blueprint ~= self.baseBlueprint  ) then
            self:ChangeBlueprint(self.baseBlueprint, "")
        end

        local newPosition = {x=0,y=0,z=0}
        local diagonal = {x=1,y=1,z=1}
        for entity in Iter(selectedEntities ) do
            if ( IndexOf( self.selectedEntities, entity ) == nil ) then -- select new entities
                self:SelectEntity( entity )
            end

            if( EntityService:HasComponent( entity, "ResourceComponent" ) == true ) then
                newPosition = self.position
            else
                newPosition = VectorAdd( newPosition, EntityService:GetPosition(entity ))
                diagonal = BuildingService:GetBuildingGridSize(entity)
            end
        end

        local mod = 1 / #selectedEntities
        newPosition = VectorMulByNumber(newPosition, mod )

        self.selectorPosition = newPosition

        local container = selectorComponent:GetField("position_override"):ToContainer()
        local item = container:GetItem(0)
        if ( item == nil ) then item = container:CreateItem() end

        local itemHelper = reflection_helper(item)
        itemHelper.x = self.selectorPosition.x
        itemHelper.y = self.selectorPosition.y
        itemHelper.z = self.selectorPosition.z


        if ( (self.maxSelectedEntities == 1 and self.blueprint == self.baseBlueprint) or changed  ) then
            self:ChangeBlueprint(self.cornerBlueprint, "")
            diagonal.y = 1
            diagonal.x = math.max((math.max(SnapValue(diagonal.x, 0.5 ),1.0) - 0.5), 1.0)
            diagonal.z = math.max((math.max(SnapValue(diagonal.z, 0.5 ),1.0) - 0.5), 1.0)

            local children = EntityService:GetChildren( self.selector, true )
            for child in Iter(children ) do
                local childPos = EntityService:GetLocalPosition(child)
                childPos = VectorMul(childPos, diagonal)
                EntityService:SetPosition(child,childPos)
            end
        end

        self.selectedEntities = selectedEntities
    end
end

function selector:CheckMechActionMapperAction()
    local blocking = #self.selectedEntities > 0
    if ( blocking ~= self.blocking) then
        self.blocking = blocking
        PlayerService:SetActionBlocking( self.entity, BUILD_MODE_ACTION_MAPPER_NAME, "SELECT_BUILDING", self.blocking )
    end
end

function selector:OnSelectInProgress()
    local selectorComponent = EntityService:GetComponent(self.entity, "BuildingSelectorComponent")
    local selectedEntities =  self:FindEntitiesToSelect( reflection_helper(selectorComponent) )
    self:OperateSelection( selectedEntities, selectorComponent )
    self:CheckMechActionMapperAction()
end

function selector:OnBuildEnter()
    if ( self.blueprint == "" or self.blueprint == self.baseBlueprint ) then
        self:ChangeSelectorMode(SM_SELECT)
        return
    end

    self:DeselectAllEntities()
    self:DeactivateAllEntities()

    self:ChangeBlueprint(self.blueprint, self.ghostBlueprint)
end

function selector:OnBuildExit()
    self:RemoveScaleInfo()

end

function selector:OnBuildInProgress()
    self.transform = EntityService:GetWorldTransform( self.selector )
    if ( EntityService:IsAlive(self.selector ) and (self.category == "tools" or self.type == "floor")) then

        self.resizeScale[self.blueprint] = self.transform.scale

        -- Saving resizeScale for all Tools except picker (uses size only 1x1) and sell (does not load saved value)
        if (self.category == "tools" and self.type ~= "picker" and self.type ~= "sell" and self.type ~= "floor") then

            self.resizeScale["Tools"] = self.transform.scale
        end

        -- Saving resizeScale for all floors
        if ( self.type == "floor" and (self.category == "decorations" or self.category == "tools")) then

            self.resizeScale["Floors"] = self.transform.scale
        end
    end
end

function selector:ChangeSelectorMode( mode )
    if ( mode == self.mode ) then return end
    if ( mode ~= SM_BUILD and mode ~= SM_SELECT and mode ~= SM_INVALID ) then
        --Assert( false, "Requested selector mode is out of range" )
        return
    end

    local selectorComponent = reflection_helper(EntityService:GetComponent(self.entity , "BuildingSelectorComponent"))
    selectorComponent.mode = mode
    self.mode = mode
    if ( self.mode == SM_BUILD ) then
        self.stateMachine:ChangeState("build")
    elseif ( self.mode == SM_SELECT ) then
        self.stateMachine:ChangeState("select")
    else
        self.stateMachine:ChangeState("invalid")
        self.mode = SM_INVALID
    end
end

function selector:OnChangeSelectorModeRequest( evt )
    self:ChangeSelectorMode( evt:GetMode())
end

function selector:ActivateEntity( entity )
    QueueEvent("ActivateEntityRequest", entity, self.playerId )
end

function selector:OnActivateSelect()
    local changed = false
    for entity in Iter(self.activatedEntities) do --deselect old selected entities
        if( IndexOf( self.selectedEntities, entity ) == nil ) then
            self:DeactivateEntity( entity )
        end
    end
    for entity in Iter(self.selectedEntities ) do
        if( IndexOf( self.activatedEntities, entity ) ~= nil ) then goto continue end

        local selectableComponent = EntityService:GetConstComponent( entity, "SelectableComponent")
        Assert(selectableComponent ~= nil, "ERROR: No selectable component in selected entity!")
        self:ActivateEntity( entity )
        ::continue::
    end
    self.activatedEntities = self.selectedEntities
end

function selector:OnActivateBuild()
end

function selector:OnActivateSelectorRequest( evt )
    if ( self.mode == SM_SELECT) then
        self:OnActivateSelect()
    elseif(self.mode == SM_BUILD ) then
        self:OnActivateBuild()
    end
    self.activated = true
    self.activationTransform = EntityService:GetWorldTransform( self.selector )
end

function selector:OnDeactivateSelectorRequest( evt )
    self.activated = false
    self.activationTransform = nil
end

function selector:OnLeaveBuildModeRequest( evt )
    local fullExit =  evt:GetFullExit()
    if( fullExit ) then
        self:ChangeSelectorMode( SM_INVALID )
    else
        self:ChangeSelectorMode( self.mode + 1 ) -- what about 'SM_INVALID + 1' ???
    end
end

function selector:OnActivateEntityRequest( evt )
    if ( evt:GetPlayer() ~= self.playerId) then
        return
    end

    local entity = evt:GetEntity()
    if (IndexOf(self.activatedEntities, entity )~= nil ) then
        return
    end

    Insert(self.activatedEntities, evt:GetEntity())
end

function selector:OnDeactivateEntityRequest( evt )
    if ( evt:GetPlayer() ~= self.playerId) then
        return
    end
    Remove(self.activatedEntities, evt:GetEntity())
end

function selector:ResizeFloor( degree )

    -- Floor sizes
    self.scaleMapFloor = {
        1,
        2,
        3,
        4,

        8,

        12,

        -- 16,
        -- 20,
        -- 24,
        -- 28,
        -- 32,
    }

    local currentScale = EntityService:GetScale(self.selector).x

    local maxIndex = #self.scaleMapFloor

    local change = 1

    if ( degree > 0 ) then
        change = -1
    end

    local index = IndexOf(self.scaleMapFloor, currentScale )
    if ( index == nil ) then index = 1 end

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = 1
    elseif( newIndex == 0 ) then
        newIndex = maxIndex
    end

    local newScale = self.scaleMapFloor[newIndex]

    self.currentScale = newScale

    EntityService:SetScale( self.selector, newScale, 1.0, newScale)

    local savedValue = { x = newScale, y = 1.0, z = newScale }

    self.resizeScale[self.blueprint] = savedValue

    -- Saving resizeScale for all floors
    self.resizeScale["Floors"] = savedValue
end

function selector:RotateBuilding( degree )

    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end

    EntityService:Rotate(self.selector, 0.0, 1.0, 0.0, degree )
    local transform = EntityService:GetWorldTransform( self.selector )

    local lowBlueprint = BuildingService:FindLowUpgrade( self.blueprint )
    self.rotations[lowBlueprint] = transform.orientation
end

function selector:OnRotateSelectorRequest( evt )
    if ( self.mode == SM_SELECT) then

        local degree = evt:GetDegree()

        if ( mod_changeable_area_invert_rotation ~= nil and mod_changeable_area_invert_rotation == 1 ) then
            degree = - degree
        end

        if ( degree > 0 and #self.activatedEntities > 0 ) then

            local transform = EntityService:GetWorldTransform( self.entity )

            if ( is_server and is_client ) then

                local params = {
                    point_x = transform.position.x,
                    point_z = transform.position.z
                }

                for entity in Iter( self.activatedEntities ) do

                    QueueEvent( "LuaGlobalEvent", entity, "AreaCenterPointChangeEvent", params )
                end

            else

                local mapperName = "AreaCenterPointChangeRequest|" .. tostring(transform.position.x) .. "|" .. tostring(transform.position.z)

                for entity in Iter( self.activatedEntities ) do

                    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
                end
            end
        end

        return
    end

    if ( self.mode ~= SM_BUILD) then
        return
    end

    if (self.showScaleInfo ~= nil and EntityService:IsAlive(self.showScaleInfo ) ) then
        EntityService:RemoveEntity(self.showScaleInfo)
        self.showScaleInfo = nil
        ConsoleService:ExecuteCommand( "showed_change_info 1" )
    end

    local data = EntityService:GetDatabase( self.selector) 
    local action = ""
    if ( data ) then
        action = data:GetStringOrDefault( "action", "")
    end

    local degree = evt:GetDegree()

    if ( action == "floor" ) then
        self:ResizeFloor( degree )
    elseif (action == "" ) then
        self:RotateBuilding( degree )
    end

end

function selector:OnLoad( )
    if  (self.resizeScale == nil ) then
        self.resizeScale = {}
    end
    if ( self.rotations == nil ) then
        self.rotations = {}
    end
    if ( self.cameraCuller == nil ) then
        self.cameraCuller = INVALID_ID
    end
    if ( self.cameraCullerBlueprint == nil ) then
        self.cameraCullerBlueprint = "misc/selector_camera_culler"
    end
end

return selector
 