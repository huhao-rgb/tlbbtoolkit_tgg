/// 接口路径常量，按业务模块分组管理。
///
/// 新增接口时在此登记，避免字符串散落在业务代码中。
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  /// 首页数据（示例）。
  static const String homeItems = '/api/v1/home/items';
}
