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
    local player = PlayerService:GetPlayerForEntity( self.entity )
    PlayerService:UnlockLoot( player,"range_weapon")
    PlayerService:UnlockLoot( player,"melee_weapon")
    PlayerService:UnlockLoot( player,"skill")
    PlayerService:UnlockLoot( player,"movement_skill")
    PlayerService:UnlockLoot( player,"consumable")
    PlayerService:UnlockLoot( player,"upgrade")
    --local enabled = PlayerService:IsCraftingEnabled(player)
    --if ( enabled == false ) then
    --    QueueEvent("ForceLootContainerTypeRequest", event_sink, "crafting")
    --end
end

function armory:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenCraftingRequest", event:GetOwner(), player )
end

function armory:OnLoad()
    building.OnLoad(self)
    if ( self.armoryVersion == nil or self.armoryVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.armoryVersion = 1
	end
    
    local player = PlayerService:GetPlayerForEntity( self.entity )
    PlayerService:UnlockLoot( player,"range_weapon")
    PlayerService:UnlockLoot( player,"melee_weapon")
    PlayerService:UnlockLoot( player,"skill")
    PlayerService:UnlockLoot( player,"movement_skill")
    PlayerService:UnlockLoot( player,"consumable")
    PlayerService:UnlockLoot( player,"upgrade")
end
return armory
