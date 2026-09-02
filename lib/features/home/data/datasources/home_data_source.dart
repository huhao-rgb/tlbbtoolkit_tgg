import '../models/home_item_dto.dart';

/// 首页数据源抽象。
///
/// 数据源负责获取原始数据（DTO 形态），
/// 具体实现可以是本地模拟、缓存、REST API 等。
abstract interface class HomeDataSource {
  Future<List<HomeItemDto>> fetchHomeItems();
}
