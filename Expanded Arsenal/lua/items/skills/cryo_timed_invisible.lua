local item = require("lua/items/item.lua")

class 'cryo_timed_invisible' ( item )

function cryo_timed_invisible:__init()
	item.__init(self,self)
end

function cryo_timed_invisible:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetStringOrDefault( "bp", "items/skills/cryo_shockwave_invisible_standard" )
	self.att = database:GetStringOrDefault( "att", "be_body_upper" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
end

function cryo_timed_invisible:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function cryo_timed_invisible:OnInit()
	self:FillInitialParams()
	self.duration = self.data:GetFloatOrDefault("invisible_time", 10 )
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "invisible", { from="*", enter="OnInvisibleEnter", exit="OnInvisibleExit"} )
	
end

function cryo_timed_invisible:OnActivate()
	self.machine:ChangeState("invisible")
	
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.1 );
end

function cryo_timed_invisible:OnInvisibleEnter( state )
	state:SetDurationLimit( self.duration )
	ItemService:SetInvisible( self.owner, true )
	self:RegisterHandler( self.owner, "ActivateItemEvent", "OnActivateItemEvent" )
	self:RegisterHandler( self.owner, "DeactivateItemEvent", "OnDeactivateItemEvent" )
	self:RegisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
end

function cryo_timed_invisible:OnInvisibleExit()
	ItemService:SetInvisible( self.owner, false )		
	self:UnregisterHandler( self.owner, "ActivateItemEvent", "OnActivateItemEvent" )
	self:UnregisterHandler( self.owner, "DeactivateItemEvent", "OnDeactivateItemEvent" )
	self:UnregisterHandler( self.owner, "DamageEvent", "OnDamageEvent" )
end

function cryo_timed_invisible:OnActivateItemEvent( evt )
	local item = evt:GetItem()

	local itemType = ItemService:GetItemType( item )
	if ( item ~= self.entity and itemType ~= "equipment" ) then
		self.machine:Deactivate()
	end
end
function cryo_timed_invisible:OnDeactivateItemEvent( evt )
	local item = evt:GetItem()

	local itemType = ItemService:GetItemType( item )
	if ( item ~= self.entity and itemType ~= "equipment" ) then
		self.machine:Deactivate()
	end
end

function cryo_timed_invisible:OnDamageEvent( evt )
	local damageValue = evt:GetDamageValue()
	if ( damageValue > 0 ) then
		self.machine:Deactivate();
	end
end

function cryo_timed_invisible:OnUnequipped()
	self.machine:Deactivate();
end

return cryo_timed_invisible
