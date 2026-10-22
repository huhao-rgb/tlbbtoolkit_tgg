import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取签名配置。两个来源，按优先级：
//   1. android/key.properties + keystore 文件（本机，均不提交到版本库）；
//   2. ANDROID_KEYSTORE_PATH / ANDROID_STORE_PASSWORD / ANDROID_KEY_ALIAS /
//      ANDROID_KEY_PASSWORD 环境变量（CI，keystore 由 Secrets 临时还原到 runner）。
// 都缺失时回退 debug 签名，保证无密钥环境下 `flutter build apk --debug` 等不中断。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(propertyKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propertyKey)?.takeIf { it.isNotBlank() }
        ?: System.getenv(envKey)?.takeIf { it.isNotBlank() }

val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseStorePassword = signingValue("storePassword", "ANDROID_STORE_PASSWORD")
val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
    ?.let { file(it) }
    ?.takeIf { it.exists() }

val hasReleaseSigning = releaseStoreFile != null &&
    releaseKeyAlias != null &&
    releaseKeyPassword != null &&
    releaseStorePassword != null

android {
    namespace = "me.huhao.tools.tlbbtoolkit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "me.huhao.tools.tlbbtoolkit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
            storeFile = releaseStoreFile
            storePassword = releaseStorePassword
        }
    }

    buildTypes {
        release {
            // 有正式签名配置就用它；否则回退 debug 签名（本地无密钥时的便捷构建）。
            // CI 通过环境变量注入，并由 workflow 在构建后校验证书指纹，避免误发 debug 包。
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("未找到正式签名配置，release 构建将回退 debug 签名（不可用于分发）")
                signingConfigs.getByName("debug")
            }
        }
    }

}

// 压缩 native 库（libflutter.so / libapp.so 等）——仅 release。
// AGP 默认把它们「存储」进 APK（不压缩、4K 对齐、安装后直接 mmap），以换取更快的
// 冷启动；但这两个是 AOT 产物，deflate 后能小 40%+（20.2 MB -> 8.9 MB），对通过
// GitHub Release 下载 APK 的分发方式，下载体积远比首启几毫秒更值钱。
// 代价：安装时解压到 /data/app/.../lib，占用磁盘约为 APK + 解压后大小。
// 只作用于 release：debug 包本来就大，且每次 flutter run 都要重装，压缩只会拖慢开发。
androidComponents {
    onVariants { variant ->
        if (variant.buildType == "release") {
            variant.packaging.jniLibs.useLegacyPackaging.set(true)
        }
    }
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// 打包产物命名：TiangongGe-<versionName>-<abi>[_<buildMode>].apk
// 例：1.1.2 的 arm64 release 包 → TiangongGe-1.1.2-arm64.apk
//     debug 包 → TiangongGe-1.1.2-arm64-debug.apk
//
// 注意：Flutter Gradle 插件会把 AGP 产物复制到 build/app/outputs/flutter-apk/
// 并**强制**重命名为 app<-abi>?<-flavor>?-<build-mode>.apk（flutter_tools 依赖该
// 名称定位产物，见 FlutterPlugin.kt 的 assembleTask.doLast），所以这里不改它的
// 命名，而是在 assemble 结束后再把产物复制一份为交付名称，flutter run / build /
// install 等工具链行为完全不受影响。
// ---------------------------------------------------------------------------
val artifactBaseName = "TiangongGe"
val flutterApkDir = layout.buildDirectory.dir("outputs/flutter-apk")
val artifactVersion = flutter.versionName

// Flutter 工具用 -Ptarget-platform=android-arm64 传入目标架构；缺失时退回解析文件名。
// 统一成 win64 那种短标签，避免 arm64-v8a 这类带 “-” 的名字干扰解析。
val abiLabelMap = mapOf(
    "android-arm64" to "arm64",
    "android-arm" to "arm",
    "android-x64" to "x64",
    "android-x86" to "x86",
    "arm64-v8a" to "arm64",
    "armeabi-v7a" to "arm",
    "x86_64" to "x64",
    "x86" to "x86",
)

fun resolveAbiLabel(): String? {
    val raw = (project.findProperty("target-platform") as String?)
        ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() }
        ?: emptyList()
    val labels = raw.mapNotNull { abiLabelMap[it] }.distinct()
    return when (labels.size) {
        1 -> labels.first()
        0 -> null
        else -> "universal"
    }
}

val renameApkArtifacts = tasks.register("renameApkArtifacts") {
    group = "build"
    description = "按 TiangongGe-<版本>-<架构> 规则复制 APK 交付产物"
    doLast {
        val apkDir = flutterApkDir.get().asFile
        if (!apkDir.isDirectory) return@doLast

        // ABI 标识自身含 “-”（armeabi-v7a / arm64-v8a），不能用 split("-") 解析。
        val knownAbis = listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
        val targetLabel = resolveAbiLabel()

        apkDir.listFiles { file ->
            file.isFile && file.name.startsWith("app") && file.name.endsWith(".apk")
        }?.forEach { apk ->
            // app-<abi>?-<build-mode>.apk
            var rest = apk.name.removeSuffix(".apk").removePrefix("app-")
            val abiInName = knownAbis.firstOrNull { rest.startsWith(it) }
            if (abiInName != null) {
                rest = rest.removePrefix(abiInName).removePrefix("-")
            }
            val buildMode = rest
            val abi = abiInName?.let { abiLabelMap[it] } ?: targetLabel

            val targetName = buildString {
                append(artifactBaseName).append('-').append(artifactVersion)
                if (abi != null) append('-').append(abi)
                if (buildMode.isNotEmpty() && buildMode != "release") {
                    append('-').append(buildMode)
                }
                append(".apk")
            }

            val target = apk.copyTo(apkDir.resolve(targetName), overwrite = true)
            logger.lifecycle("交付产物：${target.absolutePath}")
        }
    }
}

// finalizedBy 保证在 Flutter 插件自身复制产物之后运行。
tasks.matching { it.name.matches(Regex("assemble(Release|Debug|Profile)")) }
    .configureEach { finalizedBy(renameApkArtifacts) }
