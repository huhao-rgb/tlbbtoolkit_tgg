import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_disabled.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_remote.dart';
import 'package:tlbbtoolkit/features/misc/presentation/providers/reg_sync_providers.dart';

void main() {
  test('未配置 SYNC_BASE_URL：DI 注入「未配置」占位网关（不崩溃、不假成功）', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(regSyncGatewayProvider),
      isA<RegSyncGatewayDisabled>(),
      reason: '未注入 SYNC_BASE_URL 时不应对真实云端发起请求',
    );
    expect(container.read(regSyncCryptoProvider), isA<RegSyncCryptoAesGcm>());
    expect(container.read(regPairingStoreProvider), isA<RegPairingStore>());
  });

  test('网关 provider 必须常驻：被销毁会 close 掉 dio，进行中的请求直接抛错', () async {
    // 真机实测故障：@riverpod 默认 autoDispose，无人订阅时被销毁 →
    // onDispose 里的 dio.close() 生效 → 请求抛
    // StateError("Can't establish connection after the adapter was closed.")，
    // 表现就是「未同步（可重试）」且点立即同步也没用，云端一条记录都没有。
    // 单测用的是内存网关（不持有任何可关闭资源），所以只有这条断言能守住它。
    final container = ProviderContainer(
      overrides: [
        regSyncConfigProvider.overrideWithValue((
          enabled: true,
          baseUrl: 'https://example.invalid',
          path: '/reg',
        )),
      ],
    );
    addTearDown(container.dispose);

    final first = container.read(regSyncGatewayProvider);
    expect(
      first,
      isA<RegSyncGatewayRemote>(),
      reason: '需走真实 dio 实现才有可关闭的 adapter',
    );

    // 让 Riverpod 的「无订阅 → 销毁」调度跑完（这正是真机上发生的时机）
    await Future<void>.delayed(Duration.zero);

    expect(
      identical(first, container.read(regSyncGatewayProvider)),
      isTrue,
      reason: '网关（及其 dio）不得被销毁重建，否则同步请求会因 adapter 已关闭而失败',
    );
  });

  group('normalizeRegSyncConfig —— define 是人工填写的，必须容错', () {
    test('标准输入保持不变（避免影响既有构建）', () {
      expect(
        normalizeRegSyncConfig(
          baseUrl: 'https://tgg.example.com',
          path: '/reg',
        ),
        (enabled: true, baseUrl: 'https://tgg.example.com', path: '/reg'),
      );
    });

    test('地址带末尾斜杠：拼出 //reg 会 404，必须归一化', () {
      // 网关按 baseUrl + path 直接字符串拼接，故此处不许留下多余斜杠
      expect(
        normalizeRegSyncConfig(
          baseUrl: 'https://tgg.example.com/',
          path: '/reg',
        ).baseUrl,
        'https://tgg.example.com',
      );
      for (final raw in [
        'https://tgg.example.com/',
        'https://tgg.example.com//',
      ]) {
        expect(normalizeRegSyncConfig(baseUrl: raw, path: '/reg'), (
          enabled: true,
          baseUrl: 'https://tgg.example.com',
          path: '/reg',
        ));
      }
    });

    test('路径缺前导斜杠 / 带末尾斜杠 / 多斜杠，一律归一为 /reg', () {
      for (final raw in ['reg', '/reg', 'reg/', '/reg/', '//reg//']) {
        expect(
          normalizeRegSyncConfig(
            baseUrl: 'https://tgg.example.com',
            path: raw,
          ).path,
          '/reg',
          reason: '输入 "$raw" 应归一化为 /reg',
        );
      }
    });

    test('两侧空白（复制粘贴常见）会被裁掉', () {
      expect(
        normalizeRegSyncConfig(
          baseUrl: '  https://tgg.example.com/  ',
          path: ' /reg ',
        ),
        (enabled: true, baseUrl: 'https://tgg.example.com', path: '/reg'),
      );
    });

    test('空地址 = 未启用（含「只有斜杠」的退化输入）', () {
      for (final raw in ['', '   ', '/', '///']) {
        final config = normalizeRegSyncConfig(baseUrl: raw, path: '/reg');
        expect(config.enabled, isFalse, reason: '输入 "$raw" 应判定为未配置');
      }
    });

    test('显式空路径保持为空，不补斜杠（保持原有语义）', () {
      expect(
        normalizeRegSyncConfig(
          baseUrl: 'https://tgg.example.com',
          path: '',
        ).path,
        '',
      );
    });
  });
}
