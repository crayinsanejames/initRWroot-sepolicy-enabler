# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=sepolicy-modder
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;
is_slot_device=1

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
# chmod -R 750 $ramdisk/*;
# chown -R root:root $ramdisk/*;


## AnyKernel install
device_check() {
  local PROP=$(echo "$1" | tr '[:upper:]' '[:lower:]') i
  for i in /system_root /system /vendor /odm /product; do
    if [ -f $i/build.prop ]; then
      for j in "ro.product.device" "ro.build.product" "ro.product.vendor.device" "ro.vendor.product.device"; do
        [ "$(sed -n "s/^$j=//p" $i/build.prop 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$PROP" ] && return 0
      done
    fi
  done
  return 1
}
manufacturer_check() {
  local PROP=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  [ "$(sed -n "s/^ro.product.manufacturer=//p" /system/build.prop 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$PROP" -o "$(sed -n "s/^ro.product.manufacturer=//p" $VEN/build.prop 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$PROP" ] && return 0
  return 1
}

[ -L /system/vendor ] && VEN=/vendor || VEN=/system/vendor
API=`file_getprop /system/build.prop ro.build.version.sdk`
[ $API -ge 26 ] && { LIBPATCH="\/vendor"; LIBDIR=$VEN; } || { LIBPATCH="\/system"; LIBDIR=system; }

ui_print "- Unpacking boot img..."
split_boot;


# Detect Sepolicy file
 # Get location of sepolicy
      $bin/magisk && context=magisk || context=shell
	  

[ -e /dev/block/bootdevice/by-name/odm$slot ] && ODMPART=true || ODMPART=false
$ODMPART && mount -o rw -t auto "/dev/block/bootdevice/by-name/odm$slot" /odm
[ -f /system_root/system/etc/selinux/plat_sepolicy.cil.bak ] && mv -f /system_root/system/etc/selinux/plat_sepolicy.cil.bak /system_root/system/etc/selinux/plat_sepolicy.cil
if [ -f /system_root/system/etc/selinux/plat_sepolicy.cil ]; then
  # Split policy
  if [ -f /odm/etc/selinux/precompiled_sepolicy ]; then
    SEPOL=/odm/etc/selinux/precompiled_sepolicy
  elif [ -f /vendor/etc/selinux/precompiled_sepolicy ]; then
    SEPOL=/vendor/etc/selinux/precompiled_sepolicy
  else
    [ /system/etc/init/hw/init.rc ] && SEPOL=/sepolicy || SEPOL=sepolicy
    rm -f $SEPOL
    $bin/magiskpolicy --compile-split --save $SEPOL
    mv -f /system_root/system/etc/selinux/plat_sepolicy.cil /system_root/system/etc/selinux/plat_sepolicy.cil.bak
    [ "$SEPOL" == "sepolicy" ] && $bin/magiskboot cpio $split_img/ramdisk.cpio "add 0644 sepolicy sepolicy"
  fi
# Monolithic policy
elif [ -f /sepolicy ]; then
  SEPOL=/sepolicy
else
  SEPOL=/sepolicy
fi

        ui_print "  Patching sepolicy"
       $magisk || magiskpolicy --load $SEPOL --save $SEPOL "allow shell * * *"
        magiskpolicy --load $file --save $SEPOL "allow shell * * *"
        context=shell
        # Needed for encryption -> "Unable to measure size of /dev/block/bootdevice/by-name/userdata_x: Permission denied"
        $KEEPFORCEENCRYPT && magiskpolicy --load $SEPOL --save $SEPOL "allow vold * * *"
	
          ui_print "  Installing commondata mount script"
          magiskpolicy --load $SEPOL --save $SEPOL "allow init media_rw_data_file dir mounton" #"allow fsck block_device blk_file { ioctl read write getattr lock append map open }"
          mkdir /system_root/datacommon 2>/dev/null
          set_perm /system_root/datacommon media_rw media_rw 0771 u:object_r:media_rw_data_file:s0
          cp -f $tmp/init.mount_datacommon.sh /system_root/init.mount_datacommon.sh
          set_perm /system_root/init.mount_datacommon.sh 0 2000 0755 u:object_r:shell_exec:s0
          if [ -f "/system_root/system/etc/init/hw/init.rc" ]; then
            ui_print "- Android 11 - Commondata Script Injection"
            [ "$(grep '# Zackptg5-DualBootMod' /system_root/system/etc/init/hw/init.rc)" ] || echo -ne "\n# Zackptg5-DualBootMod" >> /system_root/system/etc/init/hw/init.rc
            echo -e "\non property:sys.boot_completed=1\n    exec_background u:r:$context:s0 -- /init.mount_datacommon.sh\n" >> /system_root/system/etc/init/hw/init.rc
fi


# Apply sepolicy patches
ui_print "- Patching sepolicy..."
[ "$SEPOL" == "sepolicy" ] && $bin/magiskboot cpio $split_img/ramdisk.cpio "extract sepolicy sepolicy"
[ "$SEPOL" == "sepolicy" ] && $magisk || magiskpolicy --load sepolicy --save sepolicy "allow shell * * *"
 "$SEPOL" == "sepolicy" ] &&  magiskpolicy --load sepolicy --save sepolicy "allow shell * * *"
        context=shell
[ "$SEPOL" == "sepolicy" ] && $bin/magiskpolicy --load sepolicy --save sepolicy "allow init media_rw_data_file dir mounton" #"allow fsck block_device blk_file { ioctl read write getattr lock append map open }" #"allow shell * * *"
[ "$SEPOL" == "sepolicy" ] && $bin/magiskboot cpio $split_img/ramdisk.cpio "add 0644 sepolicy sepolicy"
$ODMPART && umount -l /odm

ui_print "- Installing driver..."




ui_print "- Repacking boot img..."
flash_boot;

ui_print " " "Download the apk and install as regular app" "after rebooting"
sleep 3
