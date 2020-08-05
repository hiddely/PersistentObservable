# PersistentObservable
Add local persistence to any RxSwift observable


## Usage
If we have an observable that loads some `Codable` data, such as a network API call to some service, we can locally cache the last returned result on disk by calling `.persist(key)` on the `Observable`.
```
let account = apiClient.loadAccount()
                       .persist("some_unique_key_for_this_data")
```
The latest value of the observable is cached and serialized to disk when the app goes to a background state, and loaded from disk or memory at observable creation.

## Installation
To be determined
### Swift Package Manager

### Cocoapods
