[SecureContext]
partial interface ServiceWorkerRegistration {
    readonly attribute PushManager pushManager;
};

[Exposed=(Window,Worker),
 SecureContext]
interface PushManager {
    [SameObject]
    static readonly attribute FrozenArray<DOMString> supportedContentEncodings;

    Promise<PushSubscription>    subscribe(optional PushSubscriptionOptionsInit options);
    Promise<PushSubscription?>   getSubscription();
    Promise<PushPermissionState> permissionState(optional PushSubscriptionOptionsInit options);
};

dictionary PushSubscriptionOptionsInit {
    boolean                      userVisibleOnly = false;
    (BufferSource or DOMString)? applicationServerKey = null;
};

[Exposed=(Window,Worker),
 SecureContext]
interface PushSubscriptionOptions {
    readonly attribute boolean      userVisibleOnly;
    [SameObject]
    readonly attribute ArrayBuffer? applicationServerKey;
};

[Exposed=(Window,Worker),
 SecureContext]
interface PushSubscription {
    readonly attribute USVString               endpoint;
    readonly attribute DOMTimeStamp?           expirationTime;
    [SameObject]
    readonly attribute PushSubscriptionOptions options;
    ArrayBuffer?         getKey(PushEncryptionKeyName name);
    Promise<boolean>     unsubscribe();

    PushSubscriptionJSON toJSON();
};

dictionary PushSubscriptionJSON {
    USVString                    endpoint;
    DOMTimeStamp?                expirationTime;
    record<DOMString, USVString> keys;
};

enum PushEncryptionKeyName {
    "p256dh",
    "auth"
};

[Exposed=ServiceWorker,
 SecureContext]
interface PushMessageData {
    ArrayBuffer arrayBuffer();
    Blob        blob();
    any         json();
    USVString   text();
};

[Exposed=ServiceWorker,
 SecureContext]
partial interface ServiceWorkerGlobalScope {
    attribute EventHandler onpush;
    attribute EventHandler onpushsubscriptionchange;
};

typedef (BufferSource or USVString) PushMessageDataInit;

dictionary PushEventInit : ExtendableEventInit {
    PushMessageDataInit data;
};

[Constructor(DOMString type, optional PushEventInit eventInitDict),
 Exposed=ServiceWorker,
 SecureContext]
interface PushEvent : ExtendableEvent {
    readonly attribute PushMessageData? data;
};

dictionary PushSubscriptionChangeInit : ExtendableEventInit {
    PushSubscription newSubscription = null;
    PushSubscription oldSubscription = null;
};

[Constructor(DOMString type, optional PushSubscriptionChangeInit eventInitDict),
 Exposed=ServiceWorker,
 SecureContext]
interface PushSubscriptionChangeEvent : ExtendableEvent {
    readonly attribute PushSubscription? newSubscription;
    readonly attribute PushSubscription? oldSubscription;
};

enum PushPermissionState {
    "denied",
    "granted",
    "prompt",
};
