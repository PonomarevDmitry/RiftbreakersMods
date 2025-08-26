class 'core_wreckage_ball' ( LuaEntityObject )
require("lua/units/units_utils.lua")
require("lua/utils/table_utils.lua")

function core_wreckage_ball:__init()
	LuaEntityObject.__init(self, self)
end

function core_wreckage_ball:init()
	SetupUnitScale( self.entity, self.data )

    self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" )
	--self:RegisterHandler( self.entity, "LeftTriggerEvent", "OnLeftTriggerEvent" )
	self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" )

	self.disabledEnts = {}
	self.version = 1
end

function core_wreckage_ball:OnLuaGlobalEvent( event )
	if "AlienCoreEnabled" == event:GetEvent() then
        local component = reflection_helper( EntityService:CreateComponent(self.entity,"InteractiveComponent") );
        component.slot = "EXTRACTOR"
        component.radius = 9 
        component.remove_entity = 0
		component.priority = 15
    end
end

function core_wreckage_ball:OnInteractWithEntityRequest( event )
	if self.core_activated_or_destroyed then
		return
	end

	self.core_activated_or_destroyed = true

	QueueEvent( "LuaGlobalEvent", event_sink, "AlienCoreActivated", self.data )
	HealthService:SetImmortality( self.entity, true )
	HealthService:SetHealthInPercentage( self.entity, 100)
end

function core_wreckage_ball:OnEnteredTriggerEvent( evt )
	PlayerService:DisableBuildMode( evt:GetOtherEntity() )
	Insert(self.disabledEnts, evt:GetOtherEntity() )
	
end

function core_wreckage_ball:OnLeftTriggerEvent( evt )
	PlayerService:EnableBuildMode( evt:GetOtherEntity() )
	Remove( self.disabledEnts, evt:GetOtherEntity() )
end

function core_wreckage_ball:OnDestroyRequest()
	if self.core_activated_or_destroyed then
		return
	end

	self.core_activated_or_destroyed = true

	EntityService:RequestDestroyPattern( self.entity, "default", true )	
end

function core_wreckage_ball:OnRemove()
	for ent in Iter(self.disabledEnts) do
		PlayerService:EnableBuildMode( ent )
	end
	self.disabledEnts = {}
end

function core_wreckage_ball:OnLoad()
	if ( not self.version) then
		GuiService:DisableMinimapInterference()
		self.version = 1
	end
end

return core_wreckage_ball
