class 'mining_elevator_ghost' ( LuaEntityObject )

function mining_elevator_ghost:__init()
	LuaEntityObject.__init(self,self)
end

function mining_elevator_ghost:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "check", { from="*", execute="OnCheckExecute", interval=1 } )
    self.sm:ChangeState("check")
end

function mining_elevator_ghost:OnCheckExecute()
    
   local entities =  FindService:FindEntitiesByTypeInRadius( self.entity , "player", 10)

   if (#entities == 0 ) then
        return
   end
   
   local mech = entities[1] 
   local children = EntityService:GetChildren( self.entity, true )
   for child in Iter(children ) do
       if ( EntityService:GetComponent(child, "GuiComponent") ~= nil ) then
           self.infoChild = child
       end
   end 

   if ( self.infoChild == nil ) then
        return
   end
   local player = PlayerService:GetPlayerByMech( mech )
   local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
   if ( onScreen ) then
       BuildingService:OperateUpgradeCosts( self.infoChild, player, self.repairCosts)
   else
       BuildingService:OperateUpgradeCosts( self.infoChild , player,{})
   end
end


function mining_elevator_ghost:OnInteractWithEntityRequest( evt )

    local blueprint = "buildings/dmain/mining_elevator";
    local player = PlayerService:GetPlayerByMech( evt:GetOwner() )
    --local list = BuildingService:GetBuildCosts( blueprint )
    --local entity = PlayerService:GetPlayerSelector( player )
--
    --QueueEvent( "ChangeBuildingRequest", entity, "mining_elevator" );
    --QueueEvent( "ChangeSelectorModeRequest", entity, 1 );
--
    if ( BuildingService:CanAffordBuilding( blueprint, player )) then
        local transform = EntityService:GetWorldTransform( self.entity )
        QueueEvent("ForceBuildBuildingRequest", INVALID_ID, player, blueprint, transform, true )
        EntityService:RemoveEntity( self.entity )
    end
end


return mining_elevator_ghost