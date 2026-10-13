import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/reg_pairing_store.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_crypto_aesgcm.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_disabled.dart';
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
