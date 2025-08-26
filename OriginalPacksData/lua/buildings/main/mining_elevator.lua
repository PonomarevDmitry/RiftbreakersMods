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
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
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
	local playerId = req:GetPlayerId()
	self:Interact( playerId )
end

function mining_elevator:OnSpecialActionDenied( req )
	EntityService:ShowTimeoutSoundEvent( event_sink, 30.0, "voice_over/announcement/travel_not_unavailable" , false)
end

function mining_elevator:OnLuaGlobalEvent( event )
	if ( event:GetEvent() == "CavernsDrillActivated" ) then
		EffectService:AttachEffects(self.entity, "descend")
		self.data:SetFloat("is_descending", 1)
		EntityService:RemoveComponent( self.entity, "InteractiveComponent")
	end
end

function mining_elevator:Interact( player )
	if ( PlayerService:IsPlayerVoteInProgress()) then
		return		
	end

	if ( self:CanEnableSpecialAction() ) then                 

		if ( #PlayerService:GetConnectedPlayers() > 1) then


			local voteParams =
			{
				localization = "gui/planetary_scanner/go_to_next_map_vote",
				timeout = 60.0,
				gui_id = "gui/popup/popup_vote_planetaryscanner",
				default_action = "button_no",
				vote_type = "GoToNextMapRequest",
				map = "caverns",
				win_label = "gui/planetary_scanner/rift_jump_commencing",
				start_action = "button_yes",
				player = PlayerService:GetPlayerName( player ),
				actions = 
				{
					button_yes = 
					{ 
						localization = "gui/hud/vote_accepted" ,
						event_name	 = "LuaGlobalEvent",
						event_params = { argName1 = event_sink, argName2 = "CavernsDrillActivated" }
					},

					button_no =
					{
						localization = "gui/hud/vote_negative" ,
						event_name = "",
						event_params = {}
					}
				}
			}
			GameStreamingService:StartPlayerVote(player, voteParams, true )
		else
			EffectService:AttachEffects(self.entity, "descend")
			self.data:SetFloat("is_descending", 1)
			EntityService:RemoveComponent( self.entity, "InteractiveComponent")
			QueueEvent( "LuaGlobalEvent", event_sink, "CavernsDrillActivated", {} )
		end
	else
		EntityService:ShowTimeoutSoundEvent( event_sink, 30.0, "voice_over/announcement/travel_not_unavailable" , false)
	end
end

function mining_elevator:OnInteractWithEntityRequest( event )
	local owner = event:GetOwner()
	local player = PlayerService:GetPlayerForEntity( owner )
	self:Interact( player )
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
