local weapon = require("lua/items/weapon.lua")

class 'charge_weapon' ( weapon )

function charge_weapon:__init()
	weapon.__init(self,self)
end

function charge_weapon:OnInit()
    if self.data:HasString( "aim_bp" ) then
        self.aimBp = self.data:GetString( "aim_bp" )
        self.aimMaxDistance = self.data:GetFloatOrDefault( "aim_max_distance", 0.0 )
        self.aimEnt = INVALID_ID
        self.msm = self:CreateStateMachine()
        self.msm:AddState( "aiming_marker_execute", { execute="OnAimingMarkerExecute" } )
    end
    
    if is_server and self.data:HasString( "ammo_bp" ) and self.data:HasString( "ammo_att" ) then
        self.asm = self:CreateStateMachine()
        self.asm:AddState( "ammo_execute", { enter="OnAmmoEnter", execute="OnAmmoExecute", exit="OnAmmoExit" } )
    end
end

function charge_weapon:OnLoad()
    weapon.OnLoad( self )

    if ( is_client and not self.event_registered and self:IsEquipped() ) then
        self:RegisterEventsListeners( true )
    end
    
    if self.aimBp ~= nil then
        if self.aimEnt ~= INVALID_ID then
            if ( not self:ValidateEntityReference( self.aimEnt ) ) then
                self.aimEnt = INVALID_ID
            end
        end
    end
end

function charge_weapon:OnEquipped()
	weapon.OnEquipped( self )

    if is_client then
        self:RegisterEventsListeners( true )
    end

    if self.msm ~= nil then
        self.msm:ChangeState("aiming_marker_execute")
    end

    if self.asm ~= nil then
        self.asm:ChangeState("ammo_execute")
    end
end

function charge_weapon:RegisterEventsListeners(register)
    self.event_registered = register

    if register then
        self:RegisterHandler( self.item, "ShootingWeaponChargeAcquiredEvent", "_ShootingChargeLevelAcquired" )
        self:RegisterHandler( self.item, "ShootingWeaponChargeReleasedEvent", "_ShootingChargeReleased" )
    else
        self:UnregisterHandler( self.item, "ShootingWeaponChargeAcquiredEvent", "_ShootingChargeLevelAcquired" )
        self:UnregisterHandler( self.item, "ShootingWeaponChargeReleasedEvent", "_ShootingChargeReleased" )
    end
end

function charge_weapon:OnUnequipped()
	weapon.OnUnequipped( self )

    if is_client then
        self:RegisterEventsListeners( false )
    end

    if self.msm ~= nil then
        self.msm:Deactivate()
    end

    if self.asm ~= nil then
        self.asm:Deactivate()
    end
end

function charge_weapon:_ShootingChargeLevelAcquired( evt )
    if is_client then
	   self:SetPadTriggerParams("charge_acquired", 0.2)
    end 
end

function charge_weapon:_ShootingChargeReleased( evt )
    if is_client then
	   self:SetPadTriggerParams("charge_released", 0.2)
    end
end

function charge_weapon:OnActivate( activation_id )
    WeaponService:StartCharge( self.item, activation_id );
end

function charge_weapon:OnDeactivate()
    WeaponService:StopCharge( self.item );
	return true
end

function charge_weapon:OnShootingStart()
    weapon.OnShootingStart( self )
end

function charge_weapon:OnShootingStop()
    weapon.OnShootingStop( self )

    if is_server then
        EffectService:AttachEffects( self.item, "shooting_end" )
    end
end

function charge_weapon:OnAimingMarkerExecute( state )
    if ( self.aimEnt == INVALID_ID or EntityService:IsAlive( self.aimEnt ) == false ) then 
        self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=0, y=0, z=0 })
        EntityService:CreateComponent(self.aimEnt, "NetReplicationDisabledComponent")
    end

    WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, self.aimMaxDistance )
    EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end

function charge_weapon:OnAmmoEnter( state )
    local ammoBp = self.data:GetString( "ammo_bp" )
    local ammoAtt = self.data:GetString( "ammo_att" )
    self.pendingBomb = EntityService:SpawnAndAttachEntity( ammoBp, self.item, ammoAtt, "" )
    AnimationService:StartAnim( self.pendingBomb, "working", true )
    EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 )
    self.readyBomb = nil
end

function charge_weapon:OnAmmoExecute( state )
    local progress = WeaponService:GetWeaponReloadProgress( self.item );
    local currentTime = state:GetDuration()
    if self.readyBomb ~= nil then
        if progress < 1.0 then 
            EntityService:SetGraphicsUniform( self.readyBomb, "cDissolveAmount", 0 )
            EntityService:DissolveEntity( self.readyBomb, 0.5 )
            self.readyBomb = nil

            local ammoBp = self.data:GetString( "ammo_bp" )
            local ammoAtt = self.data:GetString( "ammo_att" )
            self.pendingBomb = EntityService:SpawnAndAttachEntity( ammoBp, self.item, ammoAtt, "" )
            AnimationService:StartAnim( self.pendingBomb, "working", true )
            EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 )
        else
            EntityService:SetPosition( self.readyBomb, 0, 0.25 * math.cos( 3.14 * currentTime ), 0 )
        end
    end

    if self.pendingBomb ~= nil then
        if progress > 0 and progress < 1.0 then 
            EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 1 - progress )
            EntityService:SetPosition( self.pendingBomb, 0, 0.25 * math.cos( 3.14 * currentTime ), 0 )
        elseif progress >= 1 then
            EntityService:SetGraphicsUniform( self.pendingBomb, "cDissolveAmount", 0 )
            self.readyBomb = self.pendingBomb;
            self.pendingBomb = nil
        end
    end
end

function charge_weapon:OnAmmoExit( state )
    if self.readyBomb ~= nil then
        EntityService:DissolveEntity( self.readyBomb, 0.2 )
        self.readyBomb = nil 
    end

    if self.pendingBomb ~= nil then
        EntityService:DissolveEntity( self.pendingBomb, 0.2 )
        self.pendingBomb = nil 
    end
end

return charge_weapon
