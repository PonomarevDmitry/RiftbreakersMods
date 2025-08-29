local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/database_utils.lua")

class 'activate_all_bioanomalies' ( item )

function activate_all_bioanomalies:__init()
    item.__init(self,self)
end

function activate_all_bioanomalies:OnEquipped()
    self.duration = 0.0
end

function activate_all_bioanomalies:OnActivate()

    self.duration = self.duration or 0.0



    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.activateAfter = database:GetFloat("activate_after")

    if ( 0 <= self.duration and self.duration <= self.activateAfter ) then

        if ( self.timer == nil ) then

            self.penaltySpeedOwner = self.owner

            QueueEvent( "AddMaxSpeedModifierRequest", self.penaltySpeedOwner, "activate_all_bioanomalies_penalty", 0 )

            self.timer = BuildingService:CreateGuiTimer( self.owner, self.activateAfter )
        else

            BuildingService:SetGuiTimer( self.timer, self.duration )
        end

    elseif ( self.activateAfter < self.duration ) then

        if ( self.timer ~= nil ) then

            self:DestroyTimer()

            if ( #PlayerService:GetConnectedPlayers() > 1) then

                if ( PlayerService:IsPlayerVoteInProgress()) then
                    return		
                end

                local playerId = PlayerService:GetPlayerForEntity( self.owner )

                local playerName = PlayerService:GetPlayerName( playerId )

                local voteParams =
                {
                    localization = "gui/vote/spawner_activate_tools/activate_all_bioanomalies",

                    timeout = 30.0,

                    gui_id = "gui/popup/popup_vote_planetaryscanner",

                    default_action = "button_no",

                    start_action = "button_yes",

                    win_label = "gui/vote/spawner_activate_tools/activating",

                    player = playerName,

                    actions = 
                    {
                        button_yes = 
                        { 
                            localization = "gui/hud/vote_accepted" ,
                            event_name	 = "LuaGlobalEvent",
                            event_params = { argName1 = event_sink, argName2 = "activate_all_bioanomalies_event" }
                        },

                        button_no =
                        {
                            localization = "gui/hud/vote_negative" ,
                            event_name = "",
                            event_params = {}
                        }
                    }
                }

                GameStreamingService:StartPlayerVote( playerId, voteParams, false )

            else

                QueueEvent( "LuaGlobalEvent", event_sink, "activate_all_bioanomalies_event", {} )
            end
        end
    end

    self.duration = self.duration + 1.0 / 30.0
end

function activate_all_bioanomalies:DestroyTimer()

    if ( self.timer ~= nil ) then

        EntityService:RemoveEntity( self.timer )
        self.timer = nil

        if ( self.penaltySpeedOwner ~= nil ) then

            QueueEvent( "RemoveMaxSpeedModifierRequest", self.penaltySpeedOwner, "activate_all_bioanomalies_penalty" )
        end
    end
end

function activate_all_bioanomalies:OnDeactivate()

    self:DestroyTimer()

    self.duration = 0.0

    return true
end

function activate_all_bioanomalies:OnUnequipped()

    self:DestroyTimer()

    if ( item.OnUnequipped ) then
        item.OnUnequipped( self )
    end
end

return activate_all_bioanomalies