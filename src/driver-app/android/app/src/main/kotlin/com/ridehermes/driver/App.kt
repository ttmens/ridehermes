package com.ridehermes.driver

import android.app.Application
import android.util.Log
import com.amap.api.maps.MapsInitializer

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            MapsInitializer.updatePrivacyShow(this, true, true)
            MapsInitializer.updatePrivacyAgree(this, true)
            MapsInitializer.setApiKey("473c3c82dc0cd2f3ecf99eb3d0babeaa")
            Log.i("RideHermes", "AMap SDK initialized")
        } catch (e: Throwable) {
            Log.e("RideHermes", "AMap SDK init failed", e)
        }
    }
}
