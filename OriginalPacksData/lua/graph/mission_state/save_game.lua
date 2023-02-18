class 'save_game' ( LuaGraphNode )

function save_game:__init()
	LuaGraphNode.__init(self,self)
end

function save_game:init()
end

function save_game:Activated()
    MissionService:SaveGame()
    self:SetFinished()
end

return save_game