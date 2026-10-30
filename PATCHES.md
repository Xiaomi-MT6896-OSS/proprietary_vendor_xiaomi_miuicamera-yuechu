# MiuiCamera yuechu patches

This prebuilt is based on the stock yuechu MiuiCamera APK. The APK is
re-signed with the LineageOS platform key because the stock APK cannot be
modified without breaking its original signature.

## Changes

1. `com.android.camera.fragment.modeselector.FragmentModeSelector.gi()`
   - The capture-busy guard returned early while the JPEG/reprocess path was
     still busy. It now continues into the mode switch instead of returning.

2. `com.android.camera.ui.ModeSelectView.c()`
   - The touch gate returned false while `d7.v1.p1()` (canSwipeChangeMode)
     reported a busy state, so ACTION_DOWN events were dropped before the
     mode bar could handle them. It now always returns true.

3. `com.android.camera.l3.n()` (GalleryHelper)
   - The thumbnail review intent used `com.android.camera.action.REVIEW`
     plus `setPackage("com.miui.gallery")`, which required the wrapper
     activity.
   - It now uses `android.intent.action.VIEW` with an explicit
     `com.android.gallery3d/.app.GalleryActivity` component, so the camera
     opens Gallery2's SinglePhotoPage directly.

4. `com.android.camera.b6.o.zg()` (ImageActionImpl)
   - The thumbnail click was still gated by `j7.n.g()`, which maps to
     `d7.n2.k0()`. After a second capture that flag can stay true, so the
     click logged "DoingAction" and never reached GalleryHelper.
   - The guard now jumps straight to the gallery path.

## Effect

- After taking a photo, tapping a different mode switches immediately instead
  of being ignored for 10-30 seconds.
- Tapping the camera thumbnail opens the last photo in Gallery2 directly,
  without the extra `com.miui.gallery` wrapper hop.
- The thumbnail still opens after a photo -> mode switch -> photo sequence,
  which previously hit the `DoingAction` guard.

## Verification

- Photo -> portrait switch after a 12MP capture: works within 2 seconds.
- Portrait capture still works.
- Portrait -> photo switch after a capture: works.
- Photo -> switch -> photo -> thumbnail: opens Gallery2 SinglePhotoPage.
- Thumbnail -> Gallery2 SinglePhotoPage: opens the last image directly.

## Caveat

The APK is platform-signed, not MIUI-signed. MIUI-signature-specific
permissions/features may behave differently; the camera's normal capture,
mode switch, gallery review, slow-motion and panorama paths were checked on
yuechu.
