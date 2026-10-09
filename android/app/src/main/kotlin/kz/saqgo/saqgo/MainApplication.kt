package kz.saqgo.saqgo

import android.app.Application
import com.yandex.mapkit.MapKitFactory

/** Initializes MapKit before Flutter creates the map view. */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setLocale("ru_RU")

        // The value is supplied from the secure build environment, not source control.
        if (BuildConfig.YANDEX_MAPKIT_API_KEY.isNotBlank()) {
            MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_API_KEY)
        }
    }
}
