class 'anoryxian_boss_interactive' ( LuaEntityObject )

function anoryxian_boss_interactive:__init()
	LuaEntityObject.__init(self,self)
end

function anoryxian_boss_interactive:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
end


function anoryxian_boss_interactive:OnInteractWithEntityRequest( evt )
	QueueEvent( "LuaGlobalEvent", event_sink, "BossBreakHeal", {} )
end


return anoryxian_boss_interactive