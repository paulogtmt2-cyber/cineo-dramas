#!/usr/bin/env bash
set -euo pipefail
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
adb install -r android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
trap 'adb pull /sdcard/Android/data/br.com.cineo/files/screens screenshots || true' EXIT
adb shell am force-stop com.android.launcher3 || true
adb shell am instrument -w br.com.cineo.test/androidx.test.runner.AndroidJUnitRunner | tee android-ui-test.log
grep -q 'OK (1 test)' android-ui-test.log
