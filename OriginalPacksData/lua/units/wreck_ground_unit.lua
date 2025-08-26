
class 'wreck_ground_unit' ( LuaEntityObject )

function wreck_ground_unit:__init()
	LuaEntityObject.__init(self,self)
end

-- INIT
function wreck_ground_unit:init()	
    self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
    self:RegisterHandler( self.entity, "AnimationStateChangedEvent", "OnAnimationStateChanged" )
    self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" )
    self:RegisterHandler( self.entity, "TargetFoundEvent", "OnBuildingFoundEvent" )
    self:RegisterHandler( self.entity, "AnimationTerminalNodeReachedEvent", "OnAnimationTerminalNodeReachedEvent" )
    
    local wreckTeamComponent = EntityService:GetConstComponent( self.entity, "WreckTeamComponent")
    local damageType = ""
    if ( wreckTeamComponent ~= nil ) then
        damageType = wreckTeamComponent:GetField("killed_by_damage_type"):GetValue()
    end

    self:initDefaultParams()
    self:initParams()
    
    self:overrideParams()

    if EntityService:CompareType( self.entity, "ground_unit_small" ) then
        EntityService:ChangeType( self.entity, "prop|wreck_small" )
    elseif EntityService:CompareType( self.entity, "ground_unit_medium" ) then 
        EntityService:ChangeType( self.entity, "prop|wreck_medium" )
    elseif EntityService:CompareType( self.entity, "ground_unit_large" ) then 
        EntityService:ChangeType( self.entity, "prop|wreck_large" )
    end

    self.meshChanged = false
    --remove effect groups after death

    if damageType == 'melee' then
        self:CreateNormalWreck()
	elseif ( ( damageType == 'fire' ) and ( self.leaveBodyProbability ~= 0 ) ) then 
		self:LeaveBody()
    elseif damageType == 'gravity' then 
        self:CreateNormalExplode()
    else
        self:CreateNormalWreck()
    end

    EntityService:RemoveLifeTime(self.entity)
    EntityService:DissolveEntity( self.entity, 3.0, self.wreckLifetime )

	self.resurrectAllowFSM = self:CreateStateMachine()
	self.resurrectAllowFSM:AddState( "resurrect_allow", { enter="OnEnterResurrectAllow", exit="OnExitResurrectAllow" } )
	self.resurrectAllowFSM:ChangeState( "resurrect_allow" )
end

function wreck_ground_unit:OnEnterResurrectAllow( state )
	state:SetDurationLimit( self.resurrectCooldown )
end

function wreck_ground_unit:OnExitResurrectAllow( state )
    local forceLeaveBody = UnitService:GetStateMachineParamInt(self.entity, "force_leave_body")
    UnitService:SetStateMachineParam(self.entity, "can_be_resurrected", forceLeaveBody == 1 and 0 or 1)
end


function wreck_ground_unit:OnLoad()
    if self.dissolve then
        self:DestroyStateMachine( self.dissolve )
        EntityService:DissolveEntity( self.entity, 3.0, self.wreckLifetime )
        self.dissolve = nil
    end
end

function wreck_ground_unit:overrideParams()

    local forceLeaveBody = UnitService:GetStateMachineParamInt( self.entity, "force_leave_body" )

    if ( forceLeaveBody == 1 ) then
        self.resurrectCooldown = 1000
    end
end

function wreck_ground_unit:initDefaultParams()
    if ( BuildingService:IsOnResource( self.entity, "" ) or UnitService:IsOnArena( self.entity ) ) then
        self.wreckLifetime = RandInt( 3, 6 )
    else
        self.wreckLifetime = RandInt( 120, 180 )
    end

    self.deathAnimationMarkers = {}
    self.deathAnimationStates = {}
    self.resurrectCooldown = 1
end

function wreck_ground_unit:initParams()	
end

-- NORMAL WRECK
function wreck_ground_unit:LeaveBody()
	EffectService:AttachEffects(self.entity, "death")

    UnitService:CreateFindTargetRequest( self.entity, "check_building", 10.0, "", "building", true );
end

function wreck_ground_unit:OnBuildingFoundEvent()
    self.wreckLifetime = RandInt( 3, 6 )
    EntityService:RemoveLifeTime(self.entity)
    EntityService:DissolveEntity( self.entity, 3.0, self.wreckLifetime )
end

function wreck_ground_unit:CreateNormalWreck()
    if ( UnitService:IsOnHeightGround( self.entity ) == true ) then --fail safe
        self:CreateNormalExplode()
    else
        self:LeaveBody()
    end
end

function wreck_ground_unit:CreateNormalExplode()
    EntityService:RequestDestroyPattern( self.entity, "wreck" )	
end
    
function wreck_ground_unit:OnDestroyRequest( state )
    if self._OnDestroyRequest then
        self:_OnDestroyRequest( state )
    else
        EntityService:RequestDestroyPattern( self.entity, "wreck" )
    end
end

function wreck_ground_unit:ChangeMeshAndSpawnEffects( name )
    EntityService:RequestDestroyPattern( self.entity, name, false )	
    local oldMeshName = EntityService:GetMeshName( self.entity )
    local parsedOldMeshName = Split( oldMeshName, "." )
    local newMeshName = parsedOldMeshName[1] .. "_" .. name .. ".mesh"

    local oldMaterialName = EntityService:GetOverridenMaterial( self.entity )

    --LogService:Log( "wreck_ground_unit:ChangeMeshAndSpawnEffects oldMeshName :" .. oldMeshName .. " newMeshName :" .. newMeshName )
    --LogService:Log( "wreck_ground_unit:ChangeMeshAndSpawnEffects oldMaterialName :" .. oldMaterialName )
    EntityService:ChangeMesh( self.entity, newMeshName )
    EntityService:ChangeMaterial( self.entity, oldMaterialName )

    self.meshChanged = true
end

function wreck_ground_unit:CheckChangeMeshRequest( checkTable, checkWithEventName )
    if ( self.meshChanged == false ) then
	    for i = 1, #checkTable, 1 do 			
            --LogService:Log( "wreck_ground_unit:CheckChangeMeshRequest :" .. checkTable[i] )
		    if ( checkTable[i] == checkWithEventName ) then
                return true
            end
	    end
    end

    return false
end

function wreck_ground_unit:OnAnimationStateChanged( evt )

    local stateName = evt:GetNewStateName() 
    
    if ( self:CheckChangeMeshRequest( self.deathAnimationStates, stateName ) ) then
        self:ChangeMeshAndSpawnEffects( stateName )
    end

    if self._OnAnimationStateChanged then
        self:_OnAnimationStateChanged( evt )
    end

    if string.match( stateName, "^death_" ) then
        self.deathAnimName = stateName
    end

end

function wreck_ground_unit:OnAnimationTerminalNodeReachedEvent( evt )
    
    if ( self.deathAnimName ~= nil ) then
        EntityService:RemoveComponent( self.entity, "AnimationGraphComponent" )

        local animationComponent = EntityService:CreateComponent( self.entity, "AnimationComponent" )
        local animationComponentHelper = reflection_helper( animationComponent )
        local container = rawget( animationComponentHelper.active_animations, "__ptr" );
        local instance =  reflection_helper( container:CreateItem() )

        instance.name = self.deathAnimName
        instance.start_time = 10.0
        instance.remove_on_end = 0

       -- LogService:Log( "wreck_ground_unit:OnAnimationTerminalNodeReachedEvent replaced AnimationGraphComponent with AnimationComponent :" .. self.deathAnimName )
    end
end

function wreck_ground_unit:OnAnimationMarkerReached( evt )
	
	local markerName = evt:GetMarkerName() 

    if ( self:CheckChangeMeshRequest( self.deathAnimationMarkers, markerName ) ) then
        self:ChangeMeshAndSpawnEffects( markerName )
    elseif ( markerName == "explode" ) then
        EffectService:AttachEffects( self.entity, markerName  )
        EntityService:RequestDestroyPattern( self.entity, "wreck" )	
    else
        EffectService:AttachEffects( self.entity, markerName  )
    end

	--LogService:Log( "wreck_ground_unit:OnAnimationMarkerReached :" .. markerName )

end

return wreck_ground_unit