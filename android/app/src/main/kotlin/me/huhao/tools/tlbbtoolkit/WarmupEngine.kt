package me.huhao.tools.tlbbtoolkit

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * 启动引擎预热：把「Flutter 冷启动」提前到原生启动图展示期间并行执行。
 *
 * 未预热时的时间线是串行的：
 *   启动图 1300ms → startActivity(MainActivity) → 引擎初始化 + Dart 入口 + 首帧（数百 ms）
 * 预热后引擎在 SplashActivity.onCreate 就开始加载 libflutter.so / 初始化 Dart VM /
 * 执行 dart 入口，启动图结束时 MainActivity 直接复用它，总时长只剩「启动图时长」。
 */
object WarmupEngine {

    /** FlutterEngineCache 中的缓存键，SplashActivity 预热与 MainActivity 取用必须一致。 */
    const val ENGINE_ID = "tlbbtoolkit_main_engine"

    /**
     * 预热入口放在 [android.app.Application.attachBaseContext] 之后、`onCreate` 之前，
     * 这是整个应用进程内执行得最早的可注入点。
     *
     * 绑定到 Application 而非 SplashActivity，是为了保证「每个进程只预热一次」：
     * Activity 可能被系统销毁重建（旋转、内存回收后恢复），每次都预热会浪费一个引擎。
     */
    @Volatile
    private var warmedUp = false

    fun warmUp(context: Context) {
        synchronized(this) {
            if (warmedUp) return
            warmedUp = true
        }
        // FlutterLoader 必须在构造引擎之前初始化，否则引擎构造会抛异常。
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)

        // FlutterLoader 的初始化是后台异步的，先把同步的不变量（aidata、资源目录）落实，
        // 避免引擎构造时阻塞主线程更久；随后异步等待加载完成再启动 Dart。
        loader.ensureInitializationCompleteAsync(
            context,
            null,
            android.os.Handler(android.os.Looper.getMainLooper()),
        ) {
            val engine = FlutterEngine(context)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            // 缓存（而非立即销毁）该引擎，等 MainActivity 复用。
            FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        }
    }
}
