import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_data_source.dart';
import '../datasources/local_home_data_source.dart';
import '../datasources/remote_home_data_source.dart';

part 'home_repository_impl.g.dart';

/// 首页仓储的本地实现。
///
/// 通过构造注入数据源，便于测试时替换。
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._dataSource);

  final HomeDataSource _dataSource;

  @override
  Future<List<HomeItem>> fetchHomeItems() async {
    final dtos = await _dataSource.fetchHomeItems();
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}

/// 首页仓储的依赖注入。
///
/// 根据 [AppConstants.useLocalDataSource] 切换本地 / 远程数据源。
@riverpod
HomeRepository homeRepository(Ref ref) {
  final HomeDataSource dataSource;
  if (AppConstants.useLocalDataSource) {
    dataSource = const LocalHomeDataSource();
  } else {
    dataSource = RemoteHomeDataSource(ref.watch(dioProvider));
  }
  return HomeRepositoryImpl(dataSource);
}
