class 'enemies_change_all_groups_states' ( LuaGraphNode )

function enemies_change_all_groups_states:__init()
    LuaGraphNode.__init(self, self)
end

function enemies_change_all_groups_states:init()

	self.stringToAllGroupsStatess =
	{
		["all_normal"] 			= AUSAG_ALL_NORMAL,
		["all_aggressive"] 		= AUSAG_ALL_AGGRESSIVE,
		["all_not_aggressive"] 	= AUSAG_ALL_NOT_AGGRESSIVE,
	}

	self.allGroupsStates = self.stringToAllGroupsStatess[ self.data:GetString( "all_groups_states" ) ];

end

function enemies_change_all_groups_states:Activated()
	UnitService:ChangeAllUnitsStatesAsGroup( self.allGroupsStates )
	self:SetFinished()

end


return enemies_change_all_groups_states