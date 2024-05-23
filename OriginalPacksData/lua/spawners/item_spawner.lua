

class 'item_spawner' ( LuaEntityObject )
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/item_utils.lua")

function item_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function item_spawner:init()
	
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent",  "OnLeftTriggerEvent" )

    self.cooldown = self.data:GetFloatOrDefault("cooldown", 0)
    self.ammoCount = self.data:GetIntOrDefault("ammo_count", 0)
    self.unique = self.data:GetIntOrDefault("unique", 1)
    local blueprints = self.data:GetString("blueprint")
	self.blueprintsList = Split( blueprints, "," )	
    self.mechsInside = {}
    self.activated = false

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "creation", {  enter="OnCreationStart", exit="OnCreationEnd", execute="OnCreationExecute" } )
	self.fsm:AddState( "idle", {  execute="OnIdleExecute" } )
    self.fsm:ChangeState( "creation" )

end

function item_spawner:GatherBlueprintData()
    local randomBlueprintId = RandInt(1, #self.blueprintsList )
    self.blueprint = self.blueprintsList[randomBlueprintId]

    local blueprintResource = ResourceManager:GetBlueprint( self.blueprint )

    if (not Assert(blueprintResource ~= nil, "ERROR: Resource blueprint for pickup is invalid!")  ) then
        return
    end 

    local inventoryItemComponent = blueprintResource:GetComponent( "InventoryItemComponent" )
    local inventoryItemComponentHelper = reflection_helper( inventoryItemComponent )
    self.modelBp = inventoryItemComponentHelper.item_bp
    if (not Assert(self.modelBp ~= nil, "ERROR: Resource blueprint for pickup is invliad!")  ) then
        self.modelBp = "effects/loot/mod_standard_idle"
    end

    local weaponItemDesc = blueprintResource:GetComponent( "WeaponItemDesc" )
    if (weaponItemDesc) then
        local weaponItemDescHelper = reflection_helper( weaponItemDesc )
        self.ammoStorage = weaponItemDescHelper.ammo_storage
    end
end

function item_spawner:OnCreationStart( state)
    state:SetDurationLimit( self.cooldown )
        
    self:GatherBlueprintData()
    self.model = EntityService:SpawnAndAttachEntity( self.modelBp, self.entity )
    EntityService:SetPosition( self.model, 0.0, 3.0, 0.0 )
    EffectService:DestroyEffectsByGroup( self.model, "laser_pointer")
    EntityService:ChangeMaterial( self.model, "selector/hologram_blue_dissolve")
    
    EntityService:RemoveComponent( self.model, "MinimapItemComponent")
    EntityService:FadeEntity( self.model, DD_FADE_IN, self.cooldown )
end

function item_spawner:OnCreationExecute( state, dt)
    EntityService:Rotate( self.model, 0.0, 1.0, 0.0, dt * 15)
end

function item_spawner:OnCreationEnd( state)
    self.activated = true
    EntityService:DissolveEntity( self.model, 1.0 )
    self.model = EntityService:SpawnAndAttachEntity( self.blueprint, self.entity )
    EntityService:SetPosition( self.model, 0.0, 3.0, 0.0 )
    --EffectService:DestroyEffectsByGroup( self.model, "laser_pointer")
    --EntityService:FadeEntity( self.model, DD_FADE_IN, 0.5 )
    --EntityService:SetScale( self.model, 1.4, 1.4, 1.4 )
    self.fsm:ChangeState( "idle" )
end

function item_spawner:OnIdleExecute( state, dt)
    EntityService:Rotate( self.model, 0.0, 1.0, 0.0, dt * 15)

    if ( self.activated == true and #self.mechsInside > 0 ) then
        self:AddItem( self.mechsInside[1])
    end
end

function item_spawner:OnEnteredTriggerEvent(evt)
    Insert( self.mechsInside, evt:GetOtherEntity() )
    if ( self.activated == true ) then
        self:AddItem( self.mechsInside[1])
    end
end

function item_spawner:OnLeftTriggerEvent(evt)
    Remove( self.mechsInside, evt:GetOtherEntity() )
end

function item_spawner:AddItem( mech )
    self.activated = false
    --EffectService:SpawnEffects(self.model, "loot_collect" )
    local player  = PlayerService:GetPlayerForEntity( mech )

    --if (self.unique == false or PlayerService:HasItem( player, self.blueprint ) == false ) then
    --    local item = PlayerService:AddItemToInventory( player, self.blueprint )
    --    TryEquipItemOnSlot(player, item )
    --end

    if ( self.ammoStorage ~= nil) then
        local ammoResource = ResourceManager:GetResource("GameplayResourceDef", self.ammoStorage)
        if ( ammoResource ~= nil ) then
            local ammoResourceHelper = reflection_helper( ammoResource )
            PlayerService:AddResourceAmount(player, self.ammoStorage , self.ammoCount * ammoResourceHelper.production, false )
        end	
    end

    --EntityService:DissolveEntity( self.model, 0.2 )
    self.model = nil
    self.fsm:ChangeState( "creation" )
end


return item_spawner
