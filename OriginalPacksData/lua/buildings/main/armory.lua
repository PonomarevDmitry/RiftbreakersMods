local building = require("lua/buildings/building.lua")

class 'armory' ( building )

function armory:__init()
	building.__init(self,self)
end

function armory:OnInit()	
	self.armoryVersion = 1
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function armory:OnBuildingStart()
    local enabled = PlayerService:IsCraftingEnabled()
    if ( enabled == false ) then
        QueueEvent("ForceLootContainerTypeRequest", event_sink, "crafting")
    end
end

function armory:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenCraftingRequest", player )
end

function armory:OnLoad()
    building.OnLoad(self)
    if ( self.armoryVersion == nil or self.armoryVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.armoryVersion = 1
	end
end
return armory
