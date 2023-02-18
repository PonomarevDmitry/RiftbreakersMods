local item = require("lua/items/item.lua")

class 'shield' ( item )

function shield:__init()
	item.__init(self)
end

function shield:OnInit()
   	self.fadeSM = self:CreateStateMachine()
	self.fadeSM:AddState( "fade", { from="*", enter="OnFadeEnter", execute="OnFadeExecute" } )

	self.damageSM = self:CreateStateMachine()
	self.damageSM:AddState( "damage_effect", { from="*", execute="OnDamageEffectExecute" } )

	self.damage_effect =
	{
		blink_speed = self.data:GetFloat("blink_speed"),
		glow_factor = self.data:GetFloat("glow_factor"),
		delta_scale	= self.data:GetFloat("delta_scale")
	}
end

function shield:OnFadeEnter( state )
	state:SetDurationLimit( 0.3 )
end

function shield:OnFadeExecute( state )
	if state:GetDuration() > 0.1 then
		EntityService:SetGraphicsUniform( self.shield, "cAlpha",  ( ( state:GetDuration() - 0.1 ) / 0.2 ) )
	end
end

function shield:OnEquipped()
end

function shield:OnActivate()
	if ( self.slot == "LEFT_HAND" ) then
		self.shield = EntityService:SpawnAndAttachEntity( "shield/shield_active", self.item, "att_left_hand", "player" )
	elseif ( self.slot == "RIGHT_HAND" ) then
		self.shield = EntityService:SpawnAndAttachEntity( "shield/shield_active", self.item, "att_right_hand", "player" )
	end

	self.fadeSM:ChangeState( "fade" )

	local data = EntityService:GetDatabase( self.owner );
	data:SetFloat( self.slot .. "_use_speed", 1 );

	self:RegisterHandler( self.shield, "DamageEvent", "OnDamageEvent" );
end

function shield:OnDeactivate()
	self:UnregisterHandler( self.shield, "DamageEvent", "OnDamageEvent" );

	if EntityService:IsAlive(self.shield) == true  then
		EntityService:RemoveEntity(self.shield);
	end

	if self.damageSM:GetCurrentState() ~= "" then
		local state = self.damageSM:GetState("damage_effect")
		state:Exit();
	end

	local ownerData = EntityService:GetDatabase( self.owner )
	if ownerData ~= nil then
		ownerData:SetFloat( self.slot .. "_use_speed", 0 );
	end
	--LogService:Log( "shield off" )
	return true
end

function shield:OnDamageEvent( evt )
	local state = self.damageSM:ChangeState("damage_effect")
	state:SetDurationLimit( 1.0 );
end

local function clamp( value, min, max )
	if value < min then return min end
	if value > max then return max end

	return value
end

function shield:OnDamageEffectExecute( state, dt )
	local duration = clamp( state:GetDurationLimit() - dt * self.damage_effect.blink_speed, 0.0, 1.0 );
	state:SetDurationLimit( duration );

	LogService:Log(tostring(duration))

	local glowFactor = 1.0 + self.damage_effect.glow_factor * duration;
	EntityService:SetGraphicsUniform( self.shield, "cGlowFactor", glowFactor );

	local scale = 1.0 - self.damage_effect.delta_scale + self.damage_effect.delta_scale * math.cos( duration * duration * math.pi / 2.0 );
	EntityService:SetScale( self.shield, scale, scale, scale );
end


return shield
