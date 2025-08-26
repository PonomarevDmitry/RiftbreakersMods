local weapon = require("lua/items/weapon.lua")

class 'autofire_weapon' ( weapon )

function autofire_weapon:__init()
	item.__init(self,self)
end

function autofire_weapon:OnInit()
	if self.data:HasString( "aim_bp" ) then
        self.aimBp = self.data:GetString( "aim_bp" )
        self.aimMaxDistance = self.data:GetFloatOrDefault( "aim_max_distance", 0.0 )
        self.aimEnt = INVALID_ID
        self.sm = self:CreateStateMachine()
        self.sm:AddState( "aiming_marker_execute", { execute="OnAimingMarkerExecute" } )
    end
end

function autofire_weapon:OnLoad()
    weapon.OnLoad( self )

    if self.aimBp ~= nil then
    	if self.aimEnt ~= INVALID_ID then
       		if ( not self:ValidateEntityReference( self.aimEnt ) ) then
	            self.aimEnt = INVALID_ID
	        end
	    end
    end
end

function autofire_weapon:OnEquipped()
	weapon.OnEquipped( self )

	if self.sm ~= nil then
        self.sm:ChangeState("aiming_marker_execute")
    end
end

function autofire_weapon:OnActivate( activation_id )
    WeaponService:StartShoot( self.item, activation_id );
	local db = EntityService:GetDatabase( self.item )
	if is_server and db ~= nil then
		db:SetFloat("is_shooting", 1.0 * self.data:GetFloatOrDefault("animation_speed", 1.0 ))
	end
end

function autofire_weapon:OnDeactivate()
    WeaponService:StopShoot( self.item );
	local db = EntityService:GetDatabase( self.item )
	if is_server and db ~= nil then
		db:SetFloat("is_shooting", 0.0  )
	end
	return true
end

function autofire_weapon:OnUnequipped()
	weapon.OnUnequipped( self )

    if self.sm ~= nil then
        self.sm:Deactivate()
    end
end

function autofire_weapon:OnShootingStop()
	weapon.OnShootingStop( self )

	if is_server then 
		EffectService:AttachEffects( self.item, "shooting_end" )
	end
end

function autofire_weapon:OnAimingMarkerExecute( state )
    if ( self.aimEnt == INVALID_ID or EntityService:IsAlive( self.aimEnt ) == false ) then 
        self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=0, y=0, z=0 })
        EntityService:CreateComponent(self.aimEnt, "NetReplicationDisabledComponent")
    end

    WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, self.aimMaxDistance )
    EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end


return autofire_weapon
