local item = require("lua/items/item.lua")

class 'invisible' ( item )

function invisible:__init()
	item.__init(self,self)
end

function invisible:OnInit()
	self.mode = false
end

function invisible:OnEquipped()
end

function invisible:OperateInvisibile()
	--LogService:Log( tostring( self.mode ) .. " operating invisibility" )
	ItemService:SetInvisible( self.owner, self.mode )
	
	if ( self.mode == true ) then
		self:RegisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
	else
		self:UnregisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
	end
end

function invisible:OnActivate()
	self.mode = true
	self:OperateInvisibile()
end

function invisible:OnDeactivate()
	if ( self.mode == false ) then
		return
	end
	self.mode = false
	self:OperateInvisibile()
	return true
end

function invisible:OnDamageEvent( evt )
	local damageValue = evt:GetDamageValue()
	if ( damageValue > 0 ) then
		self:_Deactivate( false )
		ItemService:ActivateCooldown(self.entity )
	end
end

function invisible:OnUnequipped()
	if ( self.mode == true ) then
		self:_Deactivate( false )
		ItemService:ActivateCooldown(self.entity )
	end
end

return invisible
