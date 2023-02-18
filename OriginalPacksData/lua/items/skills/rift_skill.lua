require("lua/utils/table_utils.lua")
require("lua/utils/serialize_utils.lua")
require("lua/utils/numeric_utils.lua")

local item = require("lua/items/item.lua")

class 'rift_skill' ( item )

function rift_skill:__init()
	item.__init(self)
end

function rift_skill:OnInit()
    self.use_count  = self.data:GetInt( "use_count" )
	if ( self.data:HasString( "rifts" ) ) then
		self.rifts = DeserializeObject( self.data:GetString("rifts") )
	else
		self.rifts = {}
	end

	self.placeSM = self:CreateStateMachine()
	self.placeSM:AddState( "place", { from="*", enter="OnPlaceEnter", execute="OnPlaceExecute",  exit="OnPlaceExit" } )
	
	self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function rift_skill:OnTeleportAppearEnter()
	self.data:SetInt("leaving", 1)
end

function rift_skill:OnTeleportAppearExit()
	self.data:SetInt("leaving", 0)
end


function rift_skill:OnPlaceEnter( state )
	state:SetDurationLimit( 0.75 )
end

function rift_skill:OnPlaceExecute( state )
	local currentProgress = ( state:GetDuration() / 1 )
	EntityService:SetOrientation( self.portalBase, 0, 1, 0, currentProgress * 360 )
	EntityService:SetScale( self.portalBase, 0.5 + currentProgress / 2.0, 0.5 + currentProgress / 2.0, 0.5 + currentProgress / 2.0 )
	EntityService:SetGraphicsUniform( self.portalBase, "cMaxHeight", 1 )
	EntityService:SetGraphicsUniform( self.portalBase, "cDissolveAmount", 1 - currentProgress )
end

function rift_skill:OnPlaceExit( state )

end

function rift_skill:OnEquipped()

end

function rift_skill:OnActivate()
	local x = EntityService:GetPositionX( self.owner ) 
	local y = EntityService:GetPositionY( self.owner ) 
	local z = EntityService:GetPositionZ( self.owner ) 
	
	--LogService:Log( tostring( x ) .. ":" .. tostring( z ) )
	
	x = SnapValue( x, 2.0 )
	z = SnapValue( z, 2.0 )
	
	--LogService:Log( tostring( x ) .. ":" .. tostring( z ) )
	
	local canPlace = ItemService:CanPlace( x, y, z, 2 )
	if ( canPlace == true ) then
		self.portal = EntityService:SpawnEntity( "items/skills/rift_portal", x,y,z, "" )
		self.portalBase = EntityService:SpawnAndAttachEntity( "items/skills/rift_base", self.portal )
		EntityService:SetScale( self.portalBase, 0, 0, 0 )
		self.placeSM:ChangeState("place")

		EntityService:RemovePropsInEntityBounds( self.portal )
		EffectService:AttachEffect( self.portal, "effects/items/portal_idle2" )
		EffectService:AttachEffect( self.portal, "effects/items/rift_placed" )
		Insert( self.rifts, self.portal )
		
		if ( #self.rifts > self.use_count ) then
			local toRemoveEnt = self.rifts[1]
			Remove( self.rifts, toRemoveEnt )
			EntityService:RemoveEntity( toRemoveEnt )	
		end
	else
		EffectService:AttachEffects( self.item, "item_activated_failed" )
	end
end

function rift_skill:OnUnequipped()
	local rifts = SerializeObject( self.rifts )
	--LogService:Log( rifts )
	self.data:SetString("rifts", rifts )
end

return rift_skill
