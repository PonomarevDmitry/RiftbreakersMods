require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'base_skill' ( LuaEntityObject )

function base_skill:__init()
	LuaEntityObject.__init(self, self)
end

function base_skill:init()
	self:RegisterHandler( self.entity, "UnitAggressiveStateEvent",  "_OnUnitAggressiveStateEvent" )
	self:RegisterHandler( self.entity, "UnitNotAggressiveStateEvent",  "_OnUnitNotAggressiveStateEvent" )
	self:RegisterHandler( self.entity, "UnitDeadStateEvent",  "_OnUnitDeadStateEvent" )
    self:RegisterHandler( self.entity, "UnitStopMoveStateEvent",  "_OnUnitStopMoveStateEvent" )
    self:RegisterHandler( self.entity, "UnitStartMoveStateEvent",  "_OnUnitStartMoveStateEvent" )
    self:RegisterHandler( self.entity, "TargetHasChangedEvent",  "_TargetHasChangedEvent" )
  	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "_OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "_OnLeftTriggerEvent" )  

    self.currentTarget = INVALID_ID
    self.inTrigger  = {}

    local parent = EntityService:GetParent( self.entity )
    EntityService:SetTeam( self.entity, EntityService:GetTeam( parent ) )

    SetupComponentFieldOverrides( self.entity, self.data )

    if self.OnInit then
	    self:OnInit()
    end
end

function base_skill:SetupScale( scale )
	local parent = EntityService:GetParent( self.entity )
	if parent ~= INVALID_ID then 
		local parentScale = EntityService:GetScale( parent )
		EntityService:SetScale( self.entity, scale / parentScale.x, scale / parentScale.y, scale / parentScale.z )
	else
		EntityService:SetScale( self.entity, scale, scale, scale )
	end
end

function base_skill:_OnUnitAggressiveStateEvent( evt )
    if self.OnUnitAggressiveStateEvent then
        self:OnUnitAggressiveStateEvent( evt )
    end
end

function base_skill:_OnUnitNotAggressiveStateEvent( evt )
    if self.OnUnitNotAggressiveStateEvent then
        self:OnUnitNotAggressiveStateEvent( evt )
    end
end

function base_skill:_OnUnitDeadStateEvent( evt )
    if self.OnUnitDeadStateEvent then
        self:OnUnitDeadStateEvent( evt )
    end
end

function base_skill:_OnUnitStartMoveStateEvent( evt )
    if self.OnUnitStartMoveStateEvent then
        self:OnUnitStartMoveStateEvent( evt )
    end
end

function base_skill:_OnUnitStopMoveStateEvent( evt )
    if self.OnUnitStopMoveStateEvent then
        self:OnUnitStopMoveStateEvent( evt )
    end
end

function base_skill:_TargetHasChangedEvent( evt )
    self.currentTarget = evt:GetTarget()

    if self.TargetHasChangedEvent then
        self:TargetHasChangedEvent( evt )
    end
end

function base_skill:_OnEnteredTriggerEvent( evt )
    local entity = evt:GetOtherEntity()
    
    if self.OnEnteredTriggerEvent then
        self:OnEnteredTriggerEvent( evt, entity )
    end

    table.insert( self.inTrigger, entity )

    --LogService:Log( "base_skill:_OnEnteredTriggerEvent : " .. tostring( EntityService:GetBlueprintName( entity ) ) )
end

function base_skill:_OnLeftTriggerEvent( evt )
    local entity = evt:GetOtherEntity()


    if self.OnLeftTriggerEvent then
        self:OnLeftTriggerEvent( evt, entity )
    end

    Remove( self.inTrigger, entity )
end

return base_skill