local building = require("lua/buildings/building.lua")

class 'laboratory' ( building )

function laboratory:__init()
	building.__init(self,self)
end

function laboratory:OnInit()	
    self.laboratoryVersion = 1
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function laboratory:OnBuildingStart()
    local enabled= PlayerService:IsResearchEnabled()
    if ( enabled == false ) then
        QueueEvent("ForceLootContainerTypeRequest", event_sink, "research")
    end
end

function laboratory:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenResearchRequest", player )
end

function laboratory:OnLoad()
    building.OnLoad(self)
    if ( self.laboratoryVersion == nil or self.laboratoryVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.laboratoryVersion = 1
	end
end

return laboratory
