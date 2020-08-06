//
//  FilesystemManager.swift
//
//  Created by Hidde Lycklama on 8/3/20.
//  License: MIT
//

import Foundation

class FilesystemManager {
    
    private let objectsDirName = "persistenceData"
    private var objectsDir: URL!
    
    let fileManager = FileManager.default
    
    init() {
        self.objectsDir = setupDirectoryAndCreateIfNotExists(name: objectsDirName)
    }
    
    func objectUrl(key: String) -> URL {
        return objectsDir.appendingPathComponent("\(key).json")
    }
    
    func remove(file: URL) {
        do {
            try fileManager.removeItem(at: file)
        } catch {
            print("Delete failed \(error)")
        }
    }
    
    func exists(file: URL) -> Bool {
        return fileManager.fileExists(atPath: file.path)
    }
    
    private func setupDirectoryAndCreateIfNotExists(name: String) -> URL? {
        do {
            let docDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dataPath = docDir.appendingPathComponent(name)
            if !fileManager.fileExists(atPath: dataPath.path) {
                try fileManager.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            }
            return dataPath
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
