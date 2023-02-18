require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'arachnoid_sentinel_base' ( base_unit )

function arachnoid_sentinel_base:__init()
	base_unit.__init(self,self)
end

function arachnoid_sentinel_base:OnInit()
	self.item = nil
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	local itemsString = self.data:GetStringOrDefault( "items" , "" )
	if ( itemsString ~= "" ) then
		local items = Split( itemsString, "," )
		local v = RandInt( 1, #items)
		self.item = items[v];	
		
		if ( self.item ~= nil ) then
			self.stingItem = ItemService:AddItemToInventory( self.entity, self.item )
			ItemService:EquipItemInSlot( self.entity, self.stingItem, "STING" )
		end
	end
end

return arachnoid_sentinel_base
