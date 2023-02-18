class 'earthquake' ( LuaEntityObject )

function earthquake:__init()
	LuaEntityObject.__init(self, self)
end

function earthquake:init()

end


function earthquake:OnRelease()
	GuiService:RemoveMinimapMarker( tostring( self.entity ) )
end

return earthquake