local building = require("lua/buildings/building.lua")
class 'mega_rift_station' ( building )

function mega_rift_station:__init()
	building.__init(self)
end

function mega_rift_station:OnInit()
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name

	self.fadeOutTime		= self.data:GetFloatOrDefault("fadeout_time", 1 )


    self.checkerMachine = self:CreateStateMachine()
	self.checkerMachine:AddState( "working", { execute="OnExecute", interval=1 } )
	self.checkerMachine:AddState( "destruction", { enter="OnEnterDestruction", exit="OnExitDestruction" } )
	self.checkerMachine:ChangeState( "working" )
	self.megastructureWorking = false
	self.activated = false
	self.waitingForFinalActivate = false
	self.reseting = false
	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity , "SpecialBuildingActionRequest", "OnSpecialAction" )
	self:RegisterHandler( event_sink , "LuaGlobalEvent", "OnLuaGlobalEvent" )
	BuildingService:DisableBuilding( self.entity )

	self.children = EntityService:GetChildren( self.entity, false )

end

function mega_rift_station:SetGlowFactor( factor )
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", factor )
	for child in Iter( self.children ) do
		EntityService:SetGraphicsUniform( child, "cGlowFactor", factor )
	end
end

function mega_rift_station:SetDatabaseParameter( parameterName, value )
	self.data:SetInt( parameterName, value )
	for child in Iter( self.children ) do
		local data = EntityService:GetDatabase( child )
		if ( data ) then
			data:SetInt( parameterName, value )
		end
	end
end

function mega_rift_station:AttachEffectsByType( name )
	if (not EffectService:HasEffectByGroup( self.entity, name ) ) then
		EffectService:AttachEffects(self.entity, name)
		for child in Iter( self.children ) do
			EffectService:AttachEffects(child, name)
		end
	end
end

function mega_rift_station:DestroyEffectsByType( name )
	EffectService:DestroyEffectsByGroup(self.entity, name)
	for child in Iter( self.children ) do
		EffectService:DestroyEffectsByGroup(child, name)
	end
end


function mega_rift_station:OnActivate()
	--LogService:Log("OnActive " .. tostring(self.megastructureWorking))
	if ( self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = true
end

function mega_rift_station:RemoveComponent()
		--LogService:Log("RemoveComponent " .. tostring(self.megastructureWorking))
		if ( not self.megastructureWorking  ) then
		return
	end
	self.megastructureWorking = false
end

function mega_rift_station:OnDeactivate()
	--LogService:Log("OnDeactivate " )
	self:RemoveComponent()
    EntityService:DisableComponent( self.entity, "InteractiveComponent")
   	self.data:SetInt("is_special_action_enabled",0)
end

function mega_rift_station:OnInteractWithEntityRequest( event )
end

function mega_rift_station:OnRemove()

	self:RemoveComponent()
end

function mega_rift_station:OnExecute()    
	if ( self.reseting ) then
		return
	end

	local data = CampaignService:GetCampaignData()
	local stringValue = data:GetStringOrDefault("global.arcology_assembly_complete","")

	local isWaitingForActivation = data:GetStringOrDefault("global.prime_rift_complete","false")

	if ( isWaitingForActivation == "true" ) then
		self:AttachEffectsByType( "portal_opened" )
		self.waitingForFinalActivate = true
        EntityService:EnableComponent( self.entity, "InteractiveComponent")
        self.data:SetInt("is_special_action_enabled",1)
		return
	end

	-- Check if all arcology workshops are working

	local arcology_workshops = 
    {
        "arcology_workshop",
        "gravitational_hyper_lens",
        "hydroponic_lab",
        "nanobot_center"
    }

    local allWorking = true
    for item in Iter( arcology_workshops ) do
        if ( data:GetFloatOrDefault( item, 0 ) == 0 ) then
            allWorking = false
        end
    end
	allWorking = allWorking and BuildingService:IsBuildingPowered( self.entity ) and BuildingService:IsResourceSupplied( self.entity ) and BuildingService:IsPlayerWorking( self.entity )
	
	if stringValue == "true" and allWorking == true then
		data:SetFloat( self.name, 1 )
		--LogService:Log("active")
		if ( not self.active ) then
        	self.active = true
			--LogService:Log("activated")
			self:SetGlowFactor( 1 )
			if ( not self.activated) then
				self:AttachEffectsByType( "idle" )
	        	EntityService:EnableComponent( self.entity, "InteractiveComponent")
		        self.data:SetInt("is_special_action_enabled",1)
			end
		end
    elseif( not self.waitingForFinalActivate ) then
		self:DestroyEffectsByType( "idle" )
		self:SetGlowFactor( 0 )
		data:SetFloat( self.name, 0 )
		--LogService:Log("disable")
		self.active = false
        EntityService:DisableComponent( self.entity, "InteractiveComponent")
        self.data:SetInt("is_special_action_enabled",0)
        BuildingService:DisableBuilding( self.entity )
    end

end

function mega_rift_station:SpecialAction()
	self:DestroyEffectsByType( "idle" )

	QueueEvent( "LuaGlobalEvent", event_sink, "MegaRiftStationActivated", {} )

	if ( self.waitingForFinalActivate == true ) then
		CampaignService:UnlockAchievement( ACHIEVEMENT_SAVE_GALATEA )
	else
		self.activated = true
		BuildingService:EnableBuilding( self.entity )
        EntityService:DisableComponent( self.entity, "InteractiveComponent")
        self.data:SetInt("is_special_action_enabled",0)
		MissionService:ActivateMissionFlow("logic/missions/campaigns/story/mega_final_attack_start.logic")
	end

end

function mega_rift_station:OnInteractWithEntityRequest( event )
    self:SpecialAction()
end

function mega_rift_station:CanEnableSpecialAction()
    return self.active and ( not self.activated or self.waitingForFinalActivate ) and not self.reseting
end

function mega_rift_station:OnSpecialAction()
    self:SpecialAction()
end


function mega_rift_station:_OnBuildingPoweredEvent()
	if ( self.power == -1 or self.power == 0 ) then 	
		self.power = 1
		self:SetDatabaseParameter( "power", self.power )
		self:AttachEffectsByType( "powered" )
	end
	
end

function mega_rift_station:_OnBuildingPowerOffEvent()
	if ( self.power == -1 or self.power == 1 ) then
		self.power = 0
		self:SetDatabaseParameter( "power", self.power )
		self:DestroyEffectsByType( "powered" )
	end
end


function mega_rift_station:OnLuaGlobalEvent( event )
	if ( event:GetEvent() == "PrimePortalResetStartEvent" ) then
		self.reseting = true 
        EntityService:DisableComponent( self.entity, "InteractiveComponent")
        self.data:SetInt("is_special_action_enabled",0)
        BuildingService:DisableBuilding( self.entity )
		self:DestroyEffectsByType( "powered" )
		self.activated = false
	elseif ( event:GetEvent() == "PrimePortalResetEndEvent") then
		self.reseting = false
		self.activated = false
	end
end

function mega_rift_station:OnDestroy()

	if ( self.activated or self.waitingForFinalActivate) then
		GuiService:FadeOutToWhite( self.fadeOutTime )
		self.checkerMachine:ChangeState( "destruction" )
	end
end
function mega_rift_station:OnEnterDestruction( state )
	state:SetDurationLimit( self.fadeOutTime )
	EntityService:DissolveEntity( self.entity, self.fadeOutTime )
end

function mega_rift_station:OnExitDestruction( state )
	local missionResult = StringToMissionStatus("lose");
	MissionService:FinishCurrentMission( missionResult );
end

function mega_rift_station:OnLoad()
	building.OnLoad(self)
	self.children = EntityService:GetChildren( self.entity, false )
end

return mega_rift_station
