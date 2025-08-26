local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_cascade' ( base_skill )

function skill_cascade:__init()
	base_skill.__init(self, self)
end

function skill_cascade:OnInit()
	self.cascadeBp			= self.data:GetString( "cascade_bp" )
	self.warningBp		    = self.data:GetString( "warning_bp" )
	self.warningRadius	    = self.data:GetFloat( "warning_radius" )
	self.spawnMinTime	    = self.data:GetFloat( "spawn_min_time" )
	self.spawnMaxTime	    = self.data:GetFloat( "spawn_max_time" )
	self.wanderStrength	    = self.data:GetFloat( "wander_strength" )
	self.cascadeStepDelay	= self.data:GetFloat( "cascade_step_delay" )
	self.spawnEntityDelay	= self.data:GetFloat( "spawn_entity_delay" )
	self.radius				= self.data:GetFloat( "radius" )
	self.stepSize			= self.data:GetFloat( "step_size" )
	self.cascadeCount	    = self.data:GetInt( "cascade_count" )	
	self.angle				= self.data:GetInt( "angle" )	

    self.spawnerWarning = self:CreateStateMachine()
    self.spawnerWarning:AddState( "spawn_warning", { execute="OnExecuteSpawnWarning" } )

	self.spawnerCascade = self:CreateStateMachine()
	self.spawnerCascade:AddState( "spawn_cascade", { execute="OnExecuteSpawnCascade" } )

	self.spawnerDelay = self:CreateStateMachine()
	self.spawnerDelay:AddState( "spawn_delays", { execute="OnExecuteSpawnDelay" } )

	self.spawnTimer = 0.0

	self.cascade = {}
	self.delays = {}
	self.warningEnts = {}
end

function skill_cascade:SetSpawnTime()
	self.spawnTimer = RandFloat( self.spawnMinTime, self.spawnMaxTime );
end

function skill_cascade:IsDistinctEnough( newNumber, existingNumbers, minDifference )
    for _, num in ipairs( existingNumbers ) do
        if math.abs( newNumber - num ) < minDifference then
            return false
        end
    end
    return true
end

function skill_cascade:GenerateUniqueDelays( count )
    
	local minDifference = ( self.delayOffset / count ) / 2.0

	local numbers = {}
    while #numbers < count do
        local newNumber
        repeat
            newNumber = RandFloat( 0.0, self.delayOffset )
        until self:IsDistinctEnough( newNumber, numbers, minDifference )
        table.insert( numbers, newNumber )
    end
    return numbers
end

function skill_cascade:SimulateCascadeOrigins( startOrigin, direction, wanderStrength, maxRadius, stepSize )
    local cascadeOrigins = {}
    
	local origin = startOrigin

	local steps = maxRadius / stepSize

    for i = 1, steps do

        local angleChange = ( math.random() - 0.5 ) * wanderStrength
        local cosAngle = math.cos( angleChange )
        local sinAngle = math.sin( angleChange )

		local newDirection = {}
		newDirection.x = direction.x * cosAngle - direction.z * sinAngle
		newDirection.y = direction.y
		newDirection.z = direction.x * sinAngle + direction.z * cosAngle
		newDirection = Normalize( newDirection )
        newDirection = VectorMulByNumber( newDirection, stepSize )

		origin = VectorAdd( origin, newDirection )

        if ( Distance( origin, startOrigin ) <= maxRadius  )then
            table.insert( cascadeOrigins, { x = origin.x, y = origin.y, z = origin.z })
        else
            break
        end
    end

    return cascadeOrigins
end

function skill_cascade:SolveCollisions( allCascadeOrigins, minDistance, iterations )

    local adjustedOrigins = {}

    for i = 1, #allCascadeOrigins do
        adjustedOrigins[i] = {}

        for j = 1, #allCascadeOrigins[i] do
            local origin = allCascadeOrigins[i][j]
            table.insert( adjustedOrigins[i], { x = origin.x, y = origin.y, z = origin.z } )
        end
    end


    for iter = 1, iterations do
        for i = 1, #adjustedOrigins do
            for j = 1, #adjustedOrigins[i] do
                local currentOrigin = adjustedOrigins[i][j]

                for k = i, #adjustedOrigins do
                    local startIdx = (k == i) and (j + 1) or 1
                    for l = startIdx, #adjustedOrigins[k] do
                        local compareOrigin = adjustedOrigins[k][l]

                        local dist = Distance(currentOrigin, compareOrigin)

                        if dist < minDistance then
                            local moveDir = Normalize(
							{
                                x = compareOrigin.x - currentOrigin.x,
                                y = compareOrigin.y - currentOrigin.y,
                                z = compareOrigin.z - currentOrigin.z
                            })

                            local moveAmount = (minDistance - dist) / 2

                            currentOrigin.x = currentOrigin.x - moveDir.x * moveAmount
                            currentOrigin.y = currentOrigin.y - moveDir.y * moveAmount
                            currentOrigin.z = currentOrigin.z - moveDir.z * moveAmount

                            compareOrigin.x = compareOrigin.x + moveDir.x * moveAmount
                            compareOrigin.y = compareOrigin.y + moveDir.y * moveAmount
                            compareOrigin.z = compareOrigin.z + moveDir.z * moveAmount
                        end
                    end
                end
            end
        end
    end

    return adjustedOrigins
end

function skill_cascade:OnExecuteSpawnWarning( state, dt )
	self.spawnTimer = self.spawnTimer - dt

	if ( self.spawnTimer <= 0.0 ) then

		if ( self.currentTarget ~= INVALID_ID ) then
			
			self:SetSpawnTime()	

			local myOrigin = EntityService:GetPosition( self.entity )
			local targetOrigin = EntityService:GetPosition( self.currentTarget )

			local dir = VectorSub( targetOrigin, myOrigin )
			dir = Normalize( dir )

			local size = EntityService:GetBoundsSize( EntityService:GetParent( self.entity ) )
			local velocity = UnitService:GetCurrentVelocity( EntityService:GetParent( self.entity ) )
			
			size.y = 0

			local offset = VectorMulByNumber( dir, ( Length( size ) * 0.15 ) + ( Length( velocity ) * 0.3 ) )
			local originForward = VectorAdd( myOrigin, offset )

			local forwardAngle = math.atan2( dir.z, dir.x )
			local halfConeAngle = math.rad( self.angle / 2 ) 

			local allCascadeOrigins = {}

			for i = 1, self.cascadeCount do

				if self.cascadeCount == 1 then
					angle = forwardAngle
				else
					local fraction = ( i - 1) / ( self.cascadeCount - 1 )
					local offset = halfConeAngle * ( fraction * 2 - 1 )

					if self.angle > 180 then
						offset = math.rad(i * 360 / self.cascadeCount)
					end

					angle = forwardAngle + offset
				end

				local rotatedDir = 
				{
					x = math.cos( angle ),
					y = dir.y,
					z = math.sin( angle )
				}

				local angleOrigin = 
				{
					x = originForward.x + rotatedDir.x,
					y = originForward.y,
					z = originForward.z + rotatedDir.z
				}

				local cascadeOrigins = self:SimulateCascadeOrigins( angleOrigin, rotatedDir, self.wanderStrength, self.radius, self.stepSize )        
                table.insert( allCascadeOrigins, cascadeOrigins )

			end

           local adjustedCascadeOrigins = self:SolveCollisions(allCascadeOrigins, self.warningRadius * 2, 10)

            for i = 1, #adjustedCascadeOrigins do
                local cascadeOrigins = adjustedCascadeOrigins[i]
                for k = 1, #cascadeOrigins do
                    local origin = cascadeOrigins[k]

                    local delayData = {}
                    delayData.origin = origin
                    delayData.spawnTimer = self.spawnEntityDelay
                    delayData.delay = (k * self.cascadeStepDelay)

                    table.insert(self.delays, delayData)
                end
            end

		end

	
	end

end

function skill_cascade:OnExecuteSpawnDelay( state, dt )
	for i = #self.delays, 1, -1  do 
		self.delays[i].delay = self.delays[i].delay - dt

		if ( self.delays[i].delay <= 0.0 ) then
			
			local delayData = self.delays[i]

			local marker = WeaponService:SpawnDangerMarker( self.warningBp, delayData.origin, self.warningRadius, delayData.spawnTimer )

			table.insert( self.warningEnts, marker )

			local cascadeData = {}
			cascadeData.origin = delayData.origin
			cascadeData.spawnTimer = delayData.spawnTimer

			table.remove( self.delays, i )

			table.insert( self.cascade, cascadeData )		
		end
	end
end

function skill_cascade:CleanMarkers()
	for i, entity in ipairs(self.warningEnts) do
	
		if ( EntityService:IsAlive( entity ) == true ) then 
		EntityService:RemoveEntity( entity )
		end
	end
	self.warningEnts = {} 
end

function skill_cascade:OnExecuteSpawnCascade( state, dt )
	for i = #self.cascade, 1, -1  do 
		self.cascade[i].spawnTimer = self.cascade[i].spawnTimer - dt

		if ( self.cascade[i].spawnTimer <= 0.0 ) then
			local origin = self.cascade[i].origin
			local entity = EntityService:SpawnEntity( self.cascadeBp, origin.x, origin.y, origin.z, "" )
			EntityService:SetTeam( entity, EntityService:GetTeam( self.entity ) )

			table.remove( self.cascade, i )
		end
	end
end

function skill_cascade:StopSpawner( spawner )
	local state  = spawner:GetState( spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end


function skill_cascade:OnUnitAggressiveStateEvent( evt )
	self.spawnerWarning:ChangeState( "spawn_warning" )
	self.spawnerCascade:ChangeState( "spawn_cascade" )
	self.spawnerDelay:ChangeState( "spawn_delays" )

	self:SetSpawnTime()

	self:CleanMarkers()

	self.cascade = {}
	self.delays = {}
end

function skill_cascade:OnUnitNotAggressiveStateEvent( evt )
	self:StopSpawner( self.spawnerWarning )
	self:StopSpawner( self.spawnerCascade )
	self:StopSpawner( self.spawnerDelay )
end

function skill_cascade:OnUnitDeadStateEvent( evt )
	self:CleanMarkers()
	EntityService:RemoveEntity( self.entity )
end

return skill_cascade