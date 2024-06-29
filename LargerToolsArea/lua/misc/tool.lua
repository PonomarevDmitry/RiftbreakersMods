class 'tool' ( LuaEntityObject )
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

local SM_BUILD   = 1
local SM_SELECT  = 2
local SM_INVALID = 3
local BUILD_MODE_ACTION_MAPPER_NAME = "buildModeActionMapv2"

function tool:__init()
	LuaEntityObject.__init(self,self)
end

function tool:init()
    
	self.stateMachine = self:CreateStateMachine()
	self.stateMachine:AddState( "working", {enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit" } )

    self.stateMachine:ChangeState("working")
    self.childPos = {}
    self.initialScale = {x=1,y=1,z=1}

    if ( self.OnPreInit ) then
        self:OnPreInit()
    end
    self:InitializeValues()

    if ( self.OnInit ) then
        self:OnInit()
    end
    self:RescaleChild()
end

function tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function tool:GetScaleFromDatabase()
    local scale = {}
    scale.x = self.data:GetFloatOrDefault("resize_scale_x", self.initialScale.x)
    scale.y = self.data:GetFloatOrDefault("resize_scale_y",  self.initialScale.y)
    scale.z = self.data:GetFloatOrDefault("resize_scale_z",  self.initialScale.z)
    return scale
end

function tool:InitializeValues()
    self.previousSelected = {}
    self.selectedEntities = {}
    self.selector = EntityService:GetParent( self.entity )

	self:RegisterHandler( self.selector, "ActivateSelectorRequest", "OnActivateSelectorRequest" )
	self:RegisterHandler( self.selector, "DeactivateSelectorRequest", "OnDeactivateSelectorRequest" )
	self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.action = self.data:GetStringOrDefault( "action", "")
    if ( self.action == "") then
        local buildingComponent = reflection_helper(EntityService:GetComponent(self.entity, "BuildingComponent") )
        self.action = buildingComponent.type
    end

    --local boundsSize = EntityService:GetBoundsSize( self.entity)
    self.boundsSize = {x=1.0, y=1.0, z=1.0} -- VectorMulByNumber( boundsSize, 0.5 )
    local scale = self:GetScaleFromDatabase()
    EntityService:SetScale(self.entity, scale.x, scale.y, scale.z)

    local orientation = {x=0,y=0,z=0,w=1}
    EntityService:SetOrientation( self.entity, orientation )

    self:SpawnCornerBlueprint()

    self.currentScale = scale.x
    self.activated = false
    self:SetChildrenPosition()
    
    local children = EntityService:GetChildren( self.corners, true )
    for child in Iter(children ) do
        if ( EntityService:GetComponent(child, "GuiComponent") ~= nil ) then
            self.infoChild = child
        end
    end 

    self.scaleMap = {
        1,
        2,
        3,
        4,
        8,
        12,
        16,
        20,
        24,
        28,
        32,
    }

    
end

function tool:OnWorkEnter()
end

function tool:OnWorkExit()
end

function tool:FindEntitiesToSelect( selectorComponent )
    local position = selectorComponent.position 
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale))
    local possibleSelectedEnts = FindService:FindGridOwnersByBox( min, max )

    local distances = {}
    for entity in Iter( possibleSelectedEnts) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity );    
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(possibleSelectedEnts, sorter)

    local selectedEntities = {}
    for entity in Iter(possibleSelectedEnts ) do
        local selectableComponent = EntityService:GetConstComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then goto continue end
    
        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        
        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= 2 ) then goto continue end 
        end
    
        Insert(selectedEntities, entity )
        ::continue::
    end
    
    if ( self.FilterSelectedEntities ) then
        selectedEntities = self:FilterSelectedEntities( selectedEntities )
    end
    
    return selectedEntities
end

function tool:RescaleChild()
    local scale = EntityService:GetScale( self.entity )
    scale.x = 1.0 / scale.x
    scale.z  = 1.0 / scale.z
    if ( self.childEntity ~= nil and self.childEntity ~= INVALID_ID ) then
        EntityService:SetScale( self.childEntity,  scale.x, scale.y, scale.z )
    end
    if ( self.corners ~= nil ) then
        EntityService:SetScale( self.corners,  scale.x, scale.y, scale.z )
    end
end

function tool:OnWorkExecute()
    self:RescaleChild()
    local selectorComponent = EntityService:GetComponent(self.selector, "BuildingSelectorComponent") 
    local previousSelection = self.selectedEntities
    self.selectedEntities =  self:FindEntitiesToSelect( reflection_helper(selectorComponent) )
    if ( self.RemovedFromSelection) then
        for ent in Iter( previousSelection ) do 
            if ( IndexOf( self.selectedEntities, ent ) == nil ) then
                self:RemovedFromSelection( ent )
            end
        end
    end
    
    if ( self.AddedToSelection) then
        for ent in Iter( self.selectedEntities ) do 
            if ( IndexOf( previousSelection, ent ) == nil ) then
                self:AddedToSelection( ent )
                if ( self.activated )  then
                    self:OnActivateEntity( ent )
                end
            end
        end
    end
    
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function tool:OnActivateSelectorRequest()
    self.activated = true
    for entity in Iter(self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function tool:OnDeactivateSelectorRequest()
    self.activated = false
    if ( self.OnDeactivate ) then
        self:OnDeactivate()
    end
end

function tool:SetChildrenPosition()
    local diagonal = VectorMulByNumber(self.boundsSize , self.currentScale)
    diagonal.y = 1
    local children = EntityService:GetChildren( self.corners, true )
    for child in Iter(children ) do
        local childPos = EntityService:GetLocalPosition(child)
        if ( self.childPos[child] == nil ) then
            self.childPos[child] = childPos
        else
            childPos = self.childPos[child]
        end
        childPos = VectorMul(childPos, diagonal)
        EntityService:SetPosition(child,childPos)
    end
end

function tool:OnRotateSelectorRequest( evt )
    local degree = evt:GetDegree()
    local currentScale = EntityService:GetScale(self.entity).x

    local maxIndex = #self.scaleMap
    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local index = IndexOf(self.scaleMap, currentScale )
    if ( index == nil ) then index = 1 end

    local newValue = index + change
    if ( newValue > maxIndex ) then
        newValue = 1
    elseif( newValue == 0 ) then
        newValue = maxIndex
    end
    self.currentScale = self.scaleMap[newValue]
    EntityService:SetScale( self.entity, self.currentScale, 1.0, self.currentScale)
    if ( self.OnRotate ) then
        self:OnRotate(degree)
    end

    self:SetChildrenPosition()
    self:RescaleChild()

end

function  tool:OnRelease()
    if ( self.RemovedFromSelection ) then
        for ent in Iter(self.selectedEntities ) do
            self:RemovedFromSelection( ent )
        end
    end
    EntityService:RemoveEntity(self.corners)    
end

function tool:OnActivateEntity( entity )
end

return tool
 