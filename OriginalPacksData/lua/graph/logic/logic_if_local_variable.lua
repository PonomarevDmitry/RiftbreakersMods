
local logic_if_global_variable = require("lua/graph/logic/logic_if_global_variable.lua")

class 'logic_if_local_variable' ( logic_if_global_variable )

function logic_if_local_variable:__init()
    logic_if_global_variable.__init(self, self)
end

function logic_if_local_variable:init()
    logic_if_global_variable.init(self)

    self.keyValue =  self.parent:CreateGraphUniqueString( self.keyValue)
    self.campaignDataSource = false
end


function logic_if_local_variable:OnLoad()
    self.campaignDataSource = false
end

return logic_if_local_variable