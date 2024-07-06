local dash = require("lua/items/skills/dash.lua")

class 'dash_proximity_mine' ( dash )

function dash_proximity_mine:__init()
    dash.__init(self,self)
end

function dash_proximity_mine:OnInit()
    if ( dash.OnInit ) then
        dash.OnInit(self)
    end

    self:FillInitialParams()
end

function dash_proximity_mine:OnLoad()
    if ( dash.OnLoad ) then
        dash.OnLoad(self)
    end

    self:FillInitialParams()
end

function dash_proximity_mine:FillInitialParams()

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

function dash_proximity_mine:OnActivate()

    self:SpawnMine()

    if ( dash.OnActivate ) then
        dash.OnActivate(self)
    end
end

function dash_proximity_mine:SpawnMine()

    local spot = self:FindAndCheckAimPosition()

    local spawned = EntityService:SpawnEntity( self.bp, spot, EntityService:GetTeam( self.owner ))

    if ( self.ownerAimDir ) then
        local dir = nil
        local mechComponent = EntityService:GetComponent( self.owner, "MechComponent" )
        if ( mechComponent ~= nil ) then
            local startPos = EntityService:GetPosition( self.owner, self.att )
            local helper = reflection_helper( mechComponent )
            local endPos = helper.weapon_look_point
            dir = VectorSub( endPos, startPos )
        else
            dir = EntityService:GetForward( self.owner )
        end

        if Length( dir ) > 0.0 then
            EntityService:SetForward( spawned, dir.x, dir.y, dir.z )
        end
    end

    if ( self.dissolveProps ) then
        EntityService:RemovePropsInEntityBounds(spawned)
    end

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, self.bp)
    EntityService:PropagateEntityOwner( spawned, self.owner )

    --QueueEvent( "FadeEntityInRequest", spawned, self.dissolveTime )
    EntityService:FadeEntity( spawned, DD_FADE_IN, self.dissolveTime )
end

function dash_proximity_mine:FindAndCheckAimPosition()

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

return dash_proximity_mine