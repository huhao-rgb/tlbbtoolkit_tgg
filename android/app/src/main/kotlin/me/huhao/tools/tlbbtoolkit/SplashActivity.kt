package me.huhao.tools.tlbbtoolkit

import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView

/**
 * 全屏启动图 Activity（原生层渲染）。
 *
 * 对应「系统启动屏 → 全屏大图页 → 主界面」三层结构中的第二层：
 * 用全屏 ImageView 绘制整幅 splash 图，展示固定时长后无动画切换到
 * Flutter 主界面（MainActivity）。
 *
 * 注意：必须 setContentView 一个真实内容视图——若只有 windowBackground，
 * 系统会一直显示「起始窗口」（不透传状态栏、图画不到状态栏背后）；
 * 有了真实视图 + edge-to-edge，启动图才能延伸到状态栏/导航栏背后，
 * 与 Flutter 主界面的沉浸式效果一致。
 */
class SplashActivity : android.app.Activity() {

    private val handler = Handler(Looper.getMainLooper())

    private val goMain = Runnable {
        if (isFinishing || isDestroyed) return@Runnable
        startActivity(Intent(this, MainActivity::class.java))
        // 前后窗口都是同一张启动图，禁用切换动画 → 过渡无感
        overridePendingTransition(0, 0)
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // 应用已在运行（最近任务 / 图标再次唤起）时不再展示启动图
        if (intent.flags and Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT != 0) {
            finish()
            return
        }
        // 真实内容视图：全屏 ImageView 绘制启动图（CENTER_CROP 等比填充裁切，
        // 深色底兜底，四周深色裁切不可见），使窗口真实绘制并延伸到系统栏背后。
        setContentView(ImageView(this).apply {
            setImageResource(R.drawable.splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(Color.parseColor("#0A0805"))
        })
        handler.postDelayed(goMain, 1300)
    }

    /** 沉浸式：窗口延伸到系统栏背后（对应 Flutter 侧 SystemUiMode.edgeToEdge）。 */
    private fun enableEdgeToEdge() {
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false)
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
            // 注：不在此设置系统栏图标明暗——SplashActivity 此时 window.insetsController
            // 可能为 null 会 NPE；深色启动图上状态栏图标默认即为浅色
            // （Theme.Light windowLightStatusBar=false）。
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
            window.statusBarColor = Color.TRANSPARENT
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(goMain)
        super.onDestroy()
    }
}
