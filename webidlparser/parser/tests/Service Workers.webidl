[SecureContext, Exposed=(Window,Worker)]
interface ServiceWorker : EventTarget {
  readonly attribute USVString scriptURL;
  readonly attribute ServiceWorkerState state;
  void postMessage(any message, optional sequence<object> transfer = []);

  // event
  attribute EventHandler onstatechange;
};
ServiceWorker includes AbstractWorker;

enum ServiceWorkerState {
  "installing",
  "installed",
  "activating",
  "activated",
  "redundant"
};

[SecureContext, Exposed=(Window,Worker)]
interface ServiceWorkerRegistration : EventTarget {
  readonly attribute ServiceWorker? installing;
  readonly attribute ServiceWorker? waiting;
  readonly attribute ServiceWorker? active;
  [SameObject] readonly attribute NavigationPreloadManager navigationPreload;

  readonly attribute USVString scope;
  readonly attribute ServiceWorkerUpdateViaCache updateViaCache;

  [NewObject] Promise<void> update();
  [NewObject] Promise<boolean> unregister();

  // event
  attribute EventHandler onupdatefound;
};

enum ServiceWorkerUpdateViaCache {
  "imports",
  "all",
  "none"
};

partial interface Navigator {
  [SecureContext, SameObject] readonly attribute ServiceWorkerContainer serviceWorker;
};

partial interface WorkerNavigator {
  [SecureContext, SameObject] readonly attribute ServiceWorkerContainer serviceWorker;
};

[SecureContext, Exposed=(Window,Worker)]
interface ServiceWorkerContainer : EventTarget {
  readonly attribute ServiceWorker? controller;
  readonly attribute Promise<ServiceWorkerRegistration> ready;

  [NewObject] Promise<ServiceWorkerRegistration> register(USVString scriptURL, optional RegistrationOptions options);

  [NewObject] Promise<any> getRegistration(optional USVString clientURL = "");
  [NewObject] Promise<FrozenArray<ServiceWorkerRegistration>> getRegistrations();

  void startMessages();


  // events
  attribute EventHandler oncontrollerchange;
  attribute EventHandler onmessage; // event.source of message events is ServiceWorker object
  attribute EventHandler onmessageerror;
};

dictionary RegistrationOptions {
  USVString scope;
  WorkerType type = "classic";
  ServiceWorkerUpdateViaCache updateViaCache = "imports";
};

[SecureContext, Exposed=(Window,Worker)]
interface NavigationPreloadManager {
  Promise<void> enable();
  Promise<void> disable();
  Promise<void> setHeaderValue(ByteString value);
  Promise<NavigationPreloadState> getState();
};

dictionary NavigationPreloadState {
  boolean enabled = false;
  ByteString headerValue;
};

[Global=(Worker,ServiceWorker), Exposed=ServiceWorker]
interface ServiceWorkerGlobalScope : WorkerGlobalScope {
  [SameObject] readonly attribute Clients clients;
  [SameObject] readonly attribute ServiceWorkerRegistration registration;

  [NewObject] Promise<void> skipWaiting();

  attribute EventHandler oninstall;
  attribute EventHandler onactivate;
  attribute EventHandler onfetch;

  // event
  attribute EventHandler onmessage; // event.source of the message events is Client object
  attribute EventHandler onmessageerror;
};

[Exposed=ServiceWorker]
interface Client {
  readonly attribute USVString url;
  readonly attribute DOMString id;
  readonly attribute ClientType type;
  void postMessage(any message, optional sequence<object> transfer = []);
};

[Exposed=ServiceWorker]
interface WindowClient : Client {
  readonly attribute VisibilityState visibilityState;
  readonly attribute boolean focused;
  [SameObject] readonly attribute FrozenArray<USVString> ancestorOrigins;
  [NewObject] Promise<WindowClient> focus();
  [NewObject] Promise<WindowClient?> navigate(USVString url);
};

[Exposed=ServiceWorker]
interface Clients {
  // The objects returned will be new instances every time
  [NewObject] Promise<any> get(DOMString id);
  [NewObject] Promise<FrozenArray<Client>> matchAll(optional ClientQueryOptions options);
  [NewObject] Promise<WindowClient?> openWindow(USVString url);
  [NewObject] Promise<void> claim();
};

dictionary ClientQueryOptions {
  boolean includeUncontrolled = false;
  ClientType type = "window";
};

enum ClientType {
  "window",
  "worker",
  "sharedworker",
  "all"
};

[Constructor(DOMString type, optional ExtendableEventInit eventInitDict), Exposed=ServiceWorker]
interface ExtendableEvent : Event {
  void waitUntil(Promise<any> f);
};

dictionary ExtendableEventInit : EventInit {
  // Defined for the forward compatibility across the derived events
};

[Constructor(DOMString type, FetchEventInit eventInitDict), Exposed=ServiceWorker]
interface FetchEvent : ExtendableEvent {
  [SameObject] readonly attribute Request request;
  readonly attribute Promise<any> preloadResponse;
  readonly attribute DOMString clientId;
  readonly attribute DOMString resultingClientId;
  readonly attribute DOMString targetClientId;

  void respondWith(Promise<Response> r);
};

dictionary FetchEventInit : ExtendableEventInit {
  required Request request;
  Promise<any> preloadResponse;
  DOMString clientId = "";
  DOMString resultingClientId = "";
  DOMString targetClientId = "";
};

[Constructor(DOMString type, optional ExtendableMessageEventInit eventInitDict), Exposed=ServiceWorker]
interface ExtendableMessageEvent : ExtendableEvent {
  readonly attribute any data;
  readonly attribute USVString origin;
  readonly attribute DOMString lastEventId;
  [SameObject] readonly attribute (Client or ServiceWorker or MessagePort)? source;
  readonly attribute FrozenArray<MessagePort> ports;
};

dictionary ExtendableMessageEventInit : ExtendableEventInit {
  any data = null;
  USVString origin = "";
  DOMString lastEventId = "";
  (Client or ServiceWorker or MessagePort)? source = null;
  sequence<MessagePort> ports = [];
};

partial interface WindowOrWorkerGlobalScope {
  [SecureContext, SameObject] readonly attribute CacheStorage caches;
};

[SecureContext, Exposed=(Window,Worker)]
interface Cache {
  [NewObject] Promise<any> match(RequestInfo request, optional CacheQueryOptions options);
  [NewObject] Promise<FrozenArray<Response>> matchAll(optional RequestInfo request, optional CacheQueryOptions options);
  [NewObject] Promise<void> add(RequestInfo request);
  [NewObject] Promise<void> addAll(sequence<RequestInfo> requests);
  [NewObject] Promise<void> put(RequestInfo request, Response response);
  [NewObject] Promise<boolean> delete(RequestInfo request, optional CacheQueryOptions options);
  [NewObject] Promise<FrozenArray<Request>> keys(optional RequestInfo request, optional CacheQueryOptions options);
};

dictionary CacheQueryOptions {
  boolean ignoreSearch = false;
  boolean ignoreMethod = false;
  boolean ignoreVary = false;
  DOMString cacheName;
};

[SecureContext, Exposed=(Window,Worker)]
interface CacheStorage {
  [NewObject] Promise<any> match(RequestInfo request, optional CacheQueryOptions options);
  [NewObject] Promise<boolean> has(DOMString cacheName);
  [NewObject] Promise<Cache> open(DOMString cacheName);
  [NewObject] Promise<boolean> delete(DOMString cacheName);
  [NewObject] Promise<sequence<DOMString>> keys();
};
