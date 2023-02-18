local tower = require("lua/buildings/defense/tower.lua")

class 'tower_shockwave' ( tower )

function tower_shockwave:__init()
	tower.__init(self,self)
end

function tower_shockwave:OnTurretEvent( evt )

end

return tower_shockwave
