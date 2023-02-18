class 'cave_entrance' ( LuaEntityObject )

function cave_entrance:__init()
	LuaEntityObject.__init(self,self)
end

function cave_entrance:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
end


function cave_entrance:OnInteractWithEntityRequest( evt )
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsEntranceActivated", {} )
end


return cave_entrance