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



    local beamWeaponComponent = EntityService:GetComponent( self.entity, "BeamWeaponComponent" )
    if ( beamWeaponComponent ~= nil ) then

        local beamWeaponComponentRef = reflection_helper(beamWeaponComponent)

        if ( mod_scanner_drone_no_sound and mod_scanner_drone_no_sound == 1 ) then
            beamWeaponComponentRef.fire_effect = "effects/mech/bioscanner_muzzle_no_sound"
        else
            beamWeaponComponentRef.fire_effect = "effects/mech/bioscanner_muzzle"
        end
    end
end

function drone_player_scanner:FindActionTarget()
    self:OnWorkInProgress()

    return (self.selectedEntity or INVALID_ID)
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

    if ( mod_scanner_drone_no_sound and mod_scanner_drone_no_sound == 1 ) then
        effectName = effectName .. "_no_sound"
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

            self:SetTargetActionFinished()
            self:TryFindNewTarget()

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

            local maxScanTime = self.maxScanTime

            if ( mod_scanner_drone_instant_scan and mod_scanner_drone_instant_scan == 1 ) then
                maxScanTime = 0
            end

            if ( scanningTime >= maxScanTime ) then

                local scansCount = 1

                if ( mod_scanner_drone_size_matters and mod_scanner_drone_size_matters == 1 ) then

                    scansCount = self:GetScansCount(self.selectedEntity)
                end

                local owner = self:GetDroneOwnerTarget()
                --local playerId = self:GetPlayerForEntity(owner)

                for i=1,scansCount do
                    ItemService:ScanEntity( self.selectedEntity, owner )
                end

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

                self:SetTargetActionFinished()
                self:TryFindNewTarget()
            end
        end
    end

    self.lastTarget = self.selectedEntity;
end

function drone_player_scanner:GetPlayerForEntity( entity )
    if PlayerService.GetPlayerForEntity then
        return PlayerService:GetPlayerForEntity( entity )
    end

    return 0
end

function drone_player_scanner:GetScansCount( entity )

    local scansCount = 1

    local size = EntityService:GetBoundsSize( entity )

    if ( size.x <= 2.5 ) then
        scansCount = 2
    elseif ( size.x <= 4.5 ) then
        scansCount = 4
    elseif ( size.x <= 9.5 ) then
        scansCount = 8
    else
        scansCount = 20
    end

    return scansCount
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

function drone_player_scanner:TryFindNewTarget()
    local target = self:FindActionTarget();
    if target ~= INVALID_ID then
        UnitService:SetCurrentTarget( self.entity, "action", target )
        UnitService:EmitStateMachineParam(self.entity, "action_target_found")
        UnitService:SetStateMachineParam( self.entity, "action_target_valid", 1)
    end
end

function drone_player_scanner:OnWorkInProgress()

    self.predicate = self.predicate or {
        signature = "ScannableComponent"
    }

    local owner = self:GetDroneOwnerTarget()

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, self.predicate )

    local target = self:FindBestEntity( owner, entities )

    if ( ( self.selectedEntity == INVALID_ID or IndexOf( entities, self.selectedEntity ) == nil ) and target ~= INVALID_ID ) then

        self:SelectEntity( target )

    elseif ( self.selectedEntity ~= INVALID_ID and self.shoting == true) then

        self:ExecuteScanning()

    elseif ( target == INVALID_ID ) then

        self:SelectEntity( INVALID_ID )
        self:SetTargetActionFinished()

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

function drone_player_scanner:FindBestEntity( owner, entities )

    if ( mod_scanner_drone_size_matters and mod_scanner_drone_size_matters == 1 ) then

        local best = {
            entity = INVALID_ID,
            distance = nil,
            scansCount = -1
        };

        for entity in Iter( entities ) do

            local scansCount = drone_player_scanner:GetScansCount( entity )

            local distance = EntityService:GetDistanceBetween( self.entity, entity )

            if ( best.entity == INVALID_ID or scansCount > best.scansCount ) then

                best.entity = entity
                best.distance = distance
                best.scansCount = scansCount

            elseif ( scansCount == best.scansCount and best.distance > distance ) then

                best.entity = entity
                best.distance = distance
                best.scansCount = scansCount
            end
        end

        return best.entity

    else
        return FindClosestEntity( self.entity, entities )
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

end

return drone_player_scanner