class 'trigger_highlight_building' ( LuaEntityObject )
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

function trigger_highlight_building:__init()
	LuaEntityObject.__init(self, self)
end

function trigger_highlight_building:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )

	local highlightsVec = self.data:GetString("highlights")
	self.highlights = Split(highlightsVec, ",")

	self.remove_from_highlight = false
	self.players = {}
	
	self:InitializeStateMachine()
end

function trigger_highlight_building:OnLoad()
	self:InitializeStateMachine()

	self.players = self.players or {}
end

function trigger_highlight_building:InitializeStateMachine()
	if self.fsm then
		return
	end

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("updater", { execute = "OnEnsureHighlight", interval = 0.5 })
	self.fsm:ChangeState("updater")
end

function trigger_highlight_building:AddHiglight( player )
	for name in Iter(self.highlights) do
		if ( not GuiService:HasPlayerHighlight( player, name ) ) then
			GuiService:AddToPlayerHighlight( player,  name )
		end
	end
	if ( IndexOf( self.players, player ) == nil ) then
		Insert( self.players, player )
	end
end

function trigger_highlight_building:RemoveHighlight( player )
	for name in Iter(self.highlights) do
		GuiService:RemoveFromPlayerHighlight(player, name )
	end
	Remove( self.players, player )
end


function trigger_highlight_building:OnEnsureHighlight()
	if not GuiService.HasHighlight then
		return
	end

	if self.remove_from_highlight then
		for name in Iter(self.highlights) do
			for player in Iter(self.players ) do
				self:AddHiglight( player )
			end
		end
	end
end

function trigger_highlight_building:OnEnteredTriggerEvent( evt )
	local player = PlayerService:GetPlayerForEntity( evt:GetOtherEntity() )
	if player == INVALID_PLAYER_ID then
		return
	end

	self.remove_from_highlight = true
	self:AddHiglight( player )
end

function trigger_highlight_building:OnLeftTriggerEvent( evt )
	self.remove_from_highlight = false
	
	local player = PlayerService:GetPlayerForEntity( evt:GetOtherEntity() )
		if player == INVALID_PLAYER_ID then
		return
	end

	self:RemoveHighlight( player )
end

function trigger_highlight_building:OnRelease( )
	if not self.remove_from_highlight then
		return
	end
	
	for player in Iter(self.players ) do
		for name in Iter(self.highlights) do
			GuiService:RemoveFromPlayerHighlight(player, name )
		end
	end
	self.players = {}
end

return trigger_highlight_building