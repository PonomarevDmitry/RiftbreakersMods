local weapon = require("lua/items/weapon.lua")

class 'singlefire_weapon' ( weapon )

function singlefire_weapon:__init()
	weapon.__init(self,self)
end

function singlefire_weapon:OnInit()
    if self.data:HasString( "aim_bp" ) then
        self.aimBp = self.data:GetString( "aim_bp" )
        self.aimMaxDistance = self.data:GetFloatOrDefault( "aim_max_distance", 0.0 )
        self.aimEnt = INVALID_ID
        self.sm = self:CreateStateMachine()
        self.sm:AddState( "aiming_marker_execute", { execute="OnAimingMarkerExecute" } )
    end
end

function singlefire_weapon:OnLoad()
    weapon.OnLoad( self )

    if self.aimBp ~= nil then
    	if self.aimEnt ~= INVALID_ID then
       		if ( not self:ValidateEntityReference( self.aimEnt ) ) then
	            self.aimEnt = INVALID_ID
	        end
	    end
    end
end

function singlefire_weapon:OnEquipped()
	weapon.OnEquipped( self )

	if self.sm ~= nil then
        self.sm:ChangeState("aiming_marker_execute")
    end
end

function singlefire_weapon:OnActivate( activation_id )
    WeaponService:ShootOnce( self.item, activation_id );
end

function singlefire_weapon:OnDeactivate()
	return true
end

function singlefire_weapon:OnUnequipped()
	weapon.OnUnequipped( self )

    if self.sm ~= nil then
        self.sm:Deactivate()
    end
end

function singlefire_weapon:OnAimingMarkerExecute( state )
    if ( self.aimEnt == INVALID_ID or EntityService:IsAlive( self.aimEnt ) == false ) then 
        self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=0, y=0, z=0 })
        EntityService:CreateComponent(self.aimEnt, "NetReplicationDisabledComponent")
    end

    WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, self.aimMaxDistance )
    EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end

return singlefire_weapon
