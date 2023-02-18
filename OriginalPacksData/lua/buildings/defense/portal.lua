local building_base = require("lua/buildings/building_base.lua")

class 'portal' ( building_base )

function portal:__init()
	building_base.__init(self)
end

function portal:OnInit()
	self.portalEnergy = nil
end

function portal:OnTeleportAppearEnter()
	local database = EntityService:GetDatabase( self.portalEnergy )
	if ( database )  then
		database:SetInt("leaving", 1)
	end
end

function portal:OnTeleportAppearExit()
	local database = EntityService:GetDatabase( self.portalEnergy )
	if ( database )  then
		database:SetInt("leaving", 0)
	end
end


function portal:OnSellStart()
	self.placeSM = self:CreateStateMachine()
	self.placeSM:AddState( "place", { from="*", enter="OnPlaceEnter", execute="OnPlaceExecute", exit="OnPlaceExit" } )
	self.placeSM:AddState( "leave",{} )
	self.placeSM:ChangeState( "place" )
end

function portal:OnPlaceEnter( state )
	state:SetDurationLimit( 0.5 )
end

function portal:OnPlaceExecute( state )
	if ( self.portalEnergy ~= nil ) then
		local currentProgress = ( 1 -  state:GetDuration() / 0.5 )
		EntityService:SetOrientation( self.portalEnergy, 0, 1, 0, currentProgress * 360 )
		EntityService:SetScale( self.portalEnergy, currentProgress , 1.0, currentProgress )
	end
end

function portal:OnPlaceExit( state )
	if ( self.portalEnergy ~= nil ) then
		EntityService:RemoveEntity( self.portalEnergy )
		self:UnregisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	end
end

function portal:OnRemove()
	if ( self.portalEnergy ~= nil ) then
		EntityService:RemoveEntity( self.portalEnergy )
	end
end

function portal:OnBuildingEnd()
	self.portalEnergy = EntityService:SpawnAndAttachEntity( "buildings/defense/rift_portal", self.entity )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	
	self:RegisterHandler( self.portalEnergy, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.portalEnergy, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function portal:OnEnteredTriggerEvent(evt)
end

function portal:OnDestroy()
	EntityService:ShowTimeoutSoundEvent(self.entity, 30.0, "voice_over/announcement/portal_destroyed" , false)
	return true
end

return portal
