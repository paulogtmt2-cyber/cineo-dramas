#!/usr/bin/env bash
set -euo pipefail
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
adb install -r android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w br.com.cineo.test/androidx.test.runner.AndroidJUnitRunner | tee android-ui-test.log
rg -q 'OK \(1 test\)' android-ui-test.log
adb pull /sdcard/Android/data/br.com.cineo/files/screens screenshots
