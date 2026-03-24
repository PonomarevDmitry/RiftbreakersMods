require("lua/utils/table_utils.lua")

class 'research_cryogenic' ( LuaGraphNode )

function research_cryogenic:__init()
    LuaGraphNode.__init(self,self)
end

function research_cryogenic:init()
	Assert( self.data:HasString("damage_type"), " ERROR: no damage type in shielding.lua script database!" )
	self.damage_type = self.data:GetStringOrDefault("damage_type","")

	self.resistance_factors =
	{
		["cryogenic"] = 0.0
	};

	self.version = 1
end

function research_cryogenic:IsReadyForResearch()
	return true
end

function research_cryogenic:SetResistance( entity, factor )
	EnvironmentService:SetResistance( entity, self.damage_type, factor, "cryogenic_item_" .. self.damage_type)
end

function research_cryogenic:OnResearchAcquired()
	local entities = FindService:FindEntitiesByType( "building" )
	for entity in Iter( entities ) do
		self:SetResistance(entity, 0.0)
	end
	
	entities = FindService:FindEntitiesByType( "player" )
	for entity in Iter( entities ) do
		self:SetResistance(entity, self.resistance_factors[self.damage_type] or 0.0)
	end
	
	--EnvironmentService:SetWeatherResistance( self.damage_type )
	
	self:RegisterHandler( event_sink , "StartBuildingEvent", "OnStartBuildingEvent")
	self:RegisterHandler( event_sink , "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent")
	self:RegisterHandler( event_sink , "ShieldEntityCreatedEvent", "OnShieldEntityCreatedEvent")
end

function research_cryogenic:OnStartBuildingEvent(evt)
	self:SetResistance(evt:GetEntity(), 0.0)
end

function research_cryogenic:OnShieldEntityCreatedEvent(evt)
	local factor = self.resistance_factors[self.damage_type] or 0.0;
	self:SetResistance(evt:GetEntity(), factor)
end

function research_cryogenic:OnPlayerControlledEntityChangeEvent(evt)
	if ( EntityService:IsAlive( evt:GetControlledEntity() ) ) then
		local factor = self.resistance_factors[self.damage_type] or 0.0;
		self:SetResistance(evt:GetControlledEntity(), factor)
	end
end

function research_cryogenic:Activated()
	if ( self.data:GetIntOrDefault("is_acquired", 0 ) == 1 ) then
		self:OnResearchAcquired()
	end
end

-- Deprecated start
function research_cryogenic:OnBuildingStartEvent( evt )
end
-- Deprecated end

function research_cryogenic:OnLoad( )
	
	if ( self.version == nil or self.version < 1 ) then
		self:UnregisterHandler( event_sink , "BuildingStartEvent", "OnBuildingStartEvent");
		self.version = 1
	end
end


return research_cryogenic