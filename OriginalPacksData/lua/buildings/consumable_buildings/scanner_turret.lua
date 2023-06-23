local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/find_utils.lua")

class 'scanner_turret' ( tower )

function scanner_turret:__init()
	tower.__init(self,self)
end

function scanner_turret:OnInit()
    tower.OnInit(self)

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", {execute="OnWorkInProgress"} )
    self.shooting = false
	self.lastTarget = INVALID_ID
	self.effect 	= INVALID_ID
	self.scanningTime = 0.0
	self.maxScanTime = self.data:GetFloatOrDefault( "scanning_time", 2 )
end

function scanner_turret:OnBuild()
	self.fsm:ChangeState("working")
end

function scanner_turret:SelectEntity( target )
    WeaponService:SetCustomTarget( self.entity, target )
    self.selectedEntity = target
end

function scanner_turret:SpawnSpecifcEffect( currentTarget )
    local effect
    local size = EntityService:GetBoundsSize( currentTarget )
    
    --LogService:Log( tostring( size.x ) ) 
    if ( size.x <= 2.5 ) then
        effect = "effects/mech/scanner_small"
    elseif ( size.x <= 4.5 ) then
        effect = "effects/mech/scanner"		
    elseif ( size.x <= 9.5 ) then
        effect = "effects/mech/scanner_big"		
    else
        effect = "effects/mech/scanner_very_big"		
    end

    self.effect = EntityService:SpawnAndAttachEntity( effect, currentTarget )		
end

function scanner_turret:ExecuteScanning()
	self.ammoEnt = EntityService:GetChildByName( self.entity, "##ammo##" )

    if ( self.lastTarget ~= INVALID_ID and self.lastTarget ~= self.selectedEntity ) then
        EntityService:RemoveEntity( self.effect )
        QueueEvent( "EntityScanningEndEvent", self.lastTarget )
        self.effect = INVALID_ID
        self.lastTarget = INVALID_ID
        self.scanningTime = 0.0

        EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
    end
    
    if ( self.selectedEntity ~= INVALID_ID ) then		
        local scannableComponent = EntityService:GetComponent( self.selectedEntity, "ScannableComponent")
        if ( scannableComponent == nil ) then
            EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
            self:SelectEntity(INVALID_ID)
            EntityService:RemoveEntity( self.effect )
            return
        end
        local scannableComponentHelper = reflection_helper(scannableComponent)
        if ( self.effect == INVALID_ID ) then
            EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_active")
            self.scanningTime = 0.0
            self:SpawnSpecifcEffect( self.selectedEntity )
            QueueEvent( "EntityScanningStartEvent", self.selectedEntity )
        elseif ( self.selectedEntity == self.lastTarget ) then
            scannableComponentHelper.scanning_progress = scannableComponentHelper.scanning_progress + ( 1.0 / 30.0 ) 
            self.scanningTime = scannableComponentHelper.scanning_progress
            local factor =  self.scanningTime / self.maxScanTime
            factor = math.min(factor, 1.0 )
            EffectService:SetParticleEmmissionUniform( self.effect, factor )
            if ( self.scanningTime >= self.maxScanTime ) then
                ItemService:ScanEntityByPlayer( self.selectedEntity, self.data:GetIntOrDefault( "owner", 0) )
                EntityService:RemoveComponent( self.selectedEntity, "ScannableComponent" ) 
                EntityService:RemoveEntity( self.effect )
                EffectService:DestroyEffectsByGroup( self.selectedEntity, "scannable" )
                QueueEvent( "EntityScanningEndEvent", self.lastTarget )
                EffectService:SpawnEffect( self.selectedEntity, "effects/loot/specimen_extracted")
                self.effect = INVALID_ID
                self:SelectEntity(INVALID_ID)
                self.scanningTime = 0.0
            end
        end
    end
    
    self.lastTarget = self.selectedEntity;
end

function scanner_turret:OnWorkInProgress()
    self.predicate = self.predicate or {
        signature = "ScannableComponent"
    }

    local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, WeaponService:GetTurretMaxRange( self.entity ), self.predicate )
    local target = FindClosestEntity( self.entity, entities );
    if ( self.selectedEntity == nil or IndexOf( entities, self.selectedEntity ) == nil ) and target ~= INVALID_ID then
        self:SelectEntity( target )
    elseif ( self.selectedEntity ~= nil and self.shoting == true) then
        self:ExecuteScanning()
    elseif target == INVALID_ID   then
        self:SelectEntity( INVALID_ID )
        WeaponService:StopShoot( self.entity )
        self.selectedEntity = nil        
    end
    
end

function scanner_turret:OnTurretEvent( evt )
   if( evt:GetTurretEntity() ~= self.entity ) then
        Assert(false,"ERROR: invalid turret event")
        return   
   end
   local status = evt:GetTurretStatus()
   if ( status == 4) then
        WeaponService:StartShoot( self.entity )
        self.shoting = true
   else
        WeaponService:StopShoot( self.entity )
        self.shoting = false
   end 
end

function scanner_turret:OnRelease()
    if ( self.lastTarget ~= INVALID_ID) then
        QueueEvent( "EntityScanningEndEvent", self.lastTarget )
        EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )

    end

    if ( self.effect ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.effect )
    end
end

return scanner_turret
