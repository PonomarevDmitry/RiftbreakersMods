--local building = require("lua/buildings/defense/tower.lua")
local building = require("lua/buildings/building.lua")
require("lua/utils/table_utils.lua")
--require("lua/utils/reflection.lua")
--require("lua/utils/find_utils.lua")

class 'scanner_tower' ( building )

function scanner_tower:__init()
    building.__init(self,self)
end

function scanner_tower:OnInit()
    building.OnInit(self)

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "working", {execute="OnWorkInProgress"} )
    self.shooting = false
    self.lastTarget = INVALID_ID
    self.effect 	= INVALID_ID
    self.scanningTime = 1.0
    self.maxScanTime = self.data:GetFloatOrDefault( "scanning_time", 0.5 )

    -- tower.lua v
    self:RegisterHandler( event_sink , "DayStartedEvent", "_OnDayCycleDayStartedEvent")	
    self:RegisterHandler( event_sink , "NightStartedEvent", "_OnDayCycleNightStartedEvent")	
    self:RegisterHandler( event_sink , "SunriseStartedEvent", "_OnDayCycleSunriseStartedEvent")	
    self:RegisterHandler( event_sink , "SunsetStartedEvent", "_OnDayCycleSunsetStartedEvent")	
    self:RegisterHandler( self.entity, "ResourceMissingEvent", "OnResourceMissingEvent" ) 
    self:RegisterHandler( self.entity, "TurretEvent", "OnTurretEvent" )
    self.lightStatus = false
    
    self.data:SetFloat( "shooting", 0 )
    local timeOfDay = EnvironmentService:GetTimeOfDay()
    -- tower.lua ^
end

function scanner_tower:OnBuild()
    self.fsm:ChangeState("working")
end

function scanner_tower:SelectEntity( target )
    WeaponService:SetCustomTarget( self.entity, target )
    self.selectedEntity = target
end

function scanner_tower:SpawnSpecifcEffect( currentTarget )
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

function scanner_tower:ExecuteScanning()
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
            QueueEvent("ShowScannableRequest", event_sink, true )
        elseif ( self.selectedEntity == self.lastTarget ) then
            scannableComponentHelper.scanning_progress = scannableComponentHelper.scanning_progress + ( 1.0 / 0.3 ) 
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

function scanner_tower:OnWorkInProgress()
    
    local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, WeaponService:GetTurretMaxRange( self.entity ), {
        signature = "ScannableComponent"
    } )
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

function scanner_tower:OnTurretEvent( evt )
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

function scanner_tower:OnRelease()
    if ( self.lastTarget ~= INVALID_ID) then
        QueueEvent( "EntityScanningEndEvent", self.lastTarget )
        EffectService:DestroyEffectsByGroup( self.lastTarget, "scannable" )
    end

    if ( self.effect ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.effect )
    end
    
    building.OnRelease(self)
end

-- tower.lua v
function scanner_tower:OnDestroy()
    return true
end

function scanner_tower:_OnDayCycleDayStartedEvent( )
    self:OperateLight("day")
end

function scanner_tower:_OnDayCycleNightStartedEvent( )
    self:OperateLight("night")
end

function scanner_tower:_OnDayCycleSunriseStartedEvent( )
    self:OperateLight("sunrise")
end

function scanner_tower:_OnDayCycleSunsetStartedEvent( )
    self:OperateLight("sunset")
end

function scanner_tower:OnActivate()
    self:OperateLight(EnvironmentService:GetTimeOfDay())
end

function scanner_tower:OnDeactivate()
    self:OperateLight(EnvironmentService:GetTimeOfDay())
end

function scanner_tower:OperateLight( time )
    if self.working == true and time ~= "day" and self.lightStatus == false then
        EffectService:AttachEffects(self.entity, "lamp")	
        self.lightStatus = true
    elseif self.working == false and self.lightStatus == true then 
        EffectService:DestroyEffectsByGroup(self.entity, "lamp")	
        self.lightStatus = false
    elseif time == "day" and self.lightStatus == true then
        EffectService:DestroyEffectsByGroup(self.entity, "lamp")	
        self.lightStatus = false
    end
end


function scanner_tower:OnResourceMissingEvent( evt )
    local resource = evt:GetResource()
    if ( resource ~= "energy" and resource ~= "ai" and ConsoleService:GetConfig("g_tower_ammo_missing_annoucements") == "1" ) then
        EntityService:ShowTimeoutSoundEvent( INVALID_ID, 30.0, "voice_over/announcement/not_enough_ammo_tower", false )
    end
end
-- tower.lua ^

return scanner_tower
