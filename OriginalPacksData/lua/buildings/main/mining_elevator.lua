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
end

function mining_elevator:OnBuildingStart()
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillConstructionStarted", {} )
end

function mining_elevator:OnBuildingEnd()
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillConstructionFinished", {} )
end

function mining_elevator:CanEnableSpecialAction()
	local descending = self.data:GetFloatOrDefault("is_descending", 0)
	return CampaignService:IsPlanetaryJumpAvailable() and descending == 0
end

function mining_elevator:OnSpecialAction( req )
	EffectService:AttachEffects(self.entity, "descend")
	self.data:SetFloat("is_descending", 1)
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillActivated", {} )
end

function mining_elevator:OnSpecialActionDenied( req )
	EntityService:ShowTimeoutSoundEvent( event_sink, 30.0, "voice_over/announcement/travel_not_unavailable" , false)
end

return mining_elevator
