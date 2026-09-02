import '../models/home_item_dto.dart';
import 'home_data_source.dart';

/// 本地模拟数据源（脚手架演示用）。
///
/// 在接入真实后端前，通过 [AppConstants.useLocalDataSource]
/// 开关使用本实现，让应用无需后端即可完整运行。
class LocalHomeDataSource implements HomeDataSource {
  const LocalHomeDataSource();

  @override
  Future<List<HomeItemDto>> fetchHomeItems() async {
    // 模拟网络延迟，便于观察 loading 状态。
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      HomeItemDto(
        id: 1,
        title: '天龙助手',
        subtitle: '常用资料与实用工具入口',
        isFavorite: true,
      ),
      HomeItemDto(
        id: 2,
        title: '成长规划',
        subtitle: '门派成长路线与加点推荐',
      ),
      HomeItemDto(
        id: 3,
        title: '打造模拟',
        subtitle: '装备打造与宝石搭配模拟',
      ),
      HomeItemDto(
        id: 4,
        title: '活动日历',
        subtitle: '每日活动与副本时间表',
      ),
    ];
  }
}
