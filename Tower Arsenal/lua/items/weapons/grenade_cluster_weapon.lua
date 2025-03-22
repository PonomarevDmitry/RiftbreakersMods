local weapon = require("lua/items/weapon.lua")

class 'grenade_cluster_weapon' ( weapon )

local CURRENT_VERSION = 1

function grenade_cluster_weapon:__init()
	item.__init(self,self)
end

function grenade_cluster_weapon:OnInit()
	self:Init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "execute", { enter="OnEnter",execute="OnExecute", exit="OnExit" } )
	self.sm:AddState( "dummy", {} )
	self.aimEnt = nil
	self.clusterCount = 8
	self.clusterRadius = 8
	self.clusterSpeed = 10
	self.clusterDamage = 10
end

function grenade_cluster_weapon:OnLoad()
	self.version = self.version or 0
    weapon.OnLoad(self)
	if ( self.aimEnt ~= nil and self.version < 1 ) then
		if ( EntityService:GetBlueprintName(self.aimEnt) ~= self.aimBp) then
    	       self.aimEnt = nil
		else
			table.insert( self.references, self.aimEnt )
			ItemService:SetItemReference( self.aimEnt, self.entity, self.entity_blueprint )
		end
	end
	self.version = CURRENT_VERSION
    self:Init()

	if ( not self:ValidateEntityReference( self.aimEnt ) ) then
		self.aimEnt = nil
	end
end

function grenade_cluster_weapon:Init()
    self.bp = self.data:GetString( "bp" )
    self.aimBp = self.data:GetString( "aim_bp" )
    self.maxDistance = self.data:GetFloatOrDefault( "max_distance", 0.0 )
	self.version = CURRENT_VERSION
end

function grenade_cluster_weapon:OnEnter( state )

end

function grenade_cluster_weapon:OnExecute( state )
	if ( self.aimEnt == nil or EntityService:IsAlive( self.aimEnt ) == false ) then 
		self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=5, y=0, z=5 })
		EntityService:CreateComponent(self.aimEnt, "NetReplicateToOwnerComponent")
	end

	WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, self.maxDistance )
	EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end

function grenade_cluster_weapon:OnExit( state )

end

function grenade_cluster_weapon:OnEquipped()
	weapon.OnEquipped( self )
	self.sm:ChangeState("execute")
end

function grenade_cluster_weapon:OnActivate()
	WeaponService:StartShoot( self.item );
end

function grenade_cluster_weapon:OnDeactivate()
	WeaponService:StopShoot( self.item );
	return true
end

function grenade_cluster_weapon:OnUnequipped()
	weapon.OnUnequipped( self )
	self.sm:ChangeState( "dummy" )
end

function grenade_cluster_weapon:OnShootingStop()
	self:Explode()
end

function grenade_cluster_weapon:Explode()
	-- Bounce up
	local velocity = Vector3(0, 1.5, 0)
	EntityService:SetVelocity(self.aimEnt, velocity)

	-- Wait for the grenade to reach its peak height
	local peakHeight = 0.5
	local timer = 0
	while timer < peakHeight do
		timer = timer + 0
		coroutine.yield()
	end

	-- Explode into clusters
	for i = 1, self.clusterCount do
       local cluster = self:SpawnCluster()
        
        -- Generate a random direction based on spherical coordinates
        local theta = math.random() * math.pi  -- Polar angle
        local phi   = math.random() * 2 * math.pi  -- Azimuthal angle

        local direction = Vector3(
            math.sin(theta) * math.cos(phi),
            math.sin(theta) * math.sin(phi),
            math.cos(theta)
        )

        direction:Normalize()
        local velocity = direction * self.clusterSpeed
        EntityService:SetVelocity(cluster, velocity)

        print("Cluster spawned with velocity:", velocity)
    end

end

return grenade_cluster_weapon
