class 'earthquake' ( LuaEntityObject )

function earthquake:__init()
	LuaEntityObject.__init(self, self)
end

function earthquake:init()

end


function earthquake:OnRelease()
	if ( GuiService:HasMinimapMarker( tostring( self.entity ) ) ) then
		GuiService:RemoveMinimapMarker( tostring( self.entity ) )
	end
end

return earthquake