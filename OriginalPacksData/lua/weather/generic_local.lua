class 'generic_local' ( LuaEntityObject )

function generic_local:__init()
	LuaEntityObject.__init(self, self)
end

function generic_local:init()

end


function generic_local:OnRelease()
	GuiService:RemoveMinimapMarker( tostring( self.entity ) )
end

return generic_local