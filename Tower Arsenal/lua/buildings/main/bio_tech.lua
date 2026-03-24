local building = require("lua/buildings/building.lua")

class 'bio_tech' ( building )

function bio_tech:__init()
	building.__init(self,self)
end

function bio_tech:OnInit()	
    self.bio_techVersion = 1
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function bio_tech:OnBuildingStart()
    local player = PlayerService:GetPlayerForEntity( self.entity )
    local enabled= PlayerService:IsResearchEnabled(player)
    if ( enabled == false ) then
        QueueEvent("ForceLootContainerTypeRequest", event_sink, "research")
    end
end

function bio_tech:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenResearchRequest",event:GetOwner(), player )
end

function bio_tech:OnLoad()
    building.OnLoad(self)
    if ( self.bio_techVersion == nil or self.bio_techVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.bio_techVersion = 1
	end
end

return bio_tech
