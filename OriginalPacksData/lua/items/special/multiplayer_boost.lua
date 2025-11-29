local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
class 'multiplayer_boost' ( item )

function multiplayer_boost:__init()
	item.__init(self,self)
end

function multiplayer_boost:OnInit()
    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "charging", {execute="OnChargingInProgress"} )
    self.radius = self.data:GetFloatOrDefault("radius", 10.0)
    self.dischargeRadius = self.data:GetFloatOrDefault("discharge_radius", 10.0)
    self.boostActivationTrigger = self.data:GetFloatOrDefault("boost_activation_trigger", 5.0)
    self.boostCooldown = self.data:GetFloatOrDefault("cooldown", 60.0)
    self.heal  = self.data:GetFloatOrDefault("heal", 50.0)
    self.boostActivationBp  = self.data:GetStringOrDefault("boost_activation_bp", "")
    self.boostInteractActivationEffect  = self.data:GetStringOrDefault("interact_boost_activation_effect", "")
    self.boostCooldownBp  = self.data:GetStringOrDefault("boost_cooldown_bp", "")
    self.beamToMech = {}
    self.timer = -1
    self.cooldownTimer = 0
    self.cooldownDeadline = 0
    self.state = "charging"
    self.cooldownEffect = nil
end

function multiplayer_boost:OnLoad()
    self.dischargeRadius = self.dischargeRadius or self.radius
    self:Cleanup()
end

function multiplayer_boost:OnEquipped()
    self.team = EntityService:GetTeam( self.owner )
    self.fsm:ChangeState("charging")

end

function multiplayer_boost:OnUnequipped()
    self.fsm:Deactivate()
    self:Cleanup()
end

function multiplayer_boost:OnRelease()
    self.fsm:Deactivate()
    self:Cleanup()
end

function multiplayer_boost:Cleanup()
    for  mech, data  in pairs( self.beamToMech ) do
        EntityService:RemoveEntity( data.entity )
    end
    self.beamToMech = {}
end

function multiplayer_boost:OnChargingInProgress( state )
    local mechs = {}
    local mechsUsed = {}
    local resetTimer = false
    local currentTime = GetLogicTime()
    if ( self.owner == nil or not EntityService:IsAlive( self.owner ) ) then
        self.fsm:Deactivate()
        self:Cleanup()
        return
    end

    local ownerPosition = EntityService:GetPosition(self.owner)
    local ownerSize = EntityService:GetBoundsSize( self.owner )
    
    local factor = 0.0
    if ( self.timer ~= -1 ) then
        factor = (currentTime - self.timer) / self.boostActivationTrigger
        factor = Clamp( factor, 0.0, 1.0 )
    end

    if (self.cooldownDeadline > currentTime and currentTime + self.boostCooldown > self.cooldownDeadline   and self.cooldownEffect == nil ) then
        if( self.boostCooldownBp ~= "" ) then
            self.cooldownEffect =EntityService:SpawnAndAttachEntity( self.boostCooldownBp, self.owner )
            EntityService:GetDatabase( self.cooldownEffect ):SetFloat("skill_end_timestamp", self.cooldownDeadline)
        end
    elseif(self.cooldownEffect ~= nil and  currentTime > self.cooldownDeadline) then
        EntityService:RemoveEntity( self.cooldownEffect )        
        self.cooldownEffect = nil
    end

    self.predicate = self.predicate or {
        signature = "MechComponent,HealthComponent,EquipmentComponent"
    }

    if ( currentTime >self.cooldownDeadline ) then
        mechs = FindService:FindEntitiesByPredicateInRadius(self.owner, self.dischargeRadius, self.predicate)
    end

    local additionalCount = 0
    for mech in Iter(mechs) do
        if ( mech == self.owner or EntityService:GetTeam(mech) ~= self.team ) then
            goto continue
        end
        local target_position = EntityService:GetPosition(mech)
        if ( Distance( target_position, ownerPosition) < 1.0 ) then
            if ( self.beamToMech[mech] ~= nil ) then
                EntityService:RemoveEntity( self.beamToMech[mech].entity )
                self.beamToMech[mech] = nil
            end
            additionalCount = additionalCount + 1
            goto continue
        end
        local lightning = nil
        if ( self.beamToMech[mech] == nil ) then
            local distance = EntityService:GetDistanceBetween( self.owner, mech )
            if ( distance > self.radius ) then
                goto continue
            end

            lightning = EntityService:SpawnEntity( "items/special/multiplayer_boost_beam", self.owner, "")
            self.beamToMech[mech] = { entity=lightning } 
            EntityService:PropagateEntityOwner( lightning, self.entity )
            resetTimer = true
        else
            lightning = self.beamToMech[mech].entity
        end
        
        if (not Assert( EntityService:IsAlive( lightning ), "ERROR: lightning not alive recreating! ") ) then
            self.beamToMech[mech] = nil
            goto continue
        end

        local component = reflection_helper(EntityService:GetComponent(lightning, "LaserBeamComponent"))
        if ( not Assert( component ~= nil, "ERROR: lightning doesnt have LaserBeamComponent! ") ) then
            EntityService:RemoveEntity( lightning )
            self.beamToMech[mech] = nil
            goto continue
        end

        component.range = Distance( ownerPosition, target_position)
        component.last_target = mech
        component.current_target = mech
        EntityService:LookAt( lightning, mech, true)
        Insert(mechsUsed, mech )

        local position = ownerPosition
        local lightningComponent = reflection_helper(EntityService:GetComponent(lightning, "LightningDataComponent"))
        local container = rawget(lightningComponent.lighning_vec, "__ptr");

        local instance = nil
        if ( container:GetItemCount() == 0 ) then
            instance = reflection_helper(container:CreateItem())
        else 
            instance = reflection_helper(container:GetItem(0))
        end

        local direction = VectorMulByNumber( Normalize( VectorSub( target_position, ownerPosition ) ), 2.0 )
        position = VectorAdd(position, direction)
    
        instance.start_point.x = position.x
        instance.start_point.y = position.y + (ownerSize.y / 2.0)
        instance.start_point.z = position.z
    
        instance.end_point.x = target_position.x
        instance.end_point.y = target_position.y  + (ownerSize.y / 2.0)
        instance.end_point.z = target_position.z

        lightningComponent.beam_scale = Lerp( 1, 5, factor )

        local effectPosition = ownerPosition
        effectPosition.y = effectPosition.y + (ownerSize.y / 2.0)
        EntityService:SetPosition(lightning, effectPosition)
        ::continue::
    end
    
    for  mech, data  in pairs( self.beamToMech ) do
        if ( IndexOf(mechsUsed, mech ) == nil ) then
            EntityService:RemoveEntity( data.entity )
            self.beamToMech[mech] = nil
            resetTimer = true
        end
    end

    local mechsCount = Size(self.beamToMech) + additionalCount

    if (currentTime < self.cooldownDeadline ) then
        return
    else
        if ( self.timer == -1 and Size(self.beamToMech) ~= 0) then
            resetTimer = true
        end
    end

    if ( resetTimer ) then
        self.timer = GetLogicTime()
    end

    if (mechsCount == 0 ) then
        self.timer = -1
        return
    end

    if ( self.timer == -1) then
        return
    end

    if ( (currentTime - self.timer) > self.boostActivationTrigger ) then
        local effectName = self:GetBoostEffectForMechCount( mechsCount + 1 )
        local effect = EntityService:SpawnAndAttachEntity(effectName, self.owner )
        local effectTime = EntityService:GetLifeTime( effect )
        if ( self.boostActivationBp ~= "" ) then
            EffectService:AttachEffect( self.owner, self.boostActivationBp )
        end	
        self.timer = -1
        self.cooldownDeadline = currentTime + effectTime + self.boostCooldown
    end

end

function multiplayer_boost:GetBoostEffectForMechCount( mechsCount )
    
    for i=mechsCount,1,-1 do
        local name = "items/special/multiplayer_boost_effect_" .. i
        if ResourceManager:ResourceExists( "EntityBlueprint",  name  ) then
            return name;
        end
    end
    Assert( false, "ERROR: there is no effect for " .. mechsCount .. " mechs" )
    return nil
end

function multiplayer_boost:OnActivate()
end

function multiplayer_boost:OnInteractWithEntityRequest( event )
end

return multiplayer_boost
