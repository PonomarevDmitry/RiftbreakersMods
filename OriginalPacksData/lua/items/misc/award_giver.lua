local item = require("lua/items/item.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'award_giver' ( item )

function award_giver:__init()
	item.__init(self,self)
end

function award_giver:OnInit()

end

function award_giver:OnDrop()


end

function award_giver:OnPickUp( owner )
	local awards = self.data:GetStringOrDefault("award", "")
	local awardList = Split( awards, "," )	
	local playerId = PlayerService:GetPlayerForEntity( owner )
	for award in Iter( awardList ) do
		PlayerService:AddGlobalAward( award, false, playerId )
	end

	local hiddenAwards = self.data:GetStringOrDefault("hidden_award", "")
	local hiddenAwardList = Split( hiddenAwards, "," )	
	for award in Iter( hiddenAwardList ) do
		PlayerService:AddGlobalAward( award, true, playerId )
	end

    Assert(#awardList ~= 0 or #hiddenAwardList ~= 0, "Error:  award in award giver empty!" )
	EntityService:RemoveEntity( self.entity )
end

function award_giver:IsPickable( owner )
	return true
end

return award_giver
