// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_artifacts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 门派 key → 神器体系。
///
/// 优先级：本地缓存 / 远端覆盖（经 catalog 仓储） → 内置 `assets/catalog/` → 常量。

@ProviderFor(jobArtifacts)
final jobArtifactsProvider = JobArtifactsProvider._();

/// 门派 key → 神器体系。
///
/// 优先级：本地缓存 / 远端覆盖（经 catalog 仓储） → 内置 `assets/catalog/` → 常量。

final class JobArtifactsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, JobArtifact>>,
          Map<String, JobArtifact>,
          FutureOr<Map<String, JobArtifact>>
        >
    with
        $FutureModifier<Map<String, JobArtifact>>,
        $FutureProvider<Map<String, JobArtifact>> {
  /// 门派 key → 神器体系。
  ///
  /// 优先级：本地缓存 / 远端覆盖（经 catalog 仓储） → 内置 `assets/catalog/` → 常量。
  JobArtifactsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobArtifactsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobArtifactsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, JobArtifact>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, JobArtifact>> create(Ref ref) {
    return jobArtifacts(ref);
  }
}

String _$jobArtifactsHash() => r'8188dc498d4d9fe3133dfb0d6f5a4bf66c37545b';
