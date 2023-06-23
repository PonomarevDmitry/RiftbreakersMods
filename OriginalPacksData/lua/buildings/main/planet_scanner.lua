local building = require("lua/buildings/building.lua")

class 'planet_scanner' ( building )

function planet_scanner:__init()
	building.__init(self,self)
end

function planet_scanner:OnInit()	
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function planet_scanner:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenPlanetaryScannerRequest", player )
end

return planet_scanner
