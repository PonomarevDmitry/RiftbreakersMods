require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_mine_layer' ( drone_spawner_building )

function tower_mine_layer:__init()
	drone_spawner_building.__init(self,self)
end

function tower_mine_layer:OnInit()
	drone_spawner_building.OnInit(self);

	self.lifting_drones = 0
end

function tower_mine_layer:OnDroneLiftingStarted()
	self.lifting_drones = self.lifting_drones + 1
	self.data:SetInt("lifting_drones", self.lifting_drones)
end

function tower_mine_layer:OnDroneLiftingEnded()
	self.lifting_drones = self.lifting_drones - 1
	self.data:SetInt("lifting_drones", self.lifting_drones)
end

return tower_mine_layer
