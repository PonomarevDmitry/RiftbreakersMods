local item = require("lua/items/item.lua")

require("lua/utils/reflection.lua")

class 'wall_pulse' ( item )

function wall_pulse:__init()
	item.__init(self,self)
end

function wall_pulse:OnInit()
end

function wall_pulse:OnEquipped()
end

function wall_pulse:OnActivate()

	local blueprintName = "items/consumables/wall_pulse"

	local team = EntityService:GetTeam(self.entity)

	local player = self.owner

	local playerPosition = EntityService:GetPosition( player )

	local culler = EntityService:SpawnEntity(blueprintName, playerPosition, team)

	EntityService:CreateLifeTime(culler, 0.05, "normal")
end

return wall_pulse