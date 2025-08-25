import Testing
@testable import xet_swift

@Test func testXetClientDownload() async throws {
    let client = XetClient()
    
    let downloadInfo = XetDownloadInfo(
        destinationPath: "/Users/fleetwood/Code/xet-swift/xet-swift/tokenizer.json",
        hash: "6aec39639a0a2d1ca966356b8c2b8426a484f80ff80731f44fa8482040713bdf",
        fileSize: 11422654
    )

    let tokenInfo = XetTokenInfo(
        token: "REQUIRES_VALID_TOKEN",
        expiry: 1755617099
    )
    
    do {
        let result = try client.downloadFiles(
            files: [downloadInfo],
            endpoint: "https://cas-server.xethub.hf.co",
            tokenInfo: tokenInfo
        )
        
        #expect(!result.isEmpty)
        print("Downloaded file path: \(result)")
    } catch {
        #expect(Bool(false), "Download failed with error: \(error)")
    }
}
