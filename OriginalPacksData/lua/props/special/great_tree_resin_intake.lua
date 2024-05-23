local building_base = require("lua/buildings/building_base.lua");
require("lua/utils/reflection.lua")

class 'great_tree_resin_intake' ( building_base )

function great_tree_resin_intake:__init()
	building_base.__init(self)
end

function great_tree_resin_intake:init()
	building_base.init(self)	
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	BuildingService:DisableBuilding( self.entity )
end

function great_tree_resin_intake:OnBuild()
end

function great_tree_resin_intake:OnDeactivate()	
end

function great_tree_resin_intake:OnActivate()	
end

function great_tree_resin_intake:OnLuaGlobalEvent( event )
	if "EnableResinIntakeEvent" == event:GetEvent() then
		BuildingService:EnableBuilding( self.entity )	
	end
end

return great_tree_resin_intake