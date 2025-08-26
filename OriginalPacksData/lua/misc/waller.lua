class 'waller' ( LuaEntityObject )

function waller:__init()
	LuaEntityObject.__init(self,self)
end

function waller:init()

	self.wallBp = self.data:GetString( "wall_bp" )
	self.sideDistance = self.data:GetFloatOrDefault( "side_distance", 1.0 )
	self.backDistance = self.data:GetFloatOrDefault( "back_distance", 10.0 )
	self.frontDistance = self.data:GetFloatOrDefault( "front_distance", 10.0 )
	self.step = self.data:GetFloatOrDefault( "step", 2.0 )
	self.forward = self.data:GetVector( "forward" )
	self.right = self.data:GetVector( "right" )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "create", { enter="OnCreateEnter" } )
	self.sm:ChangeState( "create" )

end

function waller:TranslatePoints(points, moveMin, moveMax )
    local translatedPoints = {}
    for _, p in ipairs( points ) do
        local moveX = moveMin + math.random() * ( moveMax - moveMin )
        local moveY = moveMin + math.random() * ( moveMax - moveMin )
        table.insert(translatedPoints, {x = p.x + moveX, y = p.y + moveY})
    end
    return translatedPoints
end

function waller:Distance(a, b)
    return math.sqrt( (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) )
end

function waller:GenerateBezierArc(p1, p2, c1, c2, stepDistance)
    local denseArc = {}
    local resultArc = {}

    for t = 0, 1, 0.02 do
        local x = (1 - t) * (1 - t) * (1 - t) * p1.x + 3 * (1 - t) * (1 - t) * t * c1.x + 3 * (1 - t) * t * t * c2.x + t * t * t * p2.x
        local y = (1 - t) * (1 - t) * (1 - t) * p1.y + 3 * (1 - t) * (1 - t) * t * c1.y + 3 * (1 - t) * t * t * c2.y + t * t * t * p2.y
        table.insert( denseArc, {x = x, y = y} )
    end

    local lastPoint = denseArc[1]
    table.insert( resultArc, lastPoint )

    for _, p in ipairs(denseArc) do
        if ( self:Distance( lastPoint, p ) >= stepDistance ) then
            table.insert( resultArc, p )
            lastPoint = p
        end
    end

    return resultArc
end

function waller:OnCreateEnter( state )
	local origin = EntityService:GetPosition( self.entity )

	local undergroundOffset = 4.0; -- remove later

	local backOrigin = VectorSub( origin, VectorMulByNumber( self.forward, self.backDistance ) )

	local upCornerOrigin = VectorAdd( origin, VectorMulByNumber( self.right, self.sideDistance ) )
	local upCornerDownOrigin = VectorSub( origin, VectorMulByNumber( self.right, self.sideDistance ) )


	local upCornerOriginBack = VectorAdd( upCornerOrigin, VectorMulByNumber( self.forward, self.step ) )
	local upCornerDownOriginBack = VectorAdd( upCornerDownOrigin, VectorMulByNumber( self.forward, self.step ) )

	local spawnStepSide = self.sideDistance / self.step
	local spawnStepForward = self.frontDistance / self.step


    local p1 = {x = upCornerOrigin.x, y = upCornerOrigin.z}
    local p2 = {x = upCornerDownOrigin.x, y = upCornerDownOrigin.z}
    local v = {x = backOrigin.x, y = backOrigin.z}

	local c1 = VectorAdd( backOrigin, VectorMulByNumber( self.right, self.sideDistance ) )
	local c2 = VectorSub( backOrigin, VectorMulByNumber( self.right, self.sideDistance ) )

    local points = self:GenerateBezierArc(p1, p2, {x = c1.x, y = c1.z}, {x = c2.x, y = c2.z}, self.step )

	for i = 0, spawnStepForward do 
		local spawnOrigin1 = VectorAdd ( upCornerOriginBack, VectorMulByNumber( self.forward, i * self.step ) )
		local spawnOrigin2 = VectorAdd ( upCornerDownOriginBack, VectorMulByNumber( self.forward, i * self.step ) )
        table.insert(points, {x = spawnOrigin1.x, y = spawnOrigin1.z})
        table.insert(points, {x = spawnOrigin2.x, y = spawnOrigin2.z})
	end

    local translatedPoints = self:TranslatePoints( points, -0.9, 0.9 )

    for _, point in ipairs(translatedPoints) do
        local spawnOrigin = { x = point.x, y = origin.y, z = point.y }

        if ( UnitService:IsOnNavigationStatic( spawnOrigin ) == false ) then
            local wall = EntityService:SpawnEntity( self.wallBp, spawnOrigin.x, spawnOrigin.y - undergroundOffset, spawnOrigin.z, "" )
		    
            local dynamicSpace = UnitService:IsOnNavigationDynamic( spawnOrigin )

            local db = EntityService:GetDatabase( wall )
            db:SetInt( "dynamic_space", dynamicSpace and 1 or 0 )
        end
       
    end
end





return waller
 