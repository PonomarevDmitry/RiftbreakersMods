local item = require("lua/items/item.lua")

class 'timed_invisible' ( item )

function timed_invisible:__init()
	item.__init(self,self)
end

function timed_invisible:OnInit()
	self.duration = self.data:GetFloatOrDefault("time", 10 )
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "invisible", { from="*", enter="OnInvisibleEnter", exit="OnInvisibleExit"} )
	
end

function timed_invisible:OnActivate()
	self.machine:ChangeState("invisible")
end

function timed_invisible:OnInvisibleEnter( state )
	state:SetDurationLimit( self.duration )
	ItemService:SetInvisible( self.owner, true )
	self:RegisterHandler( self.owner, "ActivateItemEvent", "OnActivateItemEvent" )
	self:RegisterHandler( self.owner, "DeactivateItemEvent", "OnDeactivateItemEvent" )
	self:RegisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
end

function timed_invisible:OnInvisibleExit()
	ItemService:SetInvisible( self.owner, false )		
	self:UnregisterHandler( self.owner, "ActivateItemEvent", "OnActivateItemEvent" )
	self:UnregisterHandler( self.owner, "DeactivateItemEvent", "OnDeactivateItemEvent" )
	self:UnregisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
end

function timed_invisible:OnActivateItemEvent( evt )
	local item = evt:GetItem()

	local itemType = ItemService:GetItemType( item )
	if ( item ~= self.entity and itemType ~= "equipment" ) then
		self.machine:Deactivate()
	end
end
function timed_invisible:OnDeactivateItemEvent( evt )
	local item = evt:GetItem()

	local itemType = ItemService:GetItemType( item )
	if ( item ~= self.entity and itemType ~= "equipment" ) then
		self.machine:Deactivate()
	end
end

function timed_invisible:OnDamageEvent( evt )
	local damageValue = evt:GetDamageValue()
	if ( damageValue > 0 ) then
		self.machine:Deactivate();
	end
end

function timed_invisible:OnUnequipped()
	self.machine:Deactivate();
end


return timed_invisible
