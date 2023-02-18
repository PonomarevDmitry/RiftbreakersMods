local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'mini_miner' ( tower )

function mini_miner:__init()
	tower.__init(self,self)
end

function mini_miner:OnInit()
    tower.OnInit(self)
	local spawn_interval= self.data:GetFloatOrDefault("spawn_interval", 0.5)
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", {execute="OnWorkInProgress", interval=spawn_interval} )

end

function mini_miner:OnBuild()
end

function mini_miner:OnActivate()
    tower.OnActivate(self)
	self.fsm:ChangeState("working")
end

function mini_miner:OnDeactivate()
    tower.OnDeactivate(self)
	self.fsm:Deactivate()

end

function mini_miner:OnWorkInProgress()
    local converter = EntityService:GetComponent(self.entity, "ResourceConverterComponent")
    if ( converter == nil ) then
        return
    end
    local converterHelper = reflection_helper(converter)
    local ore = converterHelper.last_ore_produced
    if ( ore == "") then
        return
    end

    local resourceItemBlueprint = ItemService:GetResourceBlueprint( ore )
    local resourceBlueprint = ItemService:GetBlueprintOfItem( resourceItemBlueprint )

    Assert(resourceBlueprint ~= "", "ERROR: Resource blueprint for ore is empty!")
    if ( resourceBlueprint == "" ) then
        return
    end
    
    local position = EntityService:GetPosition( self.entity )
    local size = EntityService:GetBoundsSize( self.entity )
    position.y = position.y + size.y + 0.5
    local shard = ItemService:SpawnLoot( position, resourceBlueprint, 5 , 5000, 6000, "normal" )
    QueueEvent("DissolveEntityRequest", shard, 1.0, 0.1 )
end


return mini_miner
