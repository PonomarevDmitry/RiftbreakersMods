require("lua/utils/table_utils.lua")
require("lua/buildings/building_base.lua");
local building = require("lua/buildings/building.lua")


class 'stealth_gen_II' ( building )

function stealth_gen_II:__init()
	building.__init(self,self)
end

function stealth_gen_II:OnInit()
	self.active = true
	self.selected = {}
	-- Defaults:
	self.interval = 1
	self.radius = 30

	self.radius = self.data:GetFloatOrDefault("radius", 6)
	self.interval = self.data:GetFloatOrDefault("interval", 1)

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "idle", {execute="OnWorkInProgress",exit="OnWorkExit", interval=self.interval} )
	self.fsm:AddState( "working", {execute="OnWorkInProgress",exit="OnWorkExit", interval=self.interval} )
	--self.fsm:ChangeState("idle")
end

local function can_go_invisible( entity )
		local result = EntityService:GetType( entity )
		if EntityService:CompareType( entity, "wall|tower" ) then
			return false
		else
			return true
		end
end

function stealth_gen_II:OnWorkInProgress( state )

	local objects = FindService:FindEntitiesByTypeInRadius( self.entity, "building", self.radius )

	for i = 1, #objects do
		if( IndexOf( self.selected, objects[i] ) == nil and BuildingService:IsBuildingFinished( objects[i] ) )
		then
			if (can_go_invisible(objects[i]) ~= false) then
				ItemService:SetInvisible( objects[i], true )
				Insert( self.selected, objects[i] )
			end
		end
	end

	for i = #self.selected,1,-1  do
		if( IndexOf( objects, self.selected[i] ) == nil ) then
			ItemService:SetInvisible( self.selected[i], false )
			Remove( self.selected, self.selected[i] )
		end
	end
end

function stealth_gen_II:OnWorkExit( state )
	for i = #self.selected,1,-1  do
		--if (self.selected[i] ~= nil ) then
			ItemService:SetInvisible( self.selected[i], false )
		--end
	end
	Clear( self.selected )
end

function stealth_gen_II:OnSell()
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end
end

function stealth_gen_II:OnBuildingEnd()
end

function stealth_gen_II:OnActivate()
	self.fsm:ChangeState("working")
end

function stealth_gen_II:OnDeactivate()
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end
end

return stealth_gen_II
