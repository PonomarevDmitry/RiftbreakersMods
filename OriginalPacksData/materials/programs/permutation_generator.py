f = open("particle.program", "w")

f.write("vertex_program particle_ribbon_vp hlsl")
f.write("\n{")
f.write("\n    source 						materials/programs/particle_ribbon_vp.hlsl")
f.write("\n    entry_point					mainVP")
f.write("\n    target						vs_5_0")
f.write("\n}\n")

f.write("\ngeometry_program particle_ribbon_gp hlsl")
f.write("\n{")
f.write("\n    source 						materials/programs/particle_ribbon_gp.hlsl")
f.write("\n    entry_point					mainGP")
f.write("\n    target						gs_5_0")
f.write("\n    uses_adjacency_information   on")
f.write("\n    preprocessor_defines			USE_FOG=1,USE_COLOR=1,USE_TEXCOORD=1")
f.write("\n    default_params")
f.write("\n    {")
f.write("\n        param_named_auto cWorldViewProj worldviewproj_matrix")

f.write("\n        param_named_auto cCameraPos     camera_position")
f.write("\n    }")
f.write("\n}\n")

f.write("\nvertex_program particle_billboard_vp hlsl")
f.write("\n{")
f.write("\n    source 						materials/programs/particle_billboard_vp.hlsl")
f.write("\n    entry_point					mainVP")
f.write("\n    target						vs_5_0")
f.write("\n}\n")

for def1, mask1 in [ ("ACCURATE_FACING", "a"), ("","") ]:
    for def2, mask2 in [ ("BBT_POINT", "p"), ("BBT_ORIENTED_COMMON", "oc"), ("BBT_ORIENTED_SELF", "os"), ("BBT_PERPENDICULAR_COMMON", "pc"), ("BBT_PERPENDICULAR_SELF", "ps") ]:
        for def3, mask3 in [ ("BBR_VERTEX", "rv"), ("BBR_TEXCOORD", "rt") ]:
            f.write("\ngeometry_program particle_billboard_")
            f.write(mask1)
            f.write(mask2)
            f.write(mask3)
            f.write("_gp hlsl")
            f.write("\n{")
            f.write("\n    source                          materials/programs/particle_billboard_gp.hlsl")
            f.write("\n    entry_point                     mainGP")
            f.write("\n    target                          gs_5_0")

            f.write("\n    preprocessor_defines            USE_FOG=1,")
            if def1:
                f.write(def1)
                f.write("=1,")

            f.write(def2)
            f.write("=1,")
            f.write(def3)
            f.write("=1")

            f.write("\n    default_params")
            f.write("\n    {")
            f.write("\n        param_named_auto cWorldViewProj worldviewproj_matrix")

            f.write("\n        param_named_auto cCameraPos     camera_position")
            f.write("\n        param_named_auto cCameraDir     view_direction")
            f.write("\n        param_named_auto cCameraRight   view_side_vector")
            f.write("\n        param_named_auto cCameraUp      view_up_vector")

            f.write("\n        param_named      cCommonUp      float3 0 1 0")
            f.write("\n        param_named      cCommonDir     float3 0 0 1")
            f.write("\n    }")
            f.write("\n}\n")

f.close()