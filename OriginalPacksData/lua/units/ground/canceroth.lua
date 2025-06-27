require("lua/utils/table_utils.lua")

local swarm = require("lua/units/ground/swarm.lua")
class 'canceroth' ( swarm )

function canceroth:__init()
	swarm.__init(self, self)
end

function canceroth:_OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 0
    self.normalExplodeProbability = 10
	self.leaveBodyProbability = 0

    if self.__OnInit then
        self:__OnInit( evt )
    end
end

function canceroth:_OnExecuteLogic( state, dt )

	local removeChildren = {}

	if ( self.isStunned ~= true ) then

		if ( #self.children < self.childrenCount ) then

			self.createChildTimer = self.createChildTimer - dt

			if ( self.createChildTimer <= 0 ) then

				local child = {}
				child.entity = self:CreateChild()
				child.currentHeight  = 0

				table.insert( self.children, child )
				self.createChildTimer = self.data:GetFloatOrDefault( "create_child_timer", 10.0 )
			end
		end

	end

	local target = UnitService:GetNavMeshMoveToTarget( self.entity )
	local origin = EntityService:GetPosition( self.entity )
	local velocity = UnitService:GetCurrentVelocity( self.entity )

	local originForward = VectorAdd( origin, velocity )

	for i = 1, ( #self.children ) do	
		
		 if ( self._CheckChild ) then
			self:_CheckChild( self.children[i].entity )
		 end

		if ( target ~= INVALID_ID) then
			UnitService:SetNavMeshMoveToOrigin( self.children[i].entity, originForward )
		else
			UnitService:SetNavMeshMoveToTarget( self.children[i].entity, self.entity )
		end
	end
end

return canceroth


