local portal_builder_tool = require("lua/misc/portal_builder_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'portal_builder_tool2' ( portal_builder_tool )

function portal_builder_tool2:__init()
    portal_builder_tool.__init(self,self)
end

function portal_builder_tool2:OnPreInit()

    self.configNameDirection = "$portal_builder_tool2_direction"
    self.configNameSize = "$portal_builder_tool2_size"
end

function portal_builder_tool2:GetDirectionConfigArray()

    if ( self.configDirectionArray == nil ) then

        local vectorX = { ["x"] = 44, ["z"] = 0 }
        local vector_X = { ["x"] = -44, ["z"] = 0 }

        local vectorXZ = { ["x"] = 22, ["z"] = 36 }
        local vector_XZ = { ["x"] = -22, ["z"] = 36 }
        local vectorX_Z = { ["x"] = 22, ["z"] = -36 }
        local vector_X_Z = { ["x"] = -22, ["z"] = -36 }

        self.configDirectionArray = {

            { vectorX },
            { vectorX, vectorXZ },

            { vectorXZ },
            { vectorXZ, vector_XZ },

            { vector_XZ },
            { vector_XZ, vector_X },

            { vector_X },
            { vector_X, vector_X_Z },

            { vector_X_Z },
            { vector_X_Z, vectorX_Z },

            { vectorX_Z },
            { vectorX_Z, vectorX },

            { vectorX, vectorXZ, vector_XZ, vector_X, vector_X_Z, vectorX_Z },
        }
    end

    return self.configDirectionArray
end

return portal_builder_tool2