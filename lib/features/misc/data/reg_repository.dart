import '../../../core/storage/local_storage.dart';
import '../domain/reg_account.dart';

/// 卡回归数据仓储：读写本地 JSON（原型 `localStorage[REG_KEY]`）。
///
/// 存储结构：`{accts:[RegAccount.toJson…], sel:<id|null>}`。
class RegRepository {
  const RegRepository(this._store);

  static const String key = 'tgg-reg-v1';

  final LocalStorage _store;

  /// 当前账号列表与选中 id（损坏/缺失返回空态）。
  ({List<RegAccount> accts, String? sel}) load() {
    final json = _store.getJson(key);
    if (json == null) return (accts: const [], sel: null);
    final sel = json['sel'] as String?;
    final list = <RegAccount>[];
    for (final it in (json['accts'] as List? ?? const [])) {
      if (it is Map<String, dynamic>) {
        final a = RegAccount.fromJson(it);
        // 过滤无效空记录
        if (a.id.isNotEmpty && a.name.isNotEmpty) list.add(a);
      }
    }
    return (accts: list, sel: sel);
  }

  Future<void> save(List<RegAccount> accts, String? sel) =>
      _store.setJson(key, {
        'accts': [for (final a in accts) a.toJson()],
        'sel': sel,
      });
}
