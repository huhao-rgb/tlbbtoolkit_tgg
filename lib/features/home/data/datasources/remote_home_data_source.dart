import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/home_item_dto.dart';
import 'home_data_source.dart';

/// 远程数据源：通过 [Dio] 从后端接口拉取数据。
class RemoteHomeDataSource implements HomeDataSource {
  RemoteHomeDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<HomeItemDto>> fetchHomeItems() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.homeItems);
      final data = response.data;
      if (data == null) {
        throw const ApiException('服务端返回数据为空');
      }
      return data
          .map((e) => HomeItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // 统一转换为领域友好的异常。
      throw ApiClient.toApiException(e);
    }
  }
}
