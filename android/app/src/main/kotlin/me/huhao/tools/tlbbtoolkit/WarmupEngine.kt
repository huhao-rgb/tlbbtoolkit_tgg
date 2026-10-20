package me.huhao.tools.tlbbtoolkit

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Flutter 引擎预热。
 *
 * 未预热时启动是串行的：启动图展示 N ms → 才 startActivity(MainActivity) →
 * 此刻才开始「加载 libflutter.so + 初始化 Dart VM + 执行 dart 入口 + 等首帧」。
 * 预热把前两步挪到启动图展示期间并行完成，MainActivity 直接复用缓存引擎，
 * 首屏耗时只剩「启动图时长」。
 *
 * 兜底：预热没赶上（极慢设备）时 [isReady] 为 false，SplashActivity 退回普通
 * Intent，MainActivity 走原有冷启动流程，行为与预热前完全一致；同时调用
 * [abandon] 销毁预热出来的引擎，避免两个 Dart isolate 同时跑同一套 App 逻辑
 * （重复网络请求、重复播放等）。
 */
object WarmupEngine {

    /** FlutterEngineCache 的键，预热方与复用方（SplashActivity）必须一致。 */
    const val ENGINE_ID = "tlbbtoolkit_main_engine"

    @Volatile
    private var starting = false

    /** 仅在「已写入缓存、可被复用」后置位，避免 isReady 为 true 却取不到引擎。 */
    @Volatile
    private var engine: FlutterEngine? = null

    @Volatile
    private var abandoned = false

    /** 引擎是否已在缓存中就绪。 */
    val isReady: Boolean
        get() = engine != null

    /**
     * 在 [TlbbApplication.onCreate] 调用，保证每个进程只预热一次
     * （不放在 Activity 上，避免 Activity 重建时白白多造一个引擎）。
     */
    fun warmUp(context: Context) {
        synchronized(this) {
            if (starting || engine != null) return
            starting = true
        }

        val appContext = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        // FlutterLoader 必须在构造引擎前完成初始化（顺带把 libflutter.so 的加载也提前了）。
        loader.startInitialization(appContext)
        loader.ensureInitializationCompleteAsync(
            appContext,
            null,
            Handler(Looper.getMainLooper()),
        ) {
            val created = FlutterEngine(appContext)
            val accepted = synchronized(this) {
                if (abandoned) {
                    false
                } else {
                    // 先入缓存再置位 isReady，保证 isReady == true 时缓存里一定有它
                    FlutterEngineCache.getInstance().put(ENGINE_ID, created)
                    engine = created
                    true
                }
            }
            if (!accepted) {
                created.destroy()
                return@ensureInitializationCompleteAsync
            }
            created.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
        }
    }

    /** MainActivity 未能复用预热引擎（[isReady] 为 false）时调用：放弃并从缓存移除。 */
    fun abandon() {
        synchronized(this) {
            abandoned = true
            engine?.let {
                FlutterEngineCache.getInstance().remove(ENGINE_ID)
                it.destroy()
                engine = null
            }
        }
    }
}
