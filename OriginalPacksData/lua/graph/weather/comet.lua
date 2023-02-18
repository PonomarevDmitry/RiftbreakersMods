class 'comet' ( LuaGraphNode )

function comet:__init()
	LuaGraphNode.__init(self,self)
end

function comet:init()
end

function comet:Activated()
	local blueprint = self.data:GetString( "blueprint" )
	local ent = EntityService:CreateEntity(blueprint)
	EntityService:CombineDatabase( ent, self.data )
	self:SetFinished()
end

return comet