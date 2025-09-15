class 'crystal_wall_ruins' ( LuaEntityObject )
require("lua/utils/reflection.lua")

function crystal_wall_ruins:__init()
	LuaEntityObject.__init(self,self)
end

function crystal_wall_ruins:init()
	local roll = RandFloat( 0.0, 100.0 )

	local regenerationChance = self.data:GetFloat("regeneration_chance")
	local regenerationTime = self.data:GetFloat("regeneration_time")

	if ( regenerationChance > roll ) then 
		self:RegisterHandler( self.entity, "TimerElapsedEvent", "OnTimerElapsedEvent")
		EntityService:CreateComponent( self.entity, "TimerComponent")
		QueueEvent( "SetTimerRequest", self.entity, "RegenerationStart", regenerationTime )
	end

	self.version = 1
end

function crystal_wall_ruins:OnLoad()
	if not self.version or self.version < 1 then
		local position = EntityService:GetPosition(self.entity)
		local owners = FindService:FindGridOwnersByBox(position,position)
		if #owners > 0 then
			EntityService:DestroyEntity(self.entity, "default")
		end
	end

	self.version = 1
end

function crystal_wall_ruins:OnTimerElapsedEvent(evt)
    if (evt:GetName() ~= "RegenerationStart") then
        return
    end
	
    local ruinsBlueprint = self.data:GetString("blueprint")
	local building = EntityService:SpawnEntity( ruinsBlueprint, self.entity, EntityService:GetTeam( self.entity ) )
	
	local healthAmountInPercent = self.data:GetFloatOrDefault("health_amount_in_percent", 30)
	local dissolveTime = self.data:GetFloatOrDefault("dissolve_time", 0.75)

	HealthService:SetHealthInPercentageWithoutEffects( building, healthAmountInPercent)
	EntityService:FadeEntity( building, DD_FADE_IN, dissolveTime )
	

	local playerReferenceComponent = EntityService:GetComponent(self.entity, "PlayerReferenceComponent")
	local playerReference = reflection_helper(EntityService:CreateComponent(building, "PlayerReferenceComponent"))
	if ( playerReferenceComponent )  then
		local helper  = reflection_helper(playerReferenceComponent )
		playerReference.player_id = helper.player_id
    	playerReference.reference_type.internal_enum = helper.reference_type.internal_enum
	else
		playerReference.player_id = 0
    	playerReference.reference_type.internal_enum = 4
	end

	EntityService:RemoveEntity(self.entity)
end

return crystal_wall_ruins
 