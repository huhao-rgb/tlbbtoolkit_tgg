import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取签名配置（android/key.properties，不提交到版本库）。
// 缺失时回退 debug 签名，保证在无密钥环境下 `flutter build apk --debug` 等
// 非正式构建不中断；正式 release 构建需要 key.properties + keystore。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // 存在签名配置时使用正式签名；否则回退 debug 签名（如 CI/无密钥环境）。
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// 打包产物命名：<项目名>_v<versionName>+<versionCode>[_<abi>][_<buildMode>].apk
// 例：version = 1.0.2+3 的 release 全量包 → tlbbtoolkit_tgg_v1.0.2+3.apk
//
// 注意：Flutter Gradle 插件会把 AGP 产物复制到 build/app/outputs/flutter-apk/
// 并**强制**重命名为 app<-abi>?<-flavor>?-<build-mode>.apk（flutter_tools 依赖该
// 名称定位产物，见 FlutterPlugin.kt 的 assembleTask.doLast），所以这里不改它的
// 命名，而是在 assemble 结束后再把产物复制一份为交付名称，flutter run / build /
// install 等工具链行为完全不受影响。
// ---------------------------------------------------------------------------
val artifactBaseName = "tlbbtoolkit_tgg"
val flutterApkDir = layout.buildDirectory.dir("outputs/flutter-apk")
val artifactVersionTag = "v${flutter.versionName}+${flutter.versionCode}"

val renameApkArtifacts = tasks.register("renameApkArtifacts") {
    group = "build"
    description = "按 <项目名>_v<版本号> 规则复制 APK 交付产物"
    doLast {
        val apkDir = flutterApkDir.get().asFile
        if (!apkDir.isDirectory) return@doLast

        // ABI 标识自身含 “-”（armeabi-v7a / arm64-v8a），不能用 split("-") 解析。
        val knownAbis = listOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")

        apkDir.listFiles { file ->
            file.isFile && file.name.startsWith("app") && file.name.endsWith(".apk")
        }?.forEach { apk ->
            // app-<abi>?-<build-mode>.apk
            var rest = apk.name.removeSuffix(".apk").removePrefix("app-")
            val abi = knownAbis.firstOrNull { rest.startsWith(it) }
            if (abi != null) {
                rest = rest.removePrefix(abi).removePrefix("-")
            }
            val buildMode = rest

            val targetName = buildString {
                append(artifactBaseName).append('_').append(artifactVersionTag)
                if (abi != null) append('_').append(abi)
                if (buildMode.isNotEmpty() && buildMode != "release") {
                    append('_').append(buildMode)
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
