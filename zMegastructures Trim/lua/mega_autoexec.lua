local ok, ep = pcall( require, "lua/entity_patcher.lua" )

local function BoxShape( x, y, z, position )
    return {
        x = x,
        y = y,
        z = z,
        position = position
     }
end

local mega_autoexec = function()
    if not ok then
        return
    end

    ep.mod_name = "[Megastructures Trim]"
    if GetOrCreateLocker( ep.mod_name ) then
        return
    end
    local patch = {
        {
            name = "buildings/megastructures/quantum_cortex_laboratory",
            data = ep.t:PipeComponent( "att_in_1,att_in_2,att_in_3,att_in_4" )
         },
        {
            name = "buildings/megastructures/hydroponic_lab",
            data = ep.t:PipeComponent( "att_in_1,att_in_2,att_in_3,att_in_4" )
         },

        {
            name = "buildings/megastructures/hydroponic_lab_10",
            data = {
                ["GridCullerComponent"] = {
                    Shapes = {
                        Box = {
                            BoxShape( 8, 8, 6 )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/hydroponic_lab_8",
            data = {
                ["GridCullerComponent"] = {
                    Shapes = {
                        Box = {
                            BoxShape( 8, 8, 6 )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/hydroponic_lab_6",
            data = {
                ["GridCullerComponent"] = {
                    Shapes = {
                        Box = {
                            BoxShape( 8, 8, 6 )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/hydroponic_lab_4",
            data = {
                ["GridCullerComponent"] = {
                    Shapes = {
                        Box = {
                            BoxShape( 8, 8, 6 )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/gravitational_hyper_lens",
            data = ep.t:PipeComponent( "att_in_1,att_in_2,att_in_3,att_in_4" )
         },
        {
            name = "buildings/megastructures/nanobot_center_4",
            data = {
                ["GridCullerComponent"] = {
                    Shapes = {
                        Box = {
                            BoxShape( 4, 18, 16, {
                                x = 2,
                                z = 2
                             } ),
                            BoxShape( 4, 18, 8, {
                                x = 4,
                                z = -2
                             } ),
                            BoxShape( 16, 18, 4, {
                                x = -2,
                                z = -2
                             } ),
                            BoxShape( 8, 18, 4, {
                                x = 2,
                                z = -4
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/nanobot_center_3",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 4, 18, 16, {
                                x = -2,
                                z = -2
                             } ),
                            BoxShape( 4, 18, 8, {
                                x = -4,
                                z = 2
                             } ),
                            BoxShape( 16, 18, 4, {
                                x = 2,
                                z = 2
                             } ),
                            BoxShape( 8, 18, 4, {
                                x = -2,
                                z = 4
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/nanobot_center_2",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 4, 18, 16, {
                                x = -2,
                                z = 2
                             } ),
                            BoxShape( 4, 18, 8, {
                                x = -4,
                                z = -2
                             } ),
                            BoxShape( 16, 18, 4, {
                                x = 2,
                                z = -2
                             } ),
                            BoxShape( 8, 18, 4, {
                                x = -2,
                                z = -4
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/nanobot_center_1",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 4, 18, 16, {
                                x = 2,
                                z = -2
                             } ),
                            BoxShape( 4, 18, 8, {
                                x = 4,
                                z = 2
                             } ),
                            BoxShape( 16, 18, 4, {
                                x = -2,
                                z = 2
                             } ),
                            BoxShape( 8, 18, 4, {
                                x = 2,
                                z = 4
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/arcology_workshop_3",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 14, 10, 18, {
                                x = -3
                             } ),
                            BoxShape( 18, 10, 14, {
                                z = 3
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/arcology_workshop_2",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 14, 10, 18, {
                                z = 3
                             } ),
                            BoxShape( 18, 10, 14, {
                                x = 3
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/arcology_workshop_1",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 14, 10, 18, {
                                x = 3
                             } ),
                            BoxShape( 18, 10, 14, {
                                z = -3
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/arcology_workshop_0",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 14, 10, 18, {
                                z = -3
                             } ),
                            BoxShape( 18, 10, 14, {
                                x = -3
                             } )
                         }
                     }
                 }
             }
         },
        {
            name = "buildings/megastructures/arcology_workshop",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            BoxShape( 6, 10, 40 ),
                            BoxShape( 40, 10, 6 )
                         }
                     }
                 }
             }
         }
     }

    ep:ApplyOrdered( patch )
end

mega_autoexec()
