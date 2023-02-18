require("lua/utils/string_utils.lua")

class 'logic_wait_on_destroy' ( LuaGraphNode )

function logic_wait_on_destroy:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_destroy:init()
	self.bp = self.data:GetString("blueprint")
end

function logic_wait_on_destroy:Activated()
	self:RegisterHandler( event_sink, "DestroyRequest", "OnDestroyRequest" )
	self:RegisterHandler( event_sink, "EntityKilledEvent", "OnEntityKilledEvent" )
end

function logic_wait_on_destroy:Deactivated()
    self:UnregisterHandlers()
end

function logic_wait_on_destroy:OnEntityKilledEvent( event )
    if ( event:GetBlueprint() == self.bp ) then
        self:SetFinished()
    end
end

function logic_wait_on_destroy:OnDestroyRequest( event )
    local entity = event:GetEntity();
    if ( EntityService:IsAlive(entity) and EntityService:GetBlueprintName( entity ) == self.bp ) then
        self:SetFinished()
    end
end

return logic_wait_on_destroy