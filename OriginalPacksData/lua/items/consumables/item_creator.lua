local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")

class 'item_creator' ( item )

function item_creator:__init()
	item.__init(self,self)
end

function item_creator:OnInit()
	self:FillInitialParams()
end

function item_creator:OnEquipped()
end

function item_creator:OnActivate()
	local spot = self:FindAndCheckAimPosition()
	local spawned = EntityService:SpawnEntity( self.bp, spot, EntityService:GetTeam( self.owner ))

	if ( self.ownerAimDir ) then
		local dir = nil
		local mechComponent = EntityService:GetComponent( self.owner, "MechMovementComponent" )
		if ( mechComponent ~= nil ) then
			local startPos = EntityService:GetPosition( self.owner, self.att )
		    local helper = reflection_helper( mechComponent )
            local endPos = helper.weapon_look_point
            dir = VectorSub( endPos, startPos )
        else
        	dir = EntityService:GetForward( self.owner )
        end

		if Length( dir ) > 0.0 then
			EntityService:SetForward( spawned, dir.x, 0, dir.z )
		end
	end

	if ( self.dissolveProps ) then
		EntityService:RemovePropsInEntityBounds(spawned)
	end
	EntityService:FadeEntity( spawned, DD_FADE_IN, 1.0 )
	ItemService:SetItemCreator( spawned, self.bp)
	EntityService:PropagateEntityOwner( spawned, self.owner )
end

function item_creator:FillInitialParams()
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
end

function item_creator:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end


function item_creator:FindAndCheckAimPosition( )
    local pos = {}
	if ( self.createAtAim ) then
		local mechComponent = EntityService:GetComponent(self.owner, "MechMovementComponent" )
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
function item_creator:HasSpot( )
    local positionToCheck = self:FindAndCheckAimPosition()
    return FindService:FindEmptySpotInRadius( positionToCheck, 2.0, "", "").first
end

function item_creator:CanActivate()
	item.CanActivate( self )
	if ( self.checkEmptySpot == false ) then
		self:SetCanActivate( true )
		return true
	end
    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
		self:SetCanActivate( false )
        return false
    end
	local hasSpot = self:HasSpot()
	self:SetCanActivate( hasSpot )
	return hasSpot
end

return item_creator
