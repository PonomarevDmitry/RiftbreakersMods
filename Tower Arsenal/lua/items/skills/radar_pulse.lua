local item = require("lua/items/item.lua")

require("lua/utils/reflection.lua")

class 'radar_pulse' ( item )

function radar_pulse:__init()
	item.__init(self,self)
end

function radar_pulse:OnInit()
end

function radar_pulse:OnEquipped()
end

function radar_pulse:OnActivate()
    local radarPulseEffect = EntityService:SpawnEntity( "items/consumables/radar_pulse", self.entity, "")

	local radarRevealer = EntityService:GetComponent(radarPulseEffect, "FogOfWarRevealerComponent" )
	if ( radarRevealer == nil ) then
		Assert( false, "ERROR: No fog of war revealer component:" )
	end
	
	local helper = reflection_helper( radarRevealer ) 
	
	helper.radius = self.data:GetFloatOrDefault( "radius", 100 ) 
	local lifeTime = self.data:GetFloatOrDefault("life_time", 10 )
	EntityService:CreateOrSetLifetime( radarPulseEffect, lifeTime, "normal" )
end

return radar_pulse
