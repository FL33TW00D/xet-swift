import Foundation
import CXet

public struct XetDownloadInfo {
    public let destinationPath: String
    public let hash: String
    public let fileSize: UInt64
    
    public init(destinationPath: String, hash: String, fileSize: UInt64) {
        self.destinationPath = destinationPath
        self.hash = hash
        self.fileSize = fileSize
    }
}

public struct XetTokenInfo {
    public let token: String
    public let expiry: UInt64
    
    public init(token: String, expiry: UInt64) {
        self.token = token
        self.expiry = expiry
    }
}

public enum XetError: Error {
    case downloadFailed
    case invalidParameters
    case nullResult
}

public class XetClient {
    public init() {}
    
    public func downloadFiles(
        files: [XetDownloadInfo],
        endpoint: String,
        tokenInfo: XetTokenInfo? = nil
    ) throws -> String {
        guard !files.isEmpty else {
            throw XetError.invalidParameters
        }
        
        let cFiles = files.map { file in
            CXetDownloadInfo(
                destination_path: strdup(file.destinationPath),
                hash: strdup(file.hash),
                file_size: file.fileSize
            )
        }
        defer {
            cFiles.forEach { cFile in
                free(UnsafeMutablePointer(mutating: cFile.destination_path))
                free(UnsafeMutablePointer(mutating: cFile.hash))
            }
        }
        
        let cEndpoint = strdup(endpoint)
        defer { free(cEndpoint) }
        
        var cTokenInfo: CTokenInfo?
        var cTokenPtr: UnsafePointer<CTokenInfo>?

        let token = tokenInfo ?? XetTokenInfo(token: "", expiry: 0)
        
        let cToken = strdup(token.token)
        cTokenInfo = CTokenInfo(token: cToken, expiry: token.expiry)
        cTokenPtr = withUnsafePointer(to: &cTokenInfo!) { $0 }
        defer { free(UnsafeMutablePointer(mutating: cToken)) }
        
        let result = download_files(
            cFiles,
            UInt(cFiles.count),
            cEndpoint,
            cTokenPtr
        )
        
        guard let result = result else {
            throw XetError.nullResult
        }
        defer { free(result) }
        
        let resultString = String(cString: result)
        return resultString
    }
}
