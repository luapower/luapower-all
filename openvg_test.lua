assert(vg, 'load an openvg implementation (see amanithvg_test.lua) to run this test')

print("Vendor: ", vg.vgGetString(vg.VG_VENDOR))
print("Renderer: ", vg.vgGetString(vg.VG_RENDERER))
print("Version: ", vg.vgGetString(vg.VG_VERSION))
print("Extensions: ", vg.vgGetString(vg.VG_EXTENSIONS))
