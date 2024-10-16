require("lua/utils/string_utils.lua")

local item = require("lua/items/item.lua")

class 'weapon' ( item )

function weapon:__init()
    item.__init(self,self)
end

function weapon:init()
    item.init(self)

    self:RegisterHandler( self.entity, "ShootingStartWeaponEvent",         "_ShootingStart" )
    self:RegisterHandler( self.entity, "ShootingStopWeaponEvent",        "_ShootingStop" )
    self:RegisterHandler( self.entity, "ShootingEmptyStartWeaponEvent",    "_ShootingEmptyStart" )
    self:RegisterHandler( self.entity, "ShootingEmptyStopWeaponEvent",    "_ShootingEmptyStop" )
    
    self.scale = self.data:GetFloatOrDefault("scale", 1.0 )
    self:CreateFeedbackStateMachine();
end

function weapon:ClearWeaponFeedbackState()
    if not self.pad_trigger then return end

    PlayerService:ResetPadTriggerMode( 0, self.pad_trigger.index );
end

function weapon:CreateFeedbackStateMachine()
    if not self._pad_fsm then
        self._pad_fsm = self:CreateStateMachine()
        self._pad_fsm:AddState("check_pad_feedback_state", { enter="UpdateWeaponFeedbackState", execute="UpdateWeaponFeedbackState", exit="ClearWeaponFeedbackState", interval=0.1 })
    end
end

function weapon:OnLoad()
    item.OnLoad(self)

    self:CreateFeedbackStateMachine();
    self.item_type = self.item_type or ItemService:GetItemType( self.entity )
    
    EntityService:LoadMissingDatabaseKeysFromBlueprint( self.entity )
end

-- position = [0,8], strength = [0,8]
function weapon:SetPadTriggerFeedbackMode( position, strength, forced_duration )
    if not self.pad_trigger then return end

    if forced_duration then
        self.pad_trigger.force_feedback = { mode="feedback", position = position, strength = strength, duration = forced_duration }
        self:ReactivatePadFeedbackState();
    else
        self.pad_trigger.feedback = { mode="feedback", position = position, strength = strength }
    end
end

-- start_position = [2,7], end_position = [3,8], strength = [0,8]
function weapon:SetPadTriggerWeaponMode( start_position, end_position, strength, forced_duration )
    if not self.pad_trigger then return end

    if forced_duration then
        self.pad_trigger.force_feedback = { mode="weapon", start_position = start_position, end_position = end_position, strength = strength, duration = forced_duration }
        self:ReactivatePadFeedbackState();
    else
        self.pad_trigger.feedback = { mode="weapon", start_position = start_position, end_position = end_position, strength = strength }
    end
end

-- position = [0,8], amplitude = [0,8], frequency = [0,255]
function weapon:SetPadTriggerVibrationMode( position, amplitude, frequency, forced_duration )
    if not self.pad_trigger then return end

    if forced_duration then
        self.pad_trigger.force_feedback = { mode="vibration", position = position, amplitude = amplitude, frequency = frequency, duration = forced_duration }
        self:ReactivatePadFeedbackState();
    else
        self.pad_trigger.feedback = { mode="vibration", position = position, amplitude = amplitude, frequency = frequency }
    end
end

function weapon:UpdateWeaponFeedbackState( state, dt )
    local playerReferenceComponent = EntityService:GetComponent( self.entity, "PlayerReferenceComponent")
    local playerId = -1    
    if (playerReferenceComponent) then
        local helper = reflection_helper(playerReferenceComponent)
        playerId = helper.player_id
    else
        return
    end

    if self.pad_trigger.force_feedback and type(dt) == 'number' then
        local duration = self.pad_trigger.force_feedback.duration - dt
        self.pad_trigger.force_feedback.duration = duration
        if duration <= 0.0 then
            self.pad_trigger.force_feedback = nil
        end
    end

    if ( PlayerService:IsInBuildMode( playerId ) ) then
        return 
    end

    if not WeaponService:HasAmmoToShoot( self.item ) then
        return PlayerService:SetPadTriggerFeedbackMode( playerId, self.pad_trigger.index, 0, 8 )
	elseif ItemService:GetActiveCooldownLeft( self.entity ) > 1.2 then
        return PlayerService:SetPadTriggerFeedbackMode( playerId, self.pad_trigger.index, 0, 8 )
    elseif not self:IsActivated() and not ItemService:CanActivateItemSlot( self.owner, self.slot, self.item_type ) then
        return PlayerService:SetPadTriggerFeedbackMode( playerId, self.pad_trigger.index, 0, 8 )
    end

    local feedback = self.pad_trigger.force_feedback or self.pad_trigger.feedback
    if not feedback then
        return PlayerService:ResetPadTriggerMode( playerId, self.pad_trigger.index );
    end

    if feedback.mode == "vibration" then
        return PlayerService:SetPadTriggerVibrationMode( playerId, self.pad_trigger.index, feedback.position, feedback.amplitude, feedback.frequency )
	elseif feedback.mode == "feedback" then
        return PlayerService:SetPadTriggerFeedbackMode( playerId, self.pad_trigger.index, feedback.position, feedback.strength )
    elseif feedback.mode == "weapon" then
        return PlayerService:SetPadTriggerWeaponMode( playerId, self.pad_trigger.index, feedback.start_position, feedback.end_position, feedback.strength )
    end
end

function weapon:ReactivatePadFeedbackState()
    if self.pad_trigger then
        self._pad_fsm:Deactivate()
        self._pad_fsm:ChangeState("check_pad_feedback_state")
    end
end

function weapon:GetPadTriggerIndexForSlot( slot )
    if self.owner ~= PlayerService:GetPlayerControlledEnt(0) then
        return nil
    end

    return PlayerService:GetPadTriggerIndexForEquipmentSlot(0, slot)
end

function weapon:SetPadTriggerParams(item_status, duration)
	if not self.data:HasString("pad_" .. item_status .. "_feedback") then
		return false
	end

	local feedback_params = Split(self.data:GetString("pad_" .. item_status .. "_feedback"), ",");
	local feedback_mode = feedback_params[1];

	if feedback_mode == "feedback" and Assert( #feedback_params == 3, "ERROR: invalid params count!") then
		self:SetPadTriggerFeedbackMode( tonumber(feedback_params[2]), tonumber(feedback_params[3]), duration )
	elseif feedback_mode == "weapon" and Assert( #feedback_params == 4, "ERROR: invalid params count!") then
		self:SetPadTriggerWeaponMode( tonumber(feedback_params[2]), tonumber(feedback_params[3]), tonumber(feedback_params[4]), duration )
	elseif feedback_mode == "vibration" and Assert( #feedback_params == 4, "ERROR: invalid params count!" ) then
		self:SetPadTriggerVibrationMode( tonumber(feedback_params[2]), tonumber(feedback_params[3]), tonumber(feedback_params[4]), duration )
	else
		return false
	end

	return true
end

function weapon:OnEquipped()
    self.pad_trigger = nil

    self.item_type = ItemService:GetItemType( self.entity )

    local pad_trigger_index = self:GetPadTriggerIndexForSlot(self.slot);
    if pad_trigger_index ~= nil then
        self.pad_trigger = { index = pad_trigger_index }
        self:ReactivatePadFeedbackState();
    end

	self:SetPadTriggerParams("equipped");

    WeaponService:UpdateWeaponStatComponent( self.entity, self.item )
    
    EntityService:SetScale( self.item, self.scale, self.scale, self.scale )
    EntityService:SetPhysicsScale( self.item, self.scale, self.scale, self.scale )
    local children = EntityService:GetChildren(self.item, true)
    for child in Iter(children) do
        EntityService:SetPhysicsScale( child, self.scale, self.scale, self.scale )
    end

end

function weapon:OnUnequipped()
    ItemService:ResetItemCooldownWeaponBased( self.entity, self.item)

    if self.pad_trigger then
        self._pad_fsm:Deactivate()
        PlayerService:ResetPadTriggerMode( 0, self.pad_trigger.index );

        self.pad_trigger = nil;
    end
end

function weapon:_OnActivate(evt)
    item._OnActivate( self, evt )
	if self:SetPadTriggerParams("active") then
    	self:ReactivatePadFeedbackState();
	end
end

function weapon:_OnDeactivate(evt)
    item._OnDeactivate( self, evt )
	self:SetPadTriggerParams("equipped");
end

function weapon:_ShootingStart( evt )
    EffectService:AttachEffects( self.item, "shooting" ) 
    self:OnShootingStart()
end

function weapon:_ShootingStop( evt )
    EffectService:DestroyEffectsByGroup( self.item, "shooting" ) 
    --local forced = evt:GetForced()
    self:OnShootingStop()
end

function weapon:_ShootingEmptyStart( evt )
    EffectService:AttachEffects( self.item, "shooting_empty" ) 
    self:OnShootingEmptyStart()
end

function weapon:_ShootingEmptyStop( evt )
    EffectService:DestroyEffectsByGroup( self.item, "shooting_empty" ) 
    --local forced = evt:GetForced()
    self:OnShootingEmptyStop()
end

function weapon:OnActivateOnce()
    WeaponService:ShootOnce( self.item )
end

function weapon:OnShootingStart()
end

function weapon:OnShootingStop()
end

function weapon:OnShootingEmptyStart()
end

function weapon:OnShootingEmptyStop()
end

function weapon:OnDrop()
    EffectService:DestroyEffectsByGroup(self.item, "laser_pointer")
end

return weapon