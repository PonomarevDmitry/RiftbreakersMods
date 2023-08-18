local rift_skill_base = require("lua/items/skills/rift_skill_base.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_jump_to_nearest_portal' ( rift_skill_base )

function rift_jump_to_nearest_portal:__init()
    rift_skill_base.__init(self,self)
end

function rift_jump_to_nearest_portal:OnActivate()

    local playable_min = MissionService:GetPlayableRegionMin()
    local playable_max = MissionService:GetPlayableRegionMax()

    local predicate = {

        signature = "RiftPointComponent",

        filter = function(entity)

            local riftPointComponent = EntityService:GetComponent(entity, "RiftPointComponent")

            if ( riftPointComponent == nil ) then
                return false
            end

            local riftPointComponentRef = reflection_helper( riftPointComponent )

            if ( riftPointComponentRef.active == false ) then
                return false;
            end

            if ( riftPointComponentRef.name == "rift" or riftPointComponentRef.name == "headquarters" ) then
                return true;
            end

            return false
        end
    };

    local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate )

    if ( #entities == 1 ) then

        self:JumpToEntity( entities[1] )

    elseif ( #entities > 1 ) then

        local nearestPortal = self:FindNearest( entities )

        self:JumpToEntity( nearestPortal )
    end
end

return rift_jump_to_nearest_portal