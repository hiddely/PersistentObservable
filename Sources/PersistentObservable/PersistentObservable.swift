//
//  PersistentObservable.swift
//
//  Created by Hidde Lycklama on 8/3/20.
//  License: MIT
//

#if canImport(UIKit)
import UIKit
import Foundation
import RxSwift
import RxCocoa

typealias SaveFunction = () -> Bool

class DiskManager {
    
    static let shared: DiskManager = DiskManager()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private let filesystem = FilesystemManager()
    
    private var memoryStore = [String: SaveFunction]()
    
    private init() {
        NotificationCenter.default.addObserver(self,
        selector: #selector(onTerminate(notification:)),
        name: UIApplication.willResignActiveNotification,
        object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Deferred saving
    func save(_ fun: @escaping SaveFunction, forKey key: String) {
        /// Defers save
        memoryStore[key] = fun
    }
    
    @objc func onTerminate(notification: Notification) {
        // save all
        let savingResult = memoryStore.map { (tuple) in
            
            let (key, value) = tuple
            let res = value()
            if !res {
                print("\(key) failed to save!")
            }
            return res
        }.reduce(true) { (last, success) -> Bool in
            return last && success
        }
        if savingResult {
            print("Saved all succesfully")
        }
        memoryStore.removeAll()
    }
    
    func write<T: Codable>(_ object: T, forKey key: String) -> Bool {
        let file = filesystem.objectUrl(key: key)
        guard let data = try? encoder.encode(object) else {
            return false
        }
        do {
            try data.write(to: file, options: [.atomicWrite])
            return true
        } catch {
            return false
        }
    }
    
    func load<T: Codable>(forKey: String) -> T? {
        let file = filesystem.objectUrl(key: forKey)
        if filesystem.exists(file: file),
            let data = try? Data(contentsOf: file) {
            return try? decoder.decode(T.self, from: data)
        }
        return nil
    }
    
    func remove(forKey: String) {
        let file = filesystem.objectUrl(key: forKey)
        filesystem.remove(file: file)
    }
    
}

extension Observable where Element: Codable {
    
    /**
        Persist the current value of this observable to disk. Elements of the observable must be `Codable`.
     
      - Parameter key: The key under which to save the elements of this observable. Must be unique
     
      - Returns: Observable with the same behavior as `self`.
     */
    public func persist(_ key: String) -> Observable<Element> {
        return Observable.create { observer -> Disposable in
            
            // Load initial
            let disk = DiskManager.shared
            DispatchQueue.main.async {
                if let saved: Element = disk.load(forKey: key) {
                    // Found initial value
                    observer.onNext(saved)
                    disk.remove(forKey: key)
                }
            }
            
            return self.subscribe({ event in
                switch event {
                case .next(let element):
                    observer.onNext(element)
                    disk.save({
                        return disk.write(element, forKey: key) // ugly workaround because generics
                    }, forKey: key)
                case .error(let err):
                    observer.onError(err)
                case .completed:
                    observer.onCompleted()
                }
            })
            
        }
    }
    
}

extension Observable {
    
    /**
        Persist the current success value of this observable to disk. Elements must conform to `Result` and values must be `Codable`.
     
      - Parameter key: The key under which to save the elements of this observable. Must be unique
     
      - Returns: Observable with the same behavior as `self`.
     */
    public func persist<T: Codable, E: Error>(_ key: String) -> Observable<Element> where Element == Result<T, E> {
        return Observable.create { observer -> Disposable in
            
            // Load initial
            let disk = DiskManager.shared
            DispatchQueue.main.async {
                if let saved: T = disk.load(forKey: key) {
                    // Found initial value
                    observer.onNext(.success(saved))
                }
            }
            
            return self.subscribe({ event in
                switch event {
                case .next(let element):
                    observer.onNext(element)
                    switch element {
                    case .success(let value):
                        disk.save({
                            return disk.write(value, forKey: key) // ugly workaround because generics
                        }, forKey: key)
                    default:
                        break
                        // clear disk ?
                    }
                    
                case .error(let err):
                    observer.onError(err)
                case .completed:
                    observer.onCompleted()
                }
            })
            
        }
    }
    
}

// Code specific to platforms where UIKit is available

#endif
