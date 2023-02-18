class 'acid_fissures' ( LuaEntityObject )

function acid_fissures:__init()
	LuaEntityObject.__init(self, self)
end

function acid_fissures:init()

end


function acid_fissures:OnRelease()
	GuiService:RemoveMinimapMarker( tostring( self.entity ) )
end

return acid_fissures