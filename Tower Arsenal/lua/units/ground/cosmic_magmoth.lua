require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'cosmic_magmoth' ( base_unit )

function cosmic_magmoth:__init()
    base_unit.__init(self, self)
end

function cosmic_magmoth:OnInit()
    self:RegisterHandler( self.entity, "EnterTeleportEvent",  "OnEnterTeleportEvent" )
    self:RegisterHandler( self.entity, "ExitTeleportEvent",  "OnExitTeleportEvent" )
    self.fuseBp = self.data:GetStringOrDefault("fuse_bp", "effects/enemies_generic/teleport_trail_fire")
    
    self.wreck_type =  "wreck_big"
    self.wreckMinSpeed = 4

    self.isTeleporting = false

    -- New armor logic integrated
    self.armour = EntityService:SpawnAndAttachEntity("units/ground/cosmic_magmoth_armour", self.entity, "att_armor", "")
    
    WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function cosmic_magmoth:OnLoad()
    base_unit.OnLoad(self)
    self.fuseBp = self.data:GetStringOrDefault("fuse_bp", "effects/enemies_generic/teleport_trail_fire")
end

function cosmic_magmoth:OnAnimationMarkerReached( evt )
    local markerName = evt:GetMarkerName() 
    if ( markerName == "attack_range_1"  ) then
        local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
        WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_1" )
    elseif( markerName == "attack_range_2" ) then
        local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
        WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_2" )
    elseif( markerName == "fuse_start" ) then
        UnitService:SpawnFuse( self.entity, self.fuseBp, 0.65, "teleport" )
    end

    return true
end

function cosmic_magmoth:OnEnterTeleportEvent( evt )
    if ( self.isTeleporting == false ) then
        self.isTeleporting = true
        EffectService:AttachEffects( self.entity, "teleport" )
    end
end

function cosmic_magmoth:OnExitTeleportEvent( evt )
    if ( self.isTeleporting == true ) then
        self.isTeleporting = false
        EffectService:AttachEffects( self.entity, "teleport" )
    end
end

function cosmic_magmoth:OnDamageEvent(evt)
    if ( base_unit.OnDamageEvent ) then
        base_unit.OnDamageEvent( self, evt )
    end
    
    if self.armour ~= nil then
        if HealthService:GetHealthInPercentage( self.entity ) < 0.5 then
            EntityService:RequestDestroyPattern( self.armour, "default" )
            self.armour = nil
        end
    end
end

return cosmic_magmoth