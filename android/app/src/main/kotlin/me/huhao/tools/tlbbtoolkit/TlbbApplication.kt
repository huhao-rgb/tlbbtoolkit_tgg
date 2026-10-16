package me.huhao.tools.tlbbtoolkit

import android.app.Application

/**
 * 应用入口：进程启动时立即预热 Flutter 引擎。
 *
 * 放在这里而不是 SplashActivity，是为了保证整个进程只预热一次——
 * Activity 会被系统销毁重建（旋转、内存回收后恢复、从最近任务切回），
 * 放在 Activity 里会重复构造引擎。
 */
class TlbbApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        WarmupEngine.warmUp(this)
    }
}
