local item = require("lua/items/item.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'shielding' ( item )

function shielding:__init()
	item.__init(self,self)
end

function shielding:OnInit()
    self.damage_type = self.data:GetString("damage_type")
    self.resistance_factor = self.data:GetFloatOrDefault("resistance_factor", 0)
    self:OnShieldingAcquired()

	self.itemVersion = 1
end

function shielding:SetResistance( entity, factor )
	EnvironmentService:SetResistance( entity, self.damage_type, factor, "shielding_item_" .. self.damage_type)
end

function shielding:OnShieldingAcquired()
	local entities = FindService:FindEntitiesByType( "building" )
	for entity in Iter( entities ) do
		self:SetResistance(entity, 0.0)
	end
	
	entities = FindService:FindEntitiesByType( "player" )
	for entity in Iter( entities ) do
		self:SetResistance(entity, self.resistance_factor )
	end
	
	self:RegisterHandler( event_sink , "StartBuildingEvent", "OnStartBuildingEvent")
	self:RegisterHandler( event_sink , "PlayerControlledEntityChangeEvent", "OnPlayerControlledEntityChangeEvent")
	self:RegisterHandler( event_sink , "ShieldEntityCreatedEvent", "OnShieldEntityCreatedEvent")
end

function shielding:OnStartBuildingEvent(evt)
	self:SetResistance(evt:GetEntity(), 0.0)
end

function shielding:OnShieldEntityCreatedEvent(evt)
	self:SetResistance(evt:GetEntity(), self.resistance_factor )
end

function shielding:OnPlayerControlledEntityChangeEvent(evt)
	if ( EntityService:IsAlive( evt:GetControlledEntity() ) ) then
		self:SetResistance(evt:GetControlledEntity(), self.resistance_factor)
	end
end

--Deprecated
function shielding:OnBuildingStartEvent( evt )
end
--EndDeprecated

function shielding:OnLoad()

	if ( self.itemVersion == nil or self.itemVersion < 1 ) then
		self:UnregisterHandler( event_sink , "BuildingStartEvent", "OnBuildingStartEvent");
		self.itemVersion = 1
	end
end
return shielding
