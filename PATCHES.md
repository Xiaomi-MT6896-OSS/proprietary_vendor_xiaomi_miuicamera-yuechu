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

## Effect

After taking a photo, tapping a different mode switches immediately instead
of being ignored for 10-30 seconds.

## Verification

- Photo -> portrait switch after a 12MP capture: works within 2 seconds.
- Portrait capture still works.
- Portrait -> photo switch after a capture: works.

## Caveat

The APK is platform-signed, not MIUI-signed. MIUI-signature-specific
permissions/features may behave differently; the camera's normal capture,
mode switch, gallery review, slow-motion and panorama paths were checked on
yuechu.
