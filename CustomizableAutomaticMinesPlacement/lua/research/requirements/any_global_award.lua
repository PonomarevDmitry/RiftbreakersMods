require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'any_global_award' ( LuaGraphNode )

function any_global_award:__init()
    LuaGraphNode.__init(self,self)
end

function any_global_award:init()
    self.item_blueprint = self.data:GetString( "item_blueprint" )
end

function any_global_award:IsReadyForResearch()

    local blueprintsArray = Split( self.item_blueprint, "," )

    for itemBlueprint in Iter( blueprintsArray ) do

        if ( PlayerService:HasGlobalAward( itemBlueprint ) ) then
            return true
        end
    end

    return false
end

function any_global_award:OnResearchAcquired()
end

return any_global_award