local building_base = require("lua/buildings/building_base.lua")

class 'portal' ( building_base )

function portal:__init()
	building_base.__init(self)
end

function portal:OnInit()
	self.portalEnergy = nil
	
	self.portalVersion = 1
	self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function portal:OnTeleportAppearEnter()
	local database = EntityService:GetOrCreateDatabase( self.portalEnergy )
	if ( database )  then
		database:SetInt("leaving", 1)
	end
end

function portal:OnTeleportAppearExit()
	local database = EntityService:GetOrCreateDatabase( self.portalEnergy )
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

	local blueprintName = "misc/rift"

	local position = EntityService:GetPosition( self.entity )

	local team = EntityService:GetTeam( self.entity )

	local newPortal = EntityService:SpawnEntity( blueprintName, position, team )

	local playerReferenceComponentRef = reflection_helper(EntityService:CreateComponent(newPortal, "PlayerReferenceComponent"))
	playerReferenceComponentRef.reference_type.internal_enum = 3

	local selfPlayerReferenceComponent = EntityService:GetComponent(self.entity, "PlayerReferenceComponent")
	if ( selfPlayerReferenceComponent ) then

		playerReferenceComponentRef.player_id = reflection_helper( selfPlayerReferenceComponent ).player_id
	else
		playerReferenceComponentRef.player_id = 0
	end

	return true
end

function portal:OnInteractWithEntityRequest( event )
	local player = PlayerService:GetPlayerByMech( event:GetOwner() )
	QueueEvent("ChangeActiveMinimapRequest", event_sink, 1, player )
end

function portal:OnLoad()
	building_base.OnLoad(self)
	if ( self.portalVersion == nil or self.portalVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.portalVersion = 1
	end
end
return portal
