class 'cave_entrance' ( LuaEntityObject )

function cave_entrance:__init()
	LuaEntityObject.__init(self,self)
end

function cave_entrance:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

function cave_entrance:OnLuaGlobalEvent( event )
	if "CaveEntranceEnabled" == event:GetEvent() then
        local component = reflection_helper( EntityService:CreateComponent(self.entity,"InteractiveComponent") );
        component.slot = "ACTIVATOR"
        component.radius = 6 
        component.remove_entity = 0
        component.remove_component = 0
		component.priority = 15
    end
end


function cave_entrance:OnInteractWithEntityRequest( evt )
	local component = EntityService:GetSingletonComponent( "VoteStatusComponent" )
	if ( component ) then
    	local container = component:GetField("vote_type_count"):ToContainer()
		if ( container:GetCount() > 0 ) then
			return
		end
	end

	local owner = evt:GetOwner()
	local player = PlayerService:GetPlayerForEntity( owner )
	
	local params = { target = tostring( EntityService:GetName( self.entity ) ) }
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
					event_params = { argName1 = event_sink, argName2 = "CavernsEntranceActivated", argName3 = params }
				},

				button_no =
				{
					localization = "gui/hud/vote_negative" ,
					event_name = "",
					event_params = {}
				}
			}
		}
		GameStreamingService:StartPlayerVote(player, voteParams, false )
	else
		QueueEvent( "LuaGlobalEvent", event_sink, "CavernsEntranceActivated", params )	
	end
end


return cave_entrance