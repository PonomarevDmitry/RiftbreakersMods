class 'camera_culling' ( LuaEntityObject )
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")

function camera_culling:__init()
	LuaEntityObject.__init(self, self)
end

function camera_culling:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )

    self.cullerDistance = self.data:GetFloatOrDefault( "culler_distance", 30 )
    self.lookAtTarget = self.data:GetIntOrDefault( "look_at_target", 1 )
    self.markChildren = self.data:GetIntOrDefault( "mark_children", 0 )
    self.checkPivot = self.data:GetIntOrDefault( "check_pivot", 0 )
    self.checkPivotThreshold = self.data:GetFloatOrDefault( "check_pivot_threshold", 10 )
    self.checkChildPivot = self.data:GetIntOrDefault( "check_child_pivot", 0 )
    self.checkChildPivotThreshold = self.data:GetFloatOrDefault( "check_child_pivot_threshold", 10 )
    self.cullerScreenSize = self.data:GetFloatOrDefault( "culler_screen_size", 0.5 )
    self.followParent = self.data:GetIntOrDefault( "follow_parent", 0 )
	self.parentId = INVALID_ID

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "mech", { from="*", enter="OnEnter", execute="OnExecute" } )
	self.sm:ChangeState( "mech" )

	self.culledEntities = {}
end

function camera_culling:OnLoad()
	self.culledEntities = self.culledEntities or {}
end

function camera_culling:EnableCameraCulling( owner, entity, enable )
	local culledEntities = self.culledEntities[ owner ] or {}

	if enable then
		if IndexOf( culledEntities, entity ) ~= nil then return end

		QueueEvent( "EnableCameraCulling", entity, self.entity )
		table.insert( culledEntities, entity )

		self.culledEntities[ owner ] = culledEntities
	else
		for culledEntity in Iter(culledEntities) do
			QueueEvent( "DisableCameraCulling", culledEntity, self.entity )
		end

		self.culledEntities[ owner ] = nil
	end
end

function camera_culling:OnEnteredTriggerEvent( evt )
	local entity = evt:GetOtherEntity()
	if self.checkPivot == 1 then 
		if EntityService:IsAlive( entity ) then
			local pos = EntityService:GetPosition( entity )
			if pos.y < self.checkPivotThreshold then
				return
			end
		end
	end

	self:EnableCameraCulling( entity, entity, true )

    if self.markChildren == 1 then
		local children = EntityService:GetChildren( entity, false )
		for child in Iter( children ) do
			if self.checkChildPivot == 1 then 
				if EntityService:IsAlive( child ) then
					local pos = EntityService:GetPosition( child )
					if pos.y >= self.checkChildPivotThreshold then
						self:EnableCameraCulling( entity, child, true )
					end
				end
			else
				self:EnableCameraCulling( entity, child, true )
			end
		end
	end
end

function camera_culling:OnLeftTriggerEvent( evt )
	local entity = evt:GetOtherEntity()
	self:EnableCameraCulling( entity, entity, false )
end

function camera_culling:OnEnter( state )
end

function camera_culling:OnExecute( state )
	local cameraId = CameraService:GetActiveCamera()
	if cameraId == INVALID_ID then
		return
	end

	if self.parentId == INVALID_ID then
	    self.parentId = EntityService:GetParent( self.entity )
		EntityService:DetachEntity( self.entity )
	end

	local targetId = INVALID_ID
    if self.followParent == 1 then
    	targetId = self.parentId
    else
		targetId = CameraService:GetFollowTarget( cameraId )
	end	

	if EntityService:IsAlive( self.parentId ) == false then
		QueueEvent( "ClearCameraCulling", self.entity )
		EntityService:RemoveEntity( self.entity )
		return
	end

	if EntityService:IsAlive( targetId ) == false or EntityService:IsAlive( cameraId ) == false then
		return
	end

	local cameraPos = EntityService:GetPosition( cameraId )
	local targetPos = EntityService:GetPosition( targetId )

	local targetScreenPos = CameraService:GetScreenCoords( targetPos )
	EntityService:SetGraphicsUniform( self.entity, "cQuadData", targetScreenPos.x, targetScreenPos.y, 0.0, self.cullerScreenSize )

	local diff = VectorSub( targetPos, cameraPos )
	local distance = Length( diff )
	local height = diff.y
	local cosAlpha = height / distance
	local distanceOffset = ( -10 / cosAlpha ) - 11.5
	local dir =  VectorMulByNumber( diff, 1.0 / distance )
	local offset = VectorMulByNumber( dir, -self.cullerDistance - distanceOffset  )
    local pos = VectorAdd( targetPos, offset )

   	EntityService:SetWorldPosition( self.entity, pos ) 

    if self.lookAtTarget == 1 then
       	EntityService:SetForward( self.entity, dir.x, dir.y, dir.z )
    else
    	dir.y = 0
    	dir = Normalize( dir )
    	EntityService:SetForward( self.entity, dir.x, dir.y, dir.z )
    end
end

return camera_culling