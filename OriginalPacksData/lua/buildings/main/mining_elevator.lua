require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
local building = require("lua/buildings/building.lua");

class 'mining_elevator' ( building )

function mining_elevator:__init()
	building.__init(self)
end

function mining_elevator:OnInit()
	self:RegisterHandler( self.entity , "SpecialBuildingActionRequest", "OnSpecialAction" )
	self:RegisterHandler( self.entity , "SpecialBuildingActionDeniedRequest", "OnSpecialActionDenied" )
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self.elevatorVersion = 1
end

function mining_elevator:OnBuildingStart()
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillConstructionStarted", {} )
end

function mining_elevator:OnBuildingEnd()
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillConstructionFinished", {} )
end

function mining_elevator:CanEnableSpecialAction()
    local campaignData = CampaignService:GetCampaignData()
	local drillEnable = campaignData:GetStringOrDefault("CavernsOutpostStage2DrillEnabled", "true" )
	local descending = self.data:GetFloatOrDefault("is_descending", 0)
	return CampaignService:IsPlanetaryJumpAvailable() and descending == 0 and drillEnable == "true"
end

function mining_elevator:OnSpecialAction( req )
	EffectService:AttachEffects(self.entity, "descend")
	self.data:SetFloat("is_descending", 1)
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillActivated", {} )
end

function mining_elevator:OnSpecialActionDenied( req )
	EntityService:ShowTimeoutSoundEvent( event_sink, 30.0, "voice_over/announcement/travel_not_unavailable" , false)
end

function mining_elevator:OnInteractWithEntityRequest( event )
	if ( self:CanEnableSpecialAction() ) then                 
		EffectService:AttachEffects(self.entity, "descend")
		self.data:SetFloat("is_descending", 1)
		EntityService:RemoveComponent( self.entity, "InteractiveComponent")
		QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillActivated", {} )
	else
		EntityService:ShowTimeoutSoundEvent( event_sink, 30.0, "voice_over/announcement/travel_not_unavailable" , false)
	end
end

function mining_elevator:OnLoad()
	building.OnLoad(self)
    
    if ( self.elevatorVersion == nil or self.elevatorVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.elevatorVersion = 1
	end
	
	if ( self.data:GetFloatOrDefault("is_descending", 0.0) == 1) then
		QueueEvent("DissolveEntityRequest", self.entity, 1.0, 0.0 )
		EntityService:SpawnEntity( "props/special/human_structures/mining_elevator_empty",self.entity, EntityService:GetTeam( self.entity ))
	end
end

return mining_elevator
