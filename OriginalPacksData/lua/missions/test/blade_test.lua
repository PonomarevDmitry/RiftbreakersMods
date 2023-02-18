require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

class 'blade_test' ( LuaGraphNode )

function blade_test:__init()
    LuaGraphNode.__init(self,self)
end

function blade_test:init()
    LogService:Log( "blade_test:init()" )

    local rulesPath = "lua/missions/test/dom_blade_test.lua"

	--MissionService:AddGameRule( "lua/missions/dom_manager.lua", rulesPath )
end

return blade_test
