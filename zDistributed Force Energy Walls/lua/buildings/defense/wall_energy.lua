require("lua/utils/table_utils.lua")
local building = require("lua/buildings/defense/wall.lua")


class 'wall_energy' (wall)

--Hard-coded here because otherwise there will be 12 copies. Static because they will never change.
--Search diameter
local diameter = 2.9 --Slighty smaller than the actual display diameter due to finicky detection near the edge
--Maximum initial start-up delay in seconds
local initial_delay = 5.0 --Shorter than the search period, but long enough to effecively stagger start times
--Search interval in seconds
local period = 10.0 --Long interval to reduce the number of computations since there will be massive numbers of walls
--How many times faster the shield should decay than regenerate
--first value is before shield separation, second is after
local decay_multipliers = {-2.0, -0.75}
--Cut-off point for shield sharing if power is lost
local decay_threshold = 0.5


--Standard __init() function to make sure the parent class gets called.
function wall_energy:__init()
	wall.__init(self, self)
end

--Runs on creation of entity
function wall_energy:OnInit()
	--Assign this Entity to a group for Map search purposes.
	EntityService:SetGroup(self.entity, "energy_walls")

	--Declare these to store data for later
	self.damageVal = 0 --Damage Reflection Amount
	self.regen_rate = 0 --Shield Recharge Rate when powered
	self.decay_rate = {} --Shield Drain rate when unpowered
	self.regen_cooldown = 0 --Shield recharge delay after damage
	self.active = false --Power status of this building 

	--Records which entities are currently affected by the shield. DO NOT TOUCH.
	--Syntax is different for efficiency reasons, and to store relational data.
	self.selected = {}

	--Import from bluprint database:
	--Blueprint of entity representing the shield
	self.shieldBp = self.data:GetStringOrDefault("shield_bp", "buildings/defense/wall_energy/shield")

	--Create the state machine to periodically search for objects that need added to or removed from the shield.
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("delay", {enter="OnDelayStart", exit="OnDelayEnd"})
	self.fsm:AddState("working", {enter="OnWorkInProgress", execute="OnWorkInProgress", exit="OnWorkExit", interval=period})
	self.fsm:AddState("shutdown", {execute="OnShutdown", interval=0.1})
end

--Runs when the building turns on, including initial power on.
function wall_energy:OnActivate()
	self.active = true

	--Verify the shield component exists. Create it if missing.
	if self.healthChild == nil then
		--Create and attatch the Shield as a child object.
		self.healthChild = EntityService:SpawnAndAttachEntity(self.shieldBp, self.entity)
		--Add self to the shield.
		--This makes the shield feel snappy when placing the building, despite the long interval between scans.
		ItemService:AddHealthLink(self.entity, self.healthChild)
	end

	self:EnableDamage()
	self:ChargeShield()

	--Start up shield scan loop
	self.fsm:ChangeState("delay")
end

--Runs when the building turns off, loses power, or is removed.
function wall_energy:OnDeactivate()
	self.active = false

	--Shut down Shield
	local state = self.fsm:GetState(self.fsm:GetCurrentState())
	if (state ~= nil) then
		state:Exit()
	end

	--Disable Damage Reflection and Drain the Shield HP, BUT ONLY IF THEY EXIST
	if (not EntityService:HasComponent(self.entity, "ReflectDamageComponent")) then return end
	self:DisableDamage()
	self:DrainShield(1)
end

--Runs when the Building hits 0 HP
function wall_energy:OnDestroy()
	--disconnect the shield
	self:UnlinkShield()
end

--Runs when the building is sold
function wall_energy:OnSell()
	--disconnect the shield
	self:UnlinkShield()
end

--Runs when loading into an existing map
function wall_energy:OnLoad()
	--Reset the staggering of shield searches
	if self.active then
		self.fsm:ChangeState("delay")
	end
end

-----------------------------------------------------------------------------------------------------------
--STATE MACHINE     STATE MACHINE     STATE MACHINE     STATE MACHINE     STATE MACHINE     STATE MACHINE
-----------------------------------------------------------------------------------------------------------
--This serves as a random-length delay before the main state machine actually starts.
--Its purpose is to desynchronize shield detection updates for performance reasons.
function wall_energy:OnDelayStart(state)
	state:SetDurationLimit(RandFloat(0.1, initial_delay))
end

--If the wall is still on, continue to "working," otherwise shut down.
function wall_energy:OnDelayEnd(state)
	if self.active then
	    self.fsm:ChangeState("working")
	end
end


--State Machine Loop function
function wall_energy:OnWorkInProgress(state)
	--Check for the shield entity, and re-create it if it is missing.
	if (self.healthChild == INVALID_ID or HealthService:GetHealth(self.healthChild)== -1) then
		self.healthChild = EntityService:SpawnAndAttachEntity(self.shieldBp, self.entity)
	end

	--Search Map for targets
	local objects = FindService:FindEntitiesByGroupInRadius(self.entity, "energy_walls", diameter)

	--Check which found targets haven't been shielded, add the shield, and record them.
	for index, obj in ipairs(objects) do
		if (self.selected[obj] == nil and BuildingService:IsBuildingFinished(obj) and obj ~= self.entity) then
			ItemService:AddHealthLink(obj, self.healthChild)	--Add Shield
			self.selected[obj] = true	--Add Record
		end
	end

	--Check for any recorded targets that no longer exist, and remove them.
	for obj, val in pairs(self.selected) do
		if (IndexOf(objects, obj) == nil) then
			ItemService:RemoveHealthLink(obj, self.healthChild)	--Remove shield
			self.selected[obj] = nil	--Delete Record
		end
	end
end

--State Machine Exit function (runs on power off, removal, or destruction of self)
function wall_energy:OnWorkExit(state)
	--if no power, switch to shutdown, otherwise kill the shield imediately
	if not self.active then
		self.fsm:ChangeState("shutdown")
	else
		self:UnlinkShield()
	end
end

function wall_energy:OnShutdown(state)
	--Terminate shield sharing once the decay threshold is reached, then exit.
	--Rebooting the shield before this is reached will automatically kill this by switching states.
	if HealthService:GetHealthInPercentage(self.healthChild) < decay_threshold then
		self:UnlinkShield()
		self:DrainShield(2)
		state:Exit()
	end
end

-----------------------------------------------------------------------------------------------------------
--SUBFUNCTIONS     SUBFUNCTIONS     SUBFUNCTIONS     SUBFUNCTIONS     SUBFUNCTIONS     SUBFUNCTIONS
-----------------------------------------------------------------------------------------------------------
--Removes all entities from the Shield
function wall_energy:UnlinkShield()
	--Remove shield from all targets, except the emitter, and delete all records.
	--The emitter is excluded as it does not have a record.
	for obj, val in pairs(self.selected) do
		ItemService:RemoveHealthLink(obj, self.healthChild)
		self.selected[obj] = nil
	end
end

--Enables Damage Reflection
function wall_energy:EnableDamage()
	--Check that Damage Reflection amount is stored, then enable it
	local DRcomponent = reflection_helper(EntityService:GetComponent(self.entity, "ReflectDamageComponent"))
	if self.damageVal ~= 0 then
		--Restore Damage Reflection
		DRcomponent.damage_value = self.damageVal
	else
		--Store value if not set
		--Doing this here because onInit() is too early
		self.damageVal = DRcomponent.damage_value
	end
end

--Disables Damage Reflection
function wall_energy:DisableDamage()

	local DRcomponent = reflection_helper(EntityService:GetComponent(self.entity, "ReflectDamageComponent"))
	DRcomponent.damage_value = 0
end

--Sets Shield to charge
function wall_energy:ChargeShield()
	--Check that Shield Regen amount is stored, then enable it
	local Rcomponent = reflection_helper(EntityService:GetComponent(self.healthChild, "RegenerationComponent"))
	if self.regen_rate ~= 0 then
		Rcomponent.regeneration = self.regen_rate
		Rcomponent.regeneration_cooldown = self.regen_cooldown
	else
		--Store value if not set
		--Doing this here because onInit() is too early
		self.regen_rate = Rcomponent.regeneration
		self.decay_rate = {}
		for i=1, #decay_multipliers do
			self.decay_rate[i] = decay_multipliers[i] * self.regen_rate
		end
		self.regen_cooldown = Rcomponent.regeneration_cooldown
	end
end

--Sets Shield to Drain
function wall_energy:DrainShield(mode)
	--Set Shield to decay
	local Rcomponent = reflection_helper(EntityService:GetComponent(self.healthChild, "RegenerationComponent"))
	Rcomponent.regeneration = self.decay_rate[mode]
	Rcomponent.regeneration_cooldown = 0

	--Subtract 1 HP to kickstart the drain, as otherwise it won't work if fully charged
	local Hcomponent = reflection_helper(EntityService:GetComponent(self.healthChild, "HealthComponent"))
	Hcomponent.health = Hcomponent.health - 1
end


return wall_energy