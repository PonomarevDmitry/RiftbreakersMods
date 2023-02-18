class 'spawn_nest' ( LuaGraphNode )
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

function spawn_nest:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_nest:init()
    local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_nest"
	end
    if ( self.data:HasString("marker_name")) then
		self.marker_name = self.data:GetString("marker_name")
		Remove(blueprints, "marker_name")
	else
		self.marker_name = "spawn_nest_marker"
	end
	local random = RandInt(1,#blueprints)
	self.nestBP = self.data:GetString( blueprints[random])
    self.spawnCount = self.data:GetIntOrDefault( "spawn_count", 1)
end

function spawn_nest:Activated()
    LogService:Log(tostring(self.spawnCount))

	local objectiveSpawn = FindObjectiveSpot()	
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		QueueEvent( "LuaGlobalEvent", event_sink, "SpawnFailed" , {})	
	else		
	    local spots = FindAllAvailableObjectiveSpots()
        local centerPos = EntityService:GetPosition( objectiveSpawn )

        local predicate = function( t, lhs, rhs )
                    local p1 = EntityService:GetPosition(lhs )
                    local p2 = EntityService:GetPosition(rhs )
                    local d1 = Distance( centerPos, p1 )
                    local d2 = Distance( centerPos, p2 )
                return d1 < d2 
            end 
        local counter = 0
        LogService:Log("SpawnStart")
        for item in SortedIter( spots, predicate ) do
            counter = counter + 1
            LogService:Log("Spawning " .. tostring(counter ))
            
            self.nest = EntityService:SpawnEntity( self.nestBP, item, "enemy" )
            if EntityService:GetComponent(self.nest, "NavMeshMovementComponent") == nil then
                EntityService:RemovePropsInEntityBounds( self.nest );
            end

            EntityService:SetGroup( self.nest, "objective" )	
            EntityService:SetName( self.nest, self.name )	
            
            self.marker = EntityService:SpawnAndAttachEntity( "effects/messages_and_markers/objective_marker_red", self.nest )	
            EntityService:SetName( self.marker, self.marker_name )

            if ( counter >= self.spawnCount ) then
                break
            end
        end
        LogService:Log("SpawnEnd")

        if ( counter > 0 ) then
            QueueEvent( "LuaGlobalEvent", event_sink, "SpawnSuccessful", {} )
        end

	end
	
end

return spawn_nest