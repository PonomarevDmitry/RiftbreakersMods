class 'ears_attach_to_camera' ( LuaGraphNode )

function ears_attach_to_camera:__init()
	LuaGraphNode.__init(self, self)
end

function ears_attach_to_camera:init()
	self.coords = {}
	self.coords.x = 0
	self.coords.y = 0
	self.coords.z = 0
end

function ears_attach_to_camera:Activated()
	SoundService:AttachEars(-1.0,self.coords)

	self:SetFinished()
end

return ears_attach_to_camera