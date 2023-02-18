local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'geotrupex_wreck' ( wreck_ground_unit )

function geotrupex_wreck:__init()
	wreck_ground_unit.__init(self,self)
end

function geotrupex_wreck:initParams()
	--self.wreckLifetime = 600
end

return geotrupex_wreck