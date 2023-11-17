local base_drone = require("lua/units/air/base_drone.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/building_utils.lua")

class 'drone_player_scanner' ( base_drone )

function drone_player_scanner:__init()
    base_drone.__init(self,self)
end

function drone_player_scanner:OnInit()

    if ( base_drone.OnInit ) then
        base_drone.OnInit( self )
    end

    self:FillInitialParams()
end

function drone_player_scanner:OnLoad()

    if ( base_drone.OnLoad ) then
        base_drone.OnLoad( self )
    end

    self:FillInitialParams()
end

function drone_player_scanner:FillInitialParams()

    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.maxScanTime = self.data:GetFloatOrDefault( "scanning_time", 2 )

    self:RegisterHandler( self.entity, "TurretEvent", "OnTurretEvent" )

    self.shoting	= false
    self.lastTarget	= INVALID_ID

    if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.effect )
    end
    self.effect		= INVALID_ID

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "working", { execute="OnWorkInProgress" } )

    self.fsm:ChangeState("working")
end

function drone_player_scanner:SpawnSpecificEffect( currentTarget )

    local size = EntityService:GetBoundsSize( currentTarget )

    local effectName

    if ( size.x <= 2.5 ) then
        effectName = "effects/mech/scanner_small"
    elseif ( size.x <= 4.5 ) then
        effectName = "effects/mech/scanner"
    elseif ( size.x <= 9.5 ) then
        effectName = "effects/mech/scanner_big"
    else
        effectName = "effects/mech/scanner_very_big"
    end

    if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.effect )
        self.effect = INVALID_ID
    end

    self.effect = EntityService:SpawnAndAttachEntity( effectName, currentTarget )
end

function drone_player_scanner:ExecuteScanning()

    self.ammoEnt = EntityService:GetChildByName( self.entity, "##ammo##" )

    --LogService:Log("ExecuteScanning " .. tostring(self.ammoEnt))

    if ( self.lastTarget ~= nil and self.lastTarget ~= INVALID_ID and self.lastTarget ~= self.selectedEntity ) then

        if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
            EntityService:RemoveEntity( self.effect )
            self.effect = INVALID_ID
        end

        QueueEvent( "EntityScanningEndEvent", self.lastTarget )
        EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )
        self.lastTarget = INVALID_ID

        EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
    end

    if ( self.selectedEntity ~= INVALID_ID ) then

        WeaponService:RotateWeaponMuzzleToTarget( self.entity, self.selectedEntity )

        EntityService:LookAt( self.entity, self.selectedEntity, true )

        local scannableComponent = EntityService:GetComponent( self.selectedEntity, "ScannableComponent" )
        if ( scannableComponent == nil ) then

            QueueEvent( "EntityScanningEndEvent", self.selectedEntity )
            EffectService:DestroyEffectsByGroup( self.selectedEntity, "scannable" )

            if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
                EntityService:RemoveEntity( self.effect )
                self.effect = INVALID_ID
            end

            EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
            self:SelectEntity(INVALID_ID)

            return
        end

        local scannableComponentHelper = reflection_helper(scannableComponent)
        if ( self.effect == INVALID_ID ) then

            EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_active")

            self:SpawnSpecificEffect( self.selectedEntity )

            QueueEvent( "EntityScanningStartEvent", self.selectedEntity )

        elseif ( self.selectedEntity == self.lastTarget ) then

            scannableComponentHelper.scanning_progress = scannableComponentHelper.scanning_progress + ( 1.0 / 30 )

            local scanningTime = scannableComponentHelper.scanning_progress

            local factor = scanningTime / self.maxScanTime

            factor = math.min( factor, 1.0 )

            if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
                EffectService:SetParticleEmmissionUniform( self.effect, factor )
            end

            if ( scanningTime >= self.maxScanTime ) then

                local owner = self.data:GetIntOrDefault( "owner", 0 )

                ItemService:ScanEntityByPlayer( self.selectedEntity, owner )

                EntityService:RemoveComponent( self.selectedEntity, "ScannableComponent" )

                EffectService:DestroyEffectsByGroup( self.selectedEntity, "scannable" )

                QueueEvent( "EntityScanningEndEvent", self.lastTarget )
                EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )

                EffectService:SpawnEffect( self.selectedEntity, "effects/loot/specimen_extracted" )
                

                if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
                    EntityService:RemoveEntity( self.effect )
                    self.effect = INVALID_ID
                end

                self:SelectEntity(INVALID_ID)
            end
        end
    end

    self.lastTarget = self.selectedEntity;
end

function drone_player_scanner:SelectEntity( target )

    WeaponService:SetCustomTarget( self.entity, target )
    self.selectedEntity = target

    if ( target ~= INVALID_ID ) then

        WeaponService:RotateWeaponMuzzleToTarget( self.entity, target )

        EntityService:LookAt( self.entity, target, true )

        WeaponService:StartShoot( self.entity )
    end
end

function drone_player_scanner:OnWorkInProgress()

    self.predicate = self.predicate or {
        signature = "ScannableComponent"
    }

    local owner = self:GetDroneOwnerTarget()

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, self.predicate )

    local target = FindClosestEntity( owner, entities )

    if ( ( self.selectedEntity == nil or IndexOf( entities, self.selectedEntity ) == nil ) and target ~= INVALID_ID ) then

        self:SelectEntity( target )

    elseif ( self.selectedEntity ~= nil and self.shoting == true) then

        self:ExecuteScanning()

    elseif ( target == INVALID_ID ) then

        self:SelectEntity( INVALID_ID )
        self.selectedEntity = nil

        WeaponService:StopShoot( self.entity )

        if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
            EntityService:RemoveEntity( self.effect )
            self.effect = INVALID_ID
        end

        if ( self.lastTarget ~= nill and self.lastTarget ~= INVALID_ID ) then
            QueueEvent( "EntityScanningEndEvent", self.lastTarget )
            EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )	
        end
    end
end

function drone_player_scanner:OnTurretEvent( evt )

   if( evt:GetTurretEntity() ~= self.entity ) then
        Assert(false,"ERROR: invalid turret event")
        return
   end

   local target = evt:GetTargetEntity()

   local status = evt:GetTurretStatus()

   if ( status == 4) then

        WeaponService:RotateWeaponMuzzleToTarget( self.entity, target )

        EntityService:LookAt( self.entity, target, true )

        WeaponService:StartShoot( self.entity )

        self.shoting = true
   else
        WeaponService:StopShoot( self.entity )
        self.shoting = false

        if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
            EntityService:RemoveEntity( self.effect )
            self.effect = INVALID_ID
        end
        
        if ( self.lastTarget ~= nill and self.lastTarget ~= INVALID_ID ) then
            QueueEvent( "EntityScanningEndEvent", self.lastTarget )
            EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )
        end
   end
end

function drone_player_scanner:OnRelease()
    if ( self.lastTarget ~= nill and self.lastTarget ~= INVALID_ID ) then
        QueueEvent( "EntityScanningEndEvent", self.lastTarget )
        EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )
        self.lastTarget = INVALID_ID
    end

    if ( self.effect ~= nill and self.effect ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.effect )
        self.effect = INVALID_ID
    end

    if ( base_drone.OnRelease ) then
        base_drone.OnRelease(self)
    end
end

function drone_player_scanner:OnDroneTargetAction( target )
    self:SetTargetActionFinished()
end

return drone_player_scanner