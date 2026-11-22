# SecretSatanData — configuration

The `SecretSatanData` package is the data layer of the app: it owns every repository, whether its data comes from a
remote service or from the device. Features never know where the data comes from.
Humans and coding agents must follow this file; the `secretsatan-new-repo` skill keeps the
**Repository registry** below up to date. Do not remove the `codegen` markers.

## Organisation

```
Sources/SecretSatanData/
├── Core/                       # code shared by every repository
│   ├── Remote/                 # NetworkClient (Alamofire), RepositoryConfiguration, NetworkError
│   └── Local/                  # LocalStore and its backends: JSONFileStore, UserDefaultsStore, KeychainStore
└── Repositories/
    └── <Name>/                 # one folder per repository
        ├── <Name>Repository.swift
        ├── <Name>RequestProtocol.swift
        ├── <Name>ResponseProtocol.swift
        ├── DAO/                # internal DAOs, at the root: one DAO can serve both sources
        ├── Remote/             # only when it has its own remote source, e.g. Remote/<Provider>/
        └── Local/              # only when it stores data on the device, e.g. <Name>Storage.swift
```

## Rules

- **Alamofire** is the HTTP layer, and only `Core/Remote/NetworkClient.swift` imports it.
- Each repository lives in its own folder: `Sources/SecretSatanData/Repositories/<Name>/`.
- Data sources are split by where the data lives, both in `Core/` and inside each repository:
  - `Remote/`: whatever leaves the device, such as HTTP through `NetworkClient` or a provider SDK.
    Provider services go in `Remote/<Provider>/`.
  - `Local/`: storage on the device (JSON files, SwiftData, UserDefaults, Keychain).
  - `DAO/` stays at the root of the repository, because one DAO can serve both sources (e.g. a cached response).
- Local storage keys start with the module and the repository, `<module>.<repository>`, e.g.
  `secretSatanData.settings`. Never change a key once the app ships: the saved data would be lost.
- The app only sees **public** types: the repository API and the request/response protocols.
- Wire and stored formats are **DAOs**, which are `internal`, so they never leave the package.
- Never put secrets (API keys, client secrets, tokens) in the source.

## Anatomy of a repository

Every repository has a public API that asks for a public data protocol, plus internal DAOs for what goes in and what comes out:

```
<Name>RequestProtocol  ->  <Name>RequestDAO  ->  (service or storage)  ->  <Name>ResponseDAO  ->  <Name>ResponseProtocol
      public                  internal                                       internal                public
```

```
Repositories/New/
├── NewRepository.swift          # public protocol NewRepositoryProtocol + public final class NewRepository
├── NewRequestProtocol.swift     # public: what the app sends or saves
├── NewResponseProtocol.swift    # public: what the app receives
├── DAO/
│   ├── NewRequestDAO.swift      # internal, built from NewRequestProtocol
│   ├── NewResponseDAO.swift     # internal, conforms to NewResponseProtocol
│   └── NewEntity.swift          # SwiftData only: the internal @Model
└── Local/
    └── NewStorage.swift         # local only: NewStore.swift with SwiftData
```

## Remote repositories

The generator creates the HTTP shape, which calls `Core/Remote/NetworkClient` directly, so it adds no `Remote/`
folder. Add `Remote/<Provider>/` by hand when the repository gets its own source, such as a provider SDK.

Each one declares its endpoints in a static configuration, created empty to be filled in:

```swift
public static let configuration = RepositoryConfiguration(
    baseURL: RepositoryConfiguration.appBaseURL,   // API_BASE_URL in Configs/Config.xcconfig
    serviceNames: []      // e.g. ["users", "users/search"]
)
```

Public API: the generator writes `fetch(_ request:serviceName:) async throws -> any <Name>ResponseProtocol`. When the
services return different shapes, replace it with one typed function per endpoint (as `Events` does:
`fetchEvents()`, `createEvent(_:)`, `fetchEvent(id:)`, `updateEvent(id:_:)`, `deleteEvent(id:)`, `drawEvent(id:)`).
A path with an id, such as `events/:id` or `events/:id/draw`, declares only `events` in `serviceNames` and appends
the id, and any action after it, to its URL.

A `PATCH` sends only what changes. When a field can also be cleared with `null` (as the date of
`updateEvent(id:_:)`), an optional can't tell "keep it" from "remove it": give it its own enum
(`EventDateUpdate`: `unchanged`, `set`, `remove`) and encode `remove` with `encodeNil`.

The backend base URL is not written in the package: the app sets `API_BASE_URL` in `Configs/Config.xcconfig`,
`project.yml` copies it to the `APIBaseURL` key of its Info.plist, and every repository reads it with
`baseURL: RepositoryConfiguration.appBaseURL`. Without that key (tests, previews) it is empty and calls throw
`NetworkError.missingBaseURL`.

`NetworkClient` logs every request, successful or not, under the `SecretSatanData` subsystem, `Network` category,
**only in Debug builds**. It never logs request bodies, which may hold tokens.
Calls to a service that is not in `serviceNames`, or made while `baseURL` is empty, throw a `NetworkError`.
When the backend answers with its error body, `{ "error": true, "reason": "…" }`, `NetworkClient` throws
`NetworkError.server(statusCode:reason:)`; any other failure stays the Alamofire error. Use `request(_:method:headers:)`
for calls without a body and `send(_:method:headers:)` for responses without a body (`204 No Content`).

### Authenticated services

Services of the SecretSatan backend that need the user send `Authorization: Bearer <token>` with the session the
`Auth` repository saved. The repository reads it through the internal `AuthSessionStorageProtocol` (injected in its
internal `init`, so tests use an in-memory one) and throws its own `notSignedIn` error, before any request, when
there is no session or it has expired (see `Events`).

### Repositories with several providers

When the same data comes from several providers (e.g. two music services), the repository holds no HTTP code: it
forwards each call to the internal service of the provider, in `Remote/<Provider>/`. Every provider service is
`internal`, conforms to one internal service protocol and is registered in `<Name>Repository.init()`. A provider
without a service throws an `unsupportedProvider` error of the repository.

When the provider only proves who the user is and the backend opens the session (as in `Auth`), the repository
does one more step after the provider service: it sends the provider's credential to its own service in
`configuration.serviceNames` through `NetworkClient` (e.g. `POST auth/apple`, `POST auth/google`) and returns that
response. It resolves the service URL before showing any provider UI, so an incomplete configuration fails first.

## Local repositories

Their storage lives in `Local/` and uses one technology, chosen when the repository is created:

| Storage | Use it for | Public API |
|---|---|---|
| JSON files (`JSONFileStore`) | Documents and cached data of any size, in Application Support | `fetch()`, `save(_:)`, `delete()` |
| UserDefaults (`UserDefaultsStore`) | Small values: settings, flags, last selection | `fetch()`, `save(_:)`, `delete()` |
| Keychain (`KeychainStore`) | Sensitive data: tokens, credentials | `fetch()`, `save(_:)`, `delete()` |
| SwiftData | Many records that are queried or related | `fetchAll()`, `save(_:)`, `deleteAll()` |

- **JSON files, UserDefaults and Keychain** keep one value per repository. The internal `<Name>StorageProtocol`
  (`Local/<Name>Storage.swift`) writes `<Name>RequestDAO` as JSON under `<Name>Storage.key` and reads it back as
  `<Name>ResponseDAO`, so both DAOs must use the same coding keys. `fetch()` throws `LocalStoreError.notFound` when
  nothing has been saved yet. The internal `init(storage:)` lets tests inject another storage.
- **SwiftData** keeps a list of `<Name>Entity` records in its own store file. All the SwiftData work runs in the
  `<Name>Store` model actor (`Local/<Name>Store.swift`), and only the Sendable DAOs cross it.
  `<Name>Repository(inMemory: true)` is for previews and tests.
- A missing field should read as its default, so adding a field keeps the rest of the saved data.

## Consuming a repository from a feature

`<Feature>Dependencies` holds `<Name>RepositoryProtocol` and hands it out with `resolveRepository()`. `<Feature>UseCase`
calls it (`fetch(_:serviceName:)` for remote, `fetch()` or `fetchAll()` for local) and returns only the data of the
response, mapped out of the `SecretSatanData` types. `<Feature>ViewModel` adds it to its own field of `viewData`.

## Creating a repository

Use the `secretsatan-new-repo` skill, which asks whether it is remote or local and, if local, which storage. Or run:

```
python3 scripts/codegen/new_repo.py --name <RepositoryName> --type remote
python3 scripts/codegen/new_repo.py --name <RepositoryName> --type local --storage json|swiftdata|userdefaults|keychain
```

## Repository registry

<!-- codegen:repository-registry:start -->
| Repository | Type | Storage | Public API | Folder |
|---|---|---|---|---|
| `Auth` | Remote | Keychain (session) | `AuthRepositoryProtocol` | `Sources/SecretSatanData/Repositories/Auth` |
| `Events` | Remote (Bearer session of `Auth`) | — | `EventsRepositoryProtocol` | `Sources/SecretSatanData/Repositories/Events` |
| `Participants` | Remote (Bearer session of `Auth`) | — | `ParticipantsRepositoryProtocol` | `Sources/SecretSatanData/Repositories/Participants` |
| `Exclusions` | Remote (Bearer session of `Auth`) | — | `ExclusionsRepositoryProtocol` | `Sources/SecretSatanData/Repositories/Exclusions` |
<!-- codegen:repository-registry:end -->
