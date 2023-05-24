local rift_skill_base = require("lua/items/skills/rift_skill_base.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_jump_to_hq' ( rift_skill_base )

function rift_jump_to_hq:__init()
    rift_skill_base.__init(self,self)
end

function rift_jump_to_hq:OnActivate()

    local findResult = FindService:FindEntityByName( "headquarters" )
    if ( findResult ~= nil and findResult ~= INVALID_ID ) then

        local jumpResult = self:JumpToHQ(findResult)

        if ( jumpResult ) then
            return
        end
    end

    findResult = FindService:FindEntityByName( "outpost" )
    if ( findResult ~= nil and findResult ~= INVALID_ID ) then

        local jumpResult = self:JumpToHQ(findResult)

        if ( jumpResult ) then
            return
        end
    end
end

function rift_jump_to_hq:JumpToHQ(entity)

    local childrenList = EntityService:GetChildren( entity, false )

    for childEntity in Iter( childrenList ) do

        local blueprintName = EntityService:GetBlueprintName( childEntity )

        if ( blueprintName ~= "buildings/main/headquarters/portal" ) then
            goto continue
        end

        local riftPointComponent = EntityService:GetComponent( childEntity, "RiftPointComponent" )
        if ( riftPointComponent = nil ) then
            goto continue
        end

        local riftPointComponentRef = reflection_helper( riftPointComponent )

        if ( riftPointComponentRef.active == false ) then
            goto continue
        end

        self:JumpToEntity(childEntity)

        do
            return true
        end

        ::continue::
    end

    return false
end

return rift_jump_to_hq