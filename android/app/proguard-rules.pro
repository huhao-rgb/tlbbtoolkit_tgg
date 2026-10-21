# ---------------------------------------------------------------------------
# shared_preferences_android 2.5.0 起改用 Pigeon JNI 实现：Dart 侧通过
# JClass.forName / instanceMethodId 用「类名 + 方法签名字符串」反射调用 Java，
# 类名、方法名与参数类型描述符都不能被 R8 重命名或裁掉，否则运行期抛
# NoSuchMethodError / ClassNotFoundException —— 表现为启动时白屏/黑屏
# （main() 里 await SharedPreferences.getInstance() 直接失败，runApp 从未执行）。
#
# 该插件自身没有提供 consumer-proguard-rules，只能在这里补。
# ---------------------------------------------------------------------------
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# package:jni 在 native 侧按名字查找的 Kotlin 运行时类
# （见 jni/lib/src/kotlin.dart 里的 JClass.forName）。
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
