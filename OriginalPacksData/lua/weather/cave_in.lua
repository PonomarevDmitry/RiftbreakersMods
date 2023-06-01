require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

class 'cave_in' ( LuaEntityObject )

function cave_in:__init()
	LuaEntityObject.__init(self, self)
end

function cave_in:init()
	self.radius = self.data:GetFloatOrDefault("radius", 10.0);
	self.duration = self.data:GetFloatOrDefault("duration", 5.0);

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("collapse", { enter = "OnCollapseEnter", execute ="OnCollapseExecute", interval = 0.1 })

	local blueprint = self.data:GetStringOrDefault("volume_blueprint", "props/special/destructible_rocks/cavern_wall")
	self.volume = EntityService:SpawnEntity(blueprint, self.entity, "")

	local min =
	{
		x = -self.radius,
		y = 0.0,
		z = -self.radius
	};

	local max =
	{
		x = self.radius,
		y = 10.0,
		z = self.radius
	};

	EntityService:CreateBoundsComponent(self.volume, min, max)

	local state = self.fsm:ChangeState("collapse")

	self:OnCollapseEnter(state);
end

function cave_in:OnCollapseEnter(state)
	state:SetDurationLimit(self.duration)

	self:OnCollapseExecute(state)
end

function cave_in:OnCollapseExecute(state)
	local progress = state:GetDuration() / state:GetDurationLimit()
	local radius = math.max( 2.0, self.radius * progress )
	QueueEvent("DestructibleVolumeCullCellsInRadiusRequest", self.volume, radius)
end

function cave_in:OnRelease()
	GuiService:RemoveMinimapMarker( tostring( self.entity ) )
end

return cave_in