package com.ridehermes.passenger

import android.app.Application
import android.util.Log
import com.amap.api.maps.MapsInitializer

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            MapsInitializer.updatePrivacyShow(this, true, true)
            MapsInitializer.updatePrivacyAgree(this, true)
            // Android platform key — must match AndroidManifest com.amap.api.v2.apikey
            MapsInitializer.setApiKey("3b9a07997610cf50a192563d4f0be0b7")
            Log.i("RideHermes", "AMap SDK privacy initialized")
        } catch (e: Throwable) {
            Log.e("RideHermes", "AMap SDK init failed", e)
        }
    }
}
