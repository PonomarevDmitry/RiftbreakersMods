local building_base = require("lua/buildings/building_base.lua")

class 'cosmic_portal' ( building_base )

function cosmic_portal:__init()
	building_base.__init(self)
end

function cosmic_portal:OnInit()
	self.portalEnergy = nil
	
	self.cosmic_portalVersion = 1
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function cosmic_portal:OnTeleportAppearEnter()
	local database = EntityService:GetDatabase( self.portalEnergy )
	if ( database )  then
		database:SetInt("leaving", 1)
	end
end

function cosmic_portal:OnTeleportAppearExit()
	local database = EntityService:GetDatabase( self.portalEnergy )
	if ( database )  then
		database:SetInt("leaving", 0)
	end
end


function cosmic_portal:OnSellStart()
	self.placeSM = self:CreateStateMachine()
	self.placeSM:AddState( "place", { from="*", enter="OnPlaceEnter", execute="OnPlaceExecute", exit="OnPlaceExit" } )
	self.placeSM:AddState( "leave",{} )
	self.placeSM:ChangeState( "place" )
end

function cosmic_portal:OnPlaceEnter( state )
	state:SetDurationLimit( 0.5 )
end

function cosmic_portal:OnPlaceExecute( state )
	if ( self.portalEnergy ~= nil ) then
		local currentProgress = ( 1 -  state:GetDuration() / 0.5 )
		EntityService:SetOrientation( self.portalEnergy, 0, 1, 0, currentProgress * 360 )
		EntityService:SetScale( self.portalEnergy, currentProgress , 1.0, currentProgress )
	end
end

function cosmic_portal:OnPlaceExit( state )
	if ( self.portalEnergy ~= nil ) then
		EntityService:RemoveEntity( self.portalEnergy )
		self:UnregisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	end
end

function cosmic_portal:OnRemove()
	if ( self.portalEnergy ~= nil ) then
		EntityService:RemoveEntity( self.portalEnergy )
	end
end

function cosmic_portal:OnBuildingEnd()
	self.portalEnergy = EntityService:SpawnAndAttachEntity( "buildings/defense/cosmic_rift_portal", self.entity )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	
	self:RegisterHandler( self.portalEnergy, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.portalEnergy, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function cosmic_portal:OnEnteredTriggerEvent(evt)
end

function cosmic_portal:OnDestroy()
	EntityService:ShowTimeoutSoundEvent(self.entity, 30.0, "voice_over/announcement/portal_destroyed" , false)
	return true
end

function cosmic_portal:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("ChangeActiveMinimapRequest", event_sink, 1, player )
end

function cosmic_portal:OnLoad()
    building_base.OnLoad(self)
    if ( self.portalVersion == nil or self.portalVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.portalVersion = 1
	end
end
return cosmic_portal
