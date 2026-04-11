require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'potion' ( item )

function potion:__init()
	item.__init(self,self)
end

function potion:OnInit()
	self.amount = self.data:GetFloat( "amount" )
end

function potion:OnEquipped()

	
end

function potion:OnActivate()

	HealthService:AddHealthInPercentage( self.owner, self.amount )
	EffectService:SpawnEffect(self.entity, "effects/items/potion")

	self.radius = 20

	local mechs = FindService:FindEntitiesByTypeInRadius( self.owner, "player", self.radius )

	for entity in Iter(mechs) do

		if ( not EntityService:IsAlive( entity ) ) then
			goto continueMech
		end
	
		if ( not HealthService:IsAlive( entity ) ) then
			goto continueMech
		end
	
		local health = HealthService:GetHealthInPercentage( entity )
		if ( health < 1 ) then

			HealthService:AddHealthInPercentage( entity, self.amount )

			EffectService:SpawnEffect( entity, "effects/buildings_generic/building_repair_big" )
		end

		::continueMech::
	end

	local buildings = FindService:FindEntitiesByTypeInRadius( self.owner, "building", self.radius )

	for entity in Iter(buildings) do
	
		if ( not EntityService:IsAlive( entity ) ) then
			goto continueBuilding
		end
	
		if ( not HealthService:IsAlive( entity ) ) then
			goto continueBuilding
		end

		local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
		if ( buildingComponent == nil ) then
			goto continueBuilding
		end

		local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
		if ( mode ~= BM_COMPLETED ) then
			goto continueBuilding
		end
			
		local health = HealthService:GetHealthInPercentage( entity )
		if ( health < 1 ) then

			HealthService:AddHealthInPercentage( entity, self.amount )

			EffectService:SpawnEffect( entity, "effects/buildings_generic/building_repair_big" )
		else

			local database = EntityService:GetDatabase( entity )

			if ( database and database:HasInt("number_of_activations")) then

				local currentNumberOfActivations =  database:GetInt("number_of_activations")

				local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )

				local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")
		
				if ( currentNumberOfActivations < maxNumberOfActivations ) then

					currentNumberOfActivations = currentNumberOfActivations + math.floor( maxNumberOfActivations * self.amount / 100  )

					currentNumberOfActivations = math.min( currentNumberOfActivations, maxNumberOfActivations )

					database:SetInt("number_of_activations", currentNumberOfActivations)

					EffectService:SpawnEffect( entity, "effects/buildings_generic/building_repair_big" )
				end
			end
		end

		::continueBuilding::
	end
end

return potion
