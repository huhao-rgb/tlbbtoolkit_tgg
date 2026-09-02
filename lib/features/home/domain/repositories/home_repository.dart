import '../entities/home_item.dart';

/// 首页数据仓储抽象。
///
/// 领域层只依赖抽象，具体实现位于 data 层。
abstract interface class HomeRepository {
  Future<List<HomeItem>> fetchHomeItems();
}
