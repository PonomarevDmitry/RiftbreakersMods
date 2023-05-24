local rift_skill_base = require("lua/items/skills/rift_skill_base.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_portal_temporary' ( rift_skill_base )

function rift_portal_temporary:__init()
    rift_skill_base.__init(self,self)
end

function rift_portal_temporary:OnActivate()

    self:SpawnPortal( "misc/rift" )
end

return rift_portal_temporary