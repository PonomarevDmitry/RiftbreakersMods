class 'generator_overcharge' ( LuaEntityObject )
require("lua/utils/reflection.lua")

function generator_overcharge:__init()
	LuaEntityObject.__init(self,self)
end

function generator_overcharge:init()
    local mechEntities = FindService:FindEntitiesByTypeInRadius( self.entity, "player", 2.0)
    local healthInPercent = self.data:GetFloatOrDefault( "heal_amount", 100 )

    for mech in Iter(mechEntities ) do
        local healthLink = EntityService:GetComponent( mech, "HealthLinkComponent" )
        if ( healthLink ) then
            local helper = reflection_helper( healthLink) 
            local container = rawget(helper.links, "__ptr");
            local count = container:GetItemCount()
            for i=0,count - 1,1 do
                local item = reflection_helper( container:GetItem( i ) )
                HealthService:AddHealthInPercentage( item.second.id, healthInPercent )
            end
        end
    end
end


return generator_overcharge
