package com.xclean.app.utils

import android.os.Build

/**
 * Utility class for detecting the device's ROM / OEM customization.
 *
 * This is useful for routing users to the correct system settings page
 * on devices that heavily customize Android (e.g., MIUI, ColorOS, OriginOS).
 */
object RomUtils {

    const val ROM_MIUI = "miui"
    const val ROM_COLOROS = "coloros"
    const val ROM_ORIGINOS = "originos"
    const val ROM_OTHER = "other"

    /**
     * Returns a string identifier for the detected ROM type.
     */
    fun getRomType(): String {
        return when {
            isMiui() -> ROM_MIUI
            isColorOS() -> ROM_COLOROS
            isOriginOS() -> ROM_ORIGINOS
            else -> ROM_OTHER
        }
    }

    /**
     * Checks for Xiaomi / Redmi / POCO devices and MIUI-specific properties.
     */
    private fun isMiui(): Boolean {
        return !getSystemProperty("ro.miui.ui.version.name").isNullOrEmpty()
                || Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)
                || Build.BRAND.equals("Xiaomi", ignoreCase = true)
                || Build.BRAND.equals("Redmi", ignoreCase = true)
                || Build.BRAND.equals("POCO", ignoreCase = true)
    }

    /**
     * Checks for OPPO / realme devices and ColorOS-specific properties.
     */
    private fun isColorOS(): Boolean {
        return !getSystemProperty("ro.build.version.opporom").isNullOrEmpty()
                || !getSystemProperty("ro.oppo.theme.version").isNullOrEmpty()
                || Build.MANUFACTURER.equals("OPPO", ignoreCase = true)
                || Build.BRAND.equals("OPPO", ignoreCase = true)
                || Build.MANUFACTURER.equals("realme", ignoreCase = true)
                || Build.BRAND.equals("realme", ignoreCase = true)
    }

    /**
     * Checks for vivo / iQOO devices and OriginOS / FuntouchOS-specific properties.
     */
    private fun isOriginOS(): Boolean {
        return !getSystemProperty("ro.vivo.os.version").isNullOrEmpty()
                || !getSystemProperty("ro.vivo.product.version").isNullOrEmpty()
                || !getSystemProperty("ro.build.version.bbk").isNullOrEmpty()
                || Build.MANUFACTURER.equals("vivo", ignoreCase = true)
                || Build.BRAND.equals("vivo", ignoreCase = true)
                || Build.BRAND.equals("iQOO", ignoreCase = true)
    }

    /**
     * Reads a system property via reflection.
     *
     * @param key The property key (e.g., "ro.miui.ui.version.name").
     * @return The property value, or null if unavailable.
     */
    private fun getSystemProperty(key: String): String? {
        return try {
            Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java)
                .invoke(null, key) as? String
        } catch (_: Exception) {
            null
        }
    }
}
