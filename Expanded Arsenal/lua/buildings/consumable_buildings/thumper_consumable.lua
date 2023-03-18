local tower = require("lua/buildings/defense/tower.lua")

class 'thumper_consumable' ( tower )

function thumper_consumable:__init()
	tower.__init(self,self)
end

function thumper_consumable:OnInit()
	EntityService:SetScale( self.entity, 0.5,0.5,0.5 )
end

function thumper_consumable:OnTurretEvent( evt )

end

return thumper_consumable
