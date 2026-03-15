namespace WindowsTwain;

internal interface IScannerService
{
    ScannerStatusResponse GetStatus();

    IReadOnlyList<ScanOperationDescriptor> GetOperations();

    ScannerDiscoveryResponse DiscoverScanners();

    ScanSessionResponse ScanAdfSimplex(ScanAdfSimplexRequest? request);

    ScanSessionResponse ScanAdfDuplex(ScanAdfDuplexRequest? request);

    ScanSessionResponse? GetSession(string sessionId);

    ScanSessionResponse RotatePage(string sessionId, int pageNumber, RotatePageRequest? request);

    ScanSessionResponse DeletePage(string sessionId, int pageNumber);

    ScanSessionResponse MovePage(string sessionId, int pageNumber, MovePageRequest? request);

    ScanSessionResponse AdjustPage(string sessionId, int pageNumber, AdjustPageRequest? request);

    ScanSessionResponse MergeSession(string sessionId, MergeSessionRequest request);

    PagePreviewArtifact GetPagePreview(string sessionId, int pageNumber, int? width, int? height, int? quality);

    SessionPdfArtifact ExportSessionPdf(string sessionId);

    OperationInvocationResponse InvokePlaceholder(string operationId);
}
