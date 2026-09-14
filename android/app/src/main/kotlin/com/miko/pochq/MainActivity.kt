package com.miko.pochq

import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        private const val SECURITY_CHANNEL = "com.miko.pochq/security"

        // SHA-256 sertifikat release permanen yang disimpan sebagai GitHub
        // Actions secret. APK yang ditandatangani ulang akan ditolak.
        private const val RELEASE_CERT_SHA256 =
            "ec865ee84f1b85e9831f8d8e18fcce724e8932234df1f007d30329195eaaf8f6"

        private val rootPackages = setOf(
            "com.topjohnwu.magisk",
            "com.topjohnwu.magisk.debug",
            "eu.chainfire.supersu",
            "com.noshufou.android.su",
            "com.koushikdutta.superuser",
            "com.kingroot.kinguser",
            "com.kingo.root",
            "me.weishu.kernelsu",
            "me.bmax.apatch",
            "org.meowcat.edxposed.manager",
            "org.lsposed.manager",
            "de.robv.android.xposed.installer",
        )

        private val analyzerPackages = setOf(
            "com.guoshi.httpcanary",
            "com.guoshi.httpcanary.premium",
            "com.guoshi.httpcanary.pro",
            "app.greyshirts.sslcapture",
            "com.minhui.networkcapture",
            "com.minhui.wificapture",
            "com.evbadroid.proxymon",
            "com.emanuelef.remote_capture",
        )

        private val rootPaths = listOf(
            "/system/app/Superuser.apk",
            "/system/app/SuperSU.apk",
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/su/bin/su",
            "/data/local/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/data/adb/magisk",
            "/data/adb/ksu",
            "/data/adb/ap",
            "/cache/su",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "checkSecurity") {
                val reason = securityFailureReason()
                result.success(
                    mapOf(
                        "secure" to (reason == null),
                        "reason" to (reason ?: "secure"),
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private fun securityFailureReason(): String? {
        // Debug build tetap dapat digunakan untuk pengembangan lokal. Nilai ini
        // dikompilasi false pada APK release dan tidak berasal dari manifest.
        if (BuildConfig.DEBUG) return null

        if (!hasExpectedSignature()) return "signature"
        if (isDebuggerOrTracerAttached()) return "debugger"
        if (isEmulator()) return "emulator"
        if (hasInstrumentation()) return "instrumentation"
        if (isRooted()) return "root"
        if (hasInstalledPackage(analyzerPackages)) return "analyzer"
        if (hasActiveVpn()) return "vpn"
        if (hasActiveProxy()) return "proxy"
        return null
    }

    @Suppress("DEPRECATION")
    private fun hasExpectedSignature(): Boolean {
        return try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(
                        PackageManager.GET_SIGNING_CERTIFICATES.toLong(),
                    ),
                )
            } else {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
            }
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val signingInfo = info.signingInfo ?: return false
                if (signingInfo.hasMultipleSigners()) {
                    signingInfo.apkContentsSigners
                } else {
                    signingInfo.signingCertificateHistory
                }
            } else {
                info.signatures
            }
            signatures.any { signature ->
                val digest = MessageDigest.getInstance("SHA-256")
                    .digest(signature.toByteArray())
                    .joinToString("") { byte ->
                        "%02x".format(byte.toInt() and 0xff)
                    }
                digest == RELEASE_CERT_SHA256
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isRooted(): Boolean {
        if (Build.TAGS?.contains("test-keys") == true) return true
        if (rootPaths.any { File(it).exists() }) return true
        if (hasInstalledPackage(rootPackages)) return true
        if (hasSuspiciousMount()) return true
        return canFindSuBinary()
    }

    private fun hasSuspiciousMount(): Boolean {
        return try {
            val mounts = File("/proc/mounts").readText().lowercase()
            mounts.contains("magisk") ||
                mounts.contains("kernelsu") ||
                mounts.contains("apatch") ||
                mounts.contains("/data/adb/modules")
        } catch (_: Exception) {
            false
        }
    }

    private fun canFindSuBinary(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(
                arrayOf("/system/xbin/which", "su"),
            )
            val finished = process.waitFor(250, TimeUnit.MILLISECONDS)
            if (!finished) process.destroyForcibly()
            finished && process.exitValue() == 0
        } catch (_: Exception) {
            false
        }
    }

    private fun hasInstrumentation(): Boolean {
        val suspiciousFiles = listOf(
            "/data/local/tmp/frida-server",
            "/data/local/tmp/re.frida.server",
            "/system/lib/libsubstrate.so",
            "/system/lib64/libsubstrate.so",
        )
        if (suspiciousFiles.any { File(it).exists() }) return true

        return try {
            val maps = File("/proc/self/maps").readText().lowercase()
            listOf(
                "frida",
                "gum-js-loop",
                "gmain",
                "libsubstrate",
                "xposed",
                "lsposed",
                "riru",
                "zygisk",
            ).any { maps.contains(it) }
        } catch (_: Exception) {
            false
        }
    }

    private fun isDebuggerOrTracerAttached(): Boolean {
        if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) return true
        return try {
            File("/proc/self/status").useLines { lines ->
                lines.firstOrNull { it.startsWith("TracerPid:") }
                    ?.substringAfter(':')
                    ?.trim()
                    ?.toIntOrNull()
                    ?.let { it > 0 } == true
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val product = Build.PRODUCT.lowercase()
        return fingerprint.startsWith("generic") ||
            fingerprint.startsWith("unknown") ||
            model.contains("google_sdk") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            hardware.contains("vbox") ||
            product.contains("sdk_gphone") ||
            product.contains("emulator") ||
            product.contains("simulator")
    }

    private fun hasActiveVpn(): Boolean {
        return try {
            val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
            val network = connectivity.activeNetwork ?: return false
            val capabilities = connectivity.getNetworkCapabilities(network)
                ?: return false
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        } catch (_: Exception) {
            // Gagal membaca status jaringan harus fail-closed pada release.
            true
        }
    }

    private fun hasActiveProxy(): Boolean {
        return try {
            val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
            val defaultProxy = connectivity.defaultProxy
            val nativeProxy = !defaultProxy?.host.isNullOrBlank() &&
                (defaultProxy?.port ?: -1) > 0
            val httpProxy = System.getProperty("http.proxyHost").orEmpty()
            val httpsProxy = System.getProperty("https.proxyHost").orEmpty()
            nativeProxy || httpProxy.isNotBlank() || httpsProxy.isNotBlank()
        } catch (_: Exception) {
            true
        }
    }

    private fun hasInstalledPackage(packages: Set<String>): Boolean {
        return packages.any { isPackageInstalled(it) }
    }

    @Suppress("DEPRECATION")
    private fun isPackageInstalled(packageId: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    packageId,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                packageManager.getPackageInfo(packageId, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }
}
