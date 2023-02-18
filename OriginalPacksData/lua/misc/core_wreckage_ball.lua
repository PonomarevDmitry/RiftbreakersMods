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
	--self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" )
    
	self.disabledEnts = {}
end

function core_wreckage_ball:OnLuaGlobalEvent( event )
	if "AlienCoreEnabled" == event:GetEvent() then
        local component = reflection_helper( EntityService:CreateComponent(self.entity,"InteractiveComponent") );
        component.slot = "EXTRACTOR"
        component.radius = 9 
        component.remove_entity = 0
    end
end

function core_wreckage_ball:OnInteractWithEntityRequest( event )

	QueueEvent( "LuaGlobalEvent", event_sink, "AlienCoreActivated", self.data )
end

function core_wreckage_ball:OnEnteredTriggerEvent( evt )
	GuiService:EnableMinimapInterference()
	PlayerService:DisableBuildMode( evt:GetOtherEntity() )
	Insert(self.disabledEnts, evt:GetOtherEntity() )
	--EffectService:AttachEffects( evt:GetOtherEntity(), "interference" )
	
end

function core_wreckage_ball:OnLeftTriggerEvent( evt )
	GuiService:DisableMinimapInterference()
	PlayerService:EnableBuildMode( evt:GetOtherEntity() )
	--EffectService:DestroyEffectsByGroup( evt:GetOtherEntity(), "interference" )
	Remove( self.disabledEnts, evt:GetOtherEntity() )
end

function core_wreckage_ball:OnDestroyRequest()
	EffectService:SpawnEffects(self.entity, "wreck")
	EntityService:RequestDestroyPattern( self.entity, "default", true )	
end

return core_wreckage_ball
