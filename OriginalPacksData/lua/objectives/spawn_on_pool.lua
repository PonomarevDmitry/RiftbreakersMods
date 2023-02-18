class 'spawn_from_pool' ( LuaGraphNode )
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")

function spawn_from_pool:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_from_pool:init()
	local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_from_pool"
	end

	if ( self.data:HasString("veins")) then
		self.veins = Split(self.data:GetString("veins"),",")
		Remove(blueprints, "veins")
	else
		self.veins = {}
	end

	if ( self.data:HasString("specific_type")) then
		self.specific_type = self.data:GetString("specific_type")
		Remove(blueprints, "specific_type")
	else
		self.specific_type = ""
	end
	local random = RandInt(1,#blueprints)
	self.eliteBlueprint = self.data:GetString( blueprints[random])

end

function spawn_from_pool:Activated()
	local objectiveSpawn = self:FindPoolsWithBuildings(self.veins, self.specific_type)	
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		
		QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnFailed" ), {})			
	else
		self.eliteUnit = EntityService:SpawnEntity( self.eliteBlueprint, objectiveSpawn, "enemy" )
		EntityService:SetName( self.eliteUnit, self.name  )	
		EntityService:SetGroup( self.eliteUnit, "objective" )	
		QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnSuccessful" ), {} )
	end
end


function spawn_from_pool:FindPoolsWithBuildings( veins, specificType)
	local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local predicate = {
        signature="ResourceVolumeComponent",
        filter = function(entity)
			local pass = false
            if ( veins ~= nil and #veins ~= 0 ) then
                local resourceName = ResourceService:GetResourceNameFromVein( entity )
                if ( IndexOf(veins, resourceName) ~= nil ) then
                    if ( specificType ~= "") then
                        pass = ResourceService:GetResourceSpecificTypeFromVein( entity ) == specificType;
					else
						pass = true
                    end
                end
            elseif( specificType ~= "") then
                pass = ResourceService:GetResourceSpecificTypeFromVein( entity ) == specificType;
            end

			if ( pass == false ) then
				return pass
			end

			local size = EntityService:GetBoundsSize( entity )
			local radius = Length( size ) / 2.0
			
			local buildings = FindService:FindEntitiesByTypeInRadius( entity, "building", radius )
			return #buildings > 0
        end
    };

	local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );
	if Assert( #entities > 0, "ERROR: no pools in to find ") then
		local randomNumber = RandInt( 1, #entities )			
		wave_start_point = entities[ randomNumber ]
		return wave_start_point;
	end

	return INVALID_ID
end

return spawn_from_pool