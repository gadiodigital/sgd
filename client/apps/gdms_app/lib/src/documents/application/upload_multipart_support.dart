import '../../infrastructure/api/gdms_api_client.dart';

typedef MultipartObjectUploader =
    Future<Map<String, dynamic>> Function({
      required String path,
      required Map<String, String> fields,
      required String fileFieldName,
      required List<int> bytes,
      required String fileName,
    });

Future<Map<String, dynamic>> postMultipartObjectWithClient(
  GdmsApiClient apiClient, {
  required String path,
  required Map<String, String> fields,
  required String fileFieldName,
  required List<int> bytes,
  required String fileName,
}) async {
  return apiClient.postMultipartObject(
    path,
    fields: fields,
    fileFieldName: fileFieldName,
    bytes: bytes,
    fileName: fileName,
  );
}
