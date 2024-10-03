
class 'heavy_plasma_shield' ( LuaEntityObject )

function heavy_plasma_shield:__init()
    LuaEntityObject.__init(self,self)
end

function heavy_plasma_shield:init()
    self.fadeSM = self:CreateStateMachine()
    self.fadeSM:AddState( "fade", { from="*", enter="OnFadeEnter", execute="OnFadeExecute" } )

    self.damageSM = self:CreateStateMachine()
    self.damageSM:AddState( "damage_effect", { from="*", execute="OnDamageEffectExecute" } )

    self.damage_effect =
    {
        blink_speed = self.data:GetFloat("blink_speed"),
        glow_factor = self.data:GetFloat("glow_factor"),
        delta_scale = self.data:GetFloat("delta_scale")
    }

    self.damageTimer = 0.0
    self.damageSM:ChangeState("damage_effect")  

    self.fadeSM:ChangeState( "fade" )
    self:RegisterHandler( self.entity, "ShieldEvent", "OnShieldEvent" );
end

function heavy_plasma_shield:OnFadeEnter( state )
    state:SetDurationLimit( 0.3 )
end

function heavy_plasma_shield:OnFadeExecute( state )
    if state:GetDuration() > 0.1 then
        EntityService:SetGraphicsUniform( self.entity, "cAlpha",  ( ( state:GetDuration() - 0.1 ) / 0.2 ) )
    end
end

function heavy_plasma_shield:OnShieldEvent( evt )
    if self.damageTimer < 0.1 then
        self.damageTimer = 1.0
    end
end

local function clamp( value, min, max )
    if value < min then return min end
    if value > max then return max end
    return value
end

function heavy_plasma_shield:OnDamageEffectExecute( state, dt )
    local duration = clamp( self.damageTimer - dt * self.damage_effect.blink_speed, 0.0, 1.0 );
    self.damageTimer = duration;
    local glowFactor = 1.0 + self.damage_effect.glow_factor * duration;
    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", glowFactor );
    local scale = 1.0 - self.damage_effect.delta_scale + self.damage_effect.delta_scale * math.cos( duration * duration * math.pi / 2.0 );
    EntityService:SetScale( self.entity, scale, scale, scale );
end

return heavy_plasma_shield
