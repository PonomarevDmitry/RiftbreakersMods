local controller = {}

local bp_changes = 0
local bp_fails = 0
local changes = 0
local fails = 0

local creator = true

function controller:MarkChanges( value )
    bp_changes = bp_changes + (value or 1)
end

function controller:GetChanges()
    return string.format( " %d/%d ", bp_changes, bp_changes + bp_fails )
end

function controller:MarkFails( value )
    bp_fails = bp_fails + (value or 1)
end

function controller:ResetChanges()
    changes = changes + bp_changes
    fails = fails + bp_fails
    bp_changes, bp_fails = 0, 0
end

function controller:GetStats()
    return string.format( " %d/%d ", changes, changes + fails )
end

function controller:ResetStats()
    changes, fails = 0, 0
end

function controller:SetCreatorMode( value )
    creator = not not value
end

function controller:IsCreator()
    return creator
end

function controller:RemoveCreatorMode()
    creator = true
end

local patch_content = {
    weapons = {},
    turret = {},
    inventory = {},
    health = {},
    mech = {}
}

function controller:AddToWeaponCheck( t )
    local weapons = patch_content.weapons
    for blueprint in Iter( t ) do
        if not weapons[blueprint] then
            weapons[blueprint] = true
        end
    end
end

function controller:AddToTurretCheck( t )
    local turret = patch_content.turret
    for blueprint in Iter( t ) do
        if not turret[blueprint] then
            turret[blueprint] = true
        end
    end
end

function controller:AddToInvetoryCheck( t )
    local inventory = patch_content.inventory
    for blueprint in Iter( t ) do
        if not inventory[blueprint] then
            inventory[blueprint] = true
        end
    end
end

function controller:AddToHealthCheck( t )
    local health = patch_content.health
    for blueprint in Iter( t ) do
        if not health[blueprint] then
            health[blueprint] = true
        end
    end
end

function controller:AddToMechCheck( evt )

    if type( evt ) ~= "table" then
        local player = evt:GetPlayerId()
        local mech = PlayerService:GetGlobalPlayerEntity( player )
        if mech ~= INVALID_ID then
            patch_content.mech[mech] = true
        end
    else
        -- Console Command
        local mechs = patch_content.mech
        for mech, _ in pairs( evt ) do
            mechs[mech] = true
        end
    end

    local function EnsureMechEquipmentComponentSlots()

        local function GetEquipmentSlotsFrom( entity )
            local component
            if type( entity ) == "string" then
                component = EntityService:GetBlueprintComponent( entity, "EquipmentComponent" )
            else
                component = EntityService:GetComponent( entity, "EquipmentComponent" )
            end

            if not component then
                LogService:Log( ("Fail to get 'EquipmentComponent' from '%s'"):format( tostring( entity ) ) )
                return
            end

            local equipment = divergent_helper( component ).equipment
            for item in IterItems( equipment ) do
                local slots = item.slots
                return slots
            end
        end

        local function AssignContainer( mech, bp, field )
            local bp_container, count = bp[field]:to_container()
            local mech_container = mech[field]:to_container()
            for bp_item in IterItems( bp_container, count ) do
                for mech_item in IterItems( mech_container ) do
                    if mech_item:GetValue() == bp_item:GetValue() then
                        goto continue
                    end
                end
                local new_item = mech_container:CreateItem()
                new_item:SetValue( bp_item:GetValue() )
                ::continue::
            end
        end

        local function AssignSlotsItem( mech_item, bp_item )
            mech_item.subslots_count = bp_item.subslots_count
            AssignContainer( mech_item, bp_item, "allow_types" )
        end

        local bp_slots = GetEquipmentSlotsFrom( "player/player" )
        for mech, _ in pairs( patch_content.mech ) do
            LogService:Log( "mech " .. tostring( mech ) )
            local mech_slots = GetEquipmentSlotsFrom( mech )

            for bp_item in IterItems( bp_slots ) do
                for mech_item in IterItems( mech_slots ) do
                    if bp_item.name == mech_item.name then
                        AssignSlotsItem( mech_item, bp_item )
                        goto continue
                    end
                end
                local new_item = mech_slots:create_item()
                new_item.name = bp_item.name
                AssignSlotsItem( new_item, bp_item )
                ::continue::
            end
        end
    end

    EnsureMechEquipmentComponentSlots()
end

function controller:EnsurePatch()
    local position = {
        x = 0,
        y = 0,
        z = 0
    }

    local function PatchFailLog( blueprint, component )
        LogService:Log( ("There is no *%s in '%s'"):format( component, blueprint ) )
    end

    local function GetComponents( entity, blueprint, component )
        local et_component = EntityService:GetConstComponent( entity, component )
        local bp_component = EntityService:GetBlueprintComponent( blueprint, component )
        return et_component, bp_component
    end

    local function EnsureWeaponItemDesc()
        local component = "WeaponItemDesc"

        local function PatchWeaponVecItem( et_item, bp_item )
            et_item.max_value = bp_item.max_value
            et_item.min_value = bp_item.min_value
            et_item.default_value = bp_item.default_value
            et_item.stat_features = bp_item.stat_features
        end

        local function PatchEntityWeaponComponent( entity, blueprint )
            local et_component, bp_component = GetComponents( entity, blueprint, component )
            if et_component ~= nil then
                et_component = divergent_helper( et_component )
                bp_component = divergent_helper( bp_component )
                et_component.ammo_storage = bp_component.ammo_storage
                et_component.damage_type = bp_component.damage_type
                local bp_container = bp_component.stat_def_vec
                local et_container = et_component.stat_def_vec
                for bp_item in IterItems( bp_container ) do
                    for et_item in IterItems( et_container ) do
                        if et_item.stat_type == bp_item.stat_type then
                            PatchWeaponVecItem( et_item, bp_item )
                            goto continue
                        end
                    end
                    local new_item = et_container:create_item()
                    new_item.stat_type = bp_item.stat_type
                    PatchWeaponVecItem( new_item, bp_item )
                    ::continue::
                end
            else
                PatchFailLog( blueprint, component )
            end
            EntityService:RemoveEntity( entity )
        end

        for blueprint, _ in pairs( patch_content.weapons ) do
            if blueprint:sub( -5 ) == "_item" then
                local item = ItemService:SpawnLoot( position, blueprint, 0, 0, 0, "" )
                PatchEntityWeaponComponent( item, blueprint )
            else
                local entity = EntityService:SpawnEntity( blueprint, position, 1 )
                PatchEntityWeaponComponent( entity, blueprint )
            end
        end
    end

    local function EnsureTurretDescTarget()
        local component = "TurretDesc"

        for blueprint, _ in pairs( patch_content.turret ) do
            local entity = EntityService:SpawnEntity( blueprint, position, 1 )
            local et_component, bp_component = GetComponents( entity, blueprint, component )
            if et_component ~= nil then
                local et_target = divergent_helper( et_component ).target
                local bp_target = divergent_helper( bp_component ).target

                local bp_map, bp_vec = bp_target.type_map, bp_target.type_vec
                local et_map, et_vec = et_target.type_map, et_target.type_vec

                for bp_item in IterItems( bp_map ) do
                    for et_item in IterItems( et_map ) do
                        if bp_item.key == et_item.key then
                            et_item.value = bp_item.value
                            goto continue
                        end
                    end
                    et_map:pair_create_item( bp_item.key, bp_item.value )
                    ::continue::
                end

                local count = et_map.count
                local et_container = rawget( et_vec, "__ptr" )
                while et_vec.count < count do
                    et_container:CreateItem()
                end

                local bp_container = rawget( bp_vec, "__ptr" )
                for et_item, i in IterItems( et_container, count ) do
                    local bp_item = bp_container:GetItem( i )
                    et_item:SetValue( bp_item:GetValue() )
                end
            else
                PatchFailLog( blueprint, component )
            end
            EntityService:RemoveEntity( entity )
        end
    end

    local function EnsureInventoryItemComponent()
        local component = "InventoryItemComponent"

        for blueprint, _ in pairs( patch_content.inventory ) do
            local item = EntityService:SpawnEntity( blueprint, position, 1 )
            local et_component, bp_component = GetComponents( item, blueprint, component )
            if et_component ~= nil then
                et_component = divergent_helper( et_component )
                bp_component = divergent_helper( bp_component )
                et_component.storage_limit = bp_component.storage_limit
                et_component.cooldown = bp_component.cooldown
                et_component.add_after_obtaining = bp_component.add_after_obtaining
                et_component.replace_lower_quality = bp_component.replace_lower_quality
            else
                PatchFailLog( blueprint, component )
            end
            EntityService:RemoveEntity( item )
        end
    end

    local function EnsureHealthDesc()
        local component = "HealthDesc"

        for blueprint, _ in pairs( patch_content.health ) do
            local entity = EntityService:SpawnEntity( blueprint, position, 1 )
            local et_component, bp_component = GetComponents( entity, blueprint, component )
            if et_component ~= nil then
                et_component = divergent_helper( et_component )
                bp_component = divergent_helper( bp_component )
                et_component.max_health = bp_component.max_health
                et_component.health = bp_component.health
            else
                PatchFailLog( blueprint, component )
            end
            EntityService:RemoveEntity( entity )
        end
    end

    EnsureWeaponItemDesc()
    EnsureTurretDescTarget()
    EnsureInventoryItemComponent()
    EnsureHealthDesc()

end

return controller
