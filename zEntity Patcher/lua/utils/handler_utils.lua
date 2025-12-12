require( "lua/utils/patcher_find_utils.lua" )

local M = {}

M.effects = require( "lua/components/effectdesc.lua" )
M.lua = require( "lua/components/luadesc.lua" )
M.health = require( "lua/components/health.lua" )
M.building = require( "lua/components/buildingdesc.lua" )
M.pipe = require( "lua/components/pipe.lua" )
M.inventory = require( "lua/components/inventorydesc.lua" )
M.turret = require( "lua/components/turretdesc.lua" )
M.weapon = require( "lua/components/weapon_item_desc.lua" )
M.converter = require( "lua/components/resource_converter.lua" )
M.resistance = require( "lua/components/resistance_component.lua" )
M.grid = require( "lua/components/grid_culler_component.lua" )
M.mech = require( "lua/components/mech_equipment.lua" )
M.default = require( "lua/components/default_handler.lua" )

return M
