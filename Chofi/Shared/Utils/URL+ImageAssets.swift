//
//  URL+ImageAssets.swift
//  Chofi
//
//  Created by Alfredo García on 21/11/26.
//

import UIKit

extension URL {
    
    static func convertAssetImage(named name: String,
                                  extension: String = "jpg") -> URL? {
        let fileManager = FileManager.default
        
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = cacheDirectory.appendingPathComponent("\(name).\(`extension`)")
        
        guard !fileManager.fileExists(atPath: url.path()) else {
            return url
        }
        
        guard let image = UIImage(named: name),
              let data = image.jpegData(compressionQuality: 1) else {
            return nil
        }
        
        fileManager.createFile(atPath: url.path(), contents: data)
        return url
    }
}
