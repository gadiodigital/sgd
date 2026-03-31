import '../../infrastructure/api/gdms_api_client.dart';

typedef MultipartObjectUploader = Future<void> Function({
  required String path,
  required Map<String, String> fields,
  required String fileFieldName,
  required List<int> bytes,
  required String fileName,
});

Future<void> postMultipartObjectWithClient(
  GdmsApiClient apiClient, {
  required String path,
  required Map<String, String> fields,
  required String fileFieldName,
  required List<int> bytes,
  required String fileName,
}) async {
  await apiClient.postMultipartObject(
    path,
    fields: fields,
    fileFieldName: fileFieldName,
    bytes: bytes,
    fileName: fileName,
  );
}
