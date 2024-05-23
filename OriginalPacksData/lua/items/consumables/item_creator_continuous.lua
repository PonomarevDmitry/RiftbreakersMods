local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")

class 'item_creator_continuous' ( item )

function item_creator_continuous:__init()
	item.__init(self,self)
end

function item_creator_continuous:OnInit()
	self:FillInitialParams()
end

function item_creator_continuous:OnEquipped()
    self.spawned = nil
end

function item_creator_continuous:OnActivate()
    local spot = self:FindAndCheckAimPosition()
    if ( self.spawned == nil ) then
	    self.spawned = EntityService:SpawnEntity( self.ghostBp, spot, EntityService:GetTeam( self.owner ))

	    if ( self.ownerAimDir ) then
	    	local position = EntityService:GetPosition( self.owner )
	    	local dir = VectorSub( spot, position)
	    	EntityService:SetForward( self.spawned, dir.x, dir.y, dir.z )
	    end

        return
    end

    if ( self.lastCanActivate ~= self.canActivate ) then
        if ( self.canActivate ) then
            EntityService:ChangeMaterial( self.spawned, "selector/hologram_blue") 
        else
            EntityService:ChangeMaterial( self.spawned, "selector/hologram_red") 
        end
        self.lastCanActivate = self.canActivate;
    end

    EntityService:SetPosition( self.spawned, spot.x, spot.y, spot.z )
    if ( self.ownerAimDir ) then
		local position = EntityService:GetPosition( self.owner )
		local dir = VectorSub( spot, position)
		EntityService:SetForward( self.spawned, dir.x, dir.y, dir.z )
	end

end
function item_creator_continuous:BringBackUseCount()
    local inventoryItemComponent = reflection_helper(EntityService:GetComponent( self.entity, "InventoryItemRuntimeDataComponent"))
    inventoryItemComponent.use_count = inventoryItemComponent.use_count + 1
end

function item_creator_continuous:OnDeactivate()
    if ( self.spawned ~= nil ) then
        EntityService:RemoveEntity( self.spawned )
        self.spawned = nil
    end
    if ( self.canActivate == false ) then
        self:BringBackUseCount()
        return true
    end

    local spot = self:FindAndCheckAimPosition()

    local spawned = EntityService:SpawnEntity( spot ) 

	if ( self.ownerAimDir ) then
		local position = EntityService:GetPosition( self.owner )
		local dir = VectorSub( spot, position)
		EntityService:SetForward( spawned, dir.x, dir.y, dir.z )
	end

    EntityService:SetTeam( spawned, EntityService:GetTeam(EntityService:GetTeam( self.owner ) ) )
    EntityService:UnpackEntity( spawned, self.bp )


	if ( self.dissolveProps ) then
		EntityService:RemovePropsInEntityBounds(spawned)
	end
	EntityService:FadeEntity( spawned, DD_FADE_IN, 1.0 )
	ItemService:SetItemCreator( spawned, self.bp)
	EntityService:PropagateEntityOwner( spawned, self.owner )

    return true
end

function item_creator_continuous:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetString( "bp" )
    self.ghostBp = database:GetStringOrDefault( "ghost_bp", "" )
	self.att = database:GetStringOrDefault( "att", "" )
	self.dissolveTime = database:GetFloatOrDefault( "dissolve", 0.5 )
	self.maxDistance = database:GetFloatOrDefault( "max_distance", -1.0 )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 ) == 1
	self.ownerAimDir = database:GetIntOrDefault("owner_aim_dir", 0) == 1
	self.createAtAim = database:GetIntOrDefault("create_at_aim_pos", 0) == 1
	self.dissolveProps = database:GetIntOrDefault("dissolve_props", 0) == 1
    self.canActivate = true
end

function  item_creator_continuous:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function item_creator_continuous:HasSpot( )
    local positionToCheck = self:FindAndCheckAimPosition()
    return FindService:FindEmptySpotInRadius( positionToCheck, 2.0, "", "").first
end

function item_creator_continuous:FindAndCheckAimPosition( )
    local pos = {}
	if ( self.createAtAim ) then
		local mechComponent = EntityService:GetComponent(self.owner, "MechComponent" )
		if ( mechComponent == nil ) then
			pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "").second
        else
		    local helper = reflection_helper( mechComponent )
            pos = helper.weapon_look_point
        end
	else
		if ( self.checkEmptySpot == false ) then
			pos = EntityService:GetPosition( self.owner, self.att )
		else
    		pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "").second
    	end	
    end

    if ( self.maxDistance < 0 ) then
        return pos
    end

    local position = EntityService:GetPosition( self.owner )
    local dir = VectorSub( pos, position)
    local length = Length(dir)
    if ( length <= self.maxDistance ) then
        return pos
    end

    dir = Normalize(dir)
    dir = VectorMulByNumber( dir, self.maxDistance)
    return VectorAdd( position ,dir)
end

function item_creator_continuous:CanActivate()
    self.canActivate = true
	item.CanActivate( self )
	if ( self.checkEmptySpot == false ) then
		return true
	end
    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        self.canActivate = false
        return false
    end

    self.canActivate = self:HasSpot()
    return self.canActivate or self:IsActivated() 
end

return item_creator_continuous
