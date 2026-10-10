/// Kernel model hub: Gallery/HF catalog, auto-provisioning, registry and
/// semantic model search. Network only for catalogs and model files
/// (guardrails §7); every model runs on the phone.
///
/// app-ui uses [ModelHub.create] and the contracts interfaces it exposes
/// (ModelCatalog, ModelRegistry, ModelProvisioner, ModelSearch).
library;

export 'src/catalog_builder.dart'
    show
        buildGalleryEntries,
        entryIdOf,
        formatOf,
        hfResolveUrl,
        inferGalleryCapabilities,
        isPinnedRevision,
        mergeEntries,
        parseKernelCatalog,
        KernelCatalog;
export 'src/gallery_allowlist.dart'
    show AllowedModel, ModelAllowlist, SocModelFile, parseAllowlist;
export 'src/http.dart' show HubHttp, HubHttpResponse, IoHubHttp;
export 'src/hub_catalog.dart' show CatalogAssets, galleryVersionKey;
export 'src/model_hub_impl.dart' show BundledCatalogAssets, ModelHub;
export 'src/platform.dart'
    show
        DeviceProfile,
        DownloadRequest,
        HubPaths,
        HubPlatform,
        ModelFileInfo,
        NetworkStatus;
export 'src/policy.dart'
    show approvedLicenses, downloadBlockReason, isDownloadable, planDownloads;
