# Calling Xet from Swift

The goal of this project is to provide a handy Swift interface to the Xet rust library.
The current Rust library offers a PyO3 interface, allowing it to be used in Python like below:

```python
from huggingface_hub import hf_hub_download
hf_hub_download(repo_id="Qwen/Qwen3-0.6B", filename="tokenizer.json")
```

The ability to replicate this functionality in Swift is our primary focus.

## Architecture

We can integrate Rust into Swift by building a C bridge. We first create a C FFI in the Rust library, and then 
package the compiled Rust library into an XCFramework. An XCFramework is a [multi-platform binary framework
bundle](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle).
If we can construct an XCFramework, and perhaps wrap that in some ergonomic Swift code, we can create a Swift package
that can easily be used in Swift projects.

In `/src/lib.rs`, we define our C FFI interface for a single function, `download_files`. This function calls a single function
in the underlying Rust library, `download_async`.

## Building the XCFramework
To build our XCFramework, we use a simple `build.sh` that orchestrates the compilation of the Rust library for multiple
platforms.

We then use `xcodebuild` to wrap up all our binaries into an XCFramework.

## Some Gotchas

```
.binaryTarget(
    name: "XetSys",
    path: "./XetSys.xcframework"
),
.target(
    name: "xet-swift",
    dependencies: ["XetSys"],
    linkerSettings: [
        .linkedFramework("SystemConfiguration"),
        .linkedFramework("CoreFoundation"),
    ]
)
```

You can see that when importing, we need to link to `SystemConfiguration` and `CoreFoundation`.

The build process was greatly informed by [this blog post](https://rhonabwy.com/2023/02/10/creating-an-xcframework/) by
Joseph Heck (who is now on the Swift team :)).

## TODO

- [ ] Test on iPhone
- [ ] Create ergonomic wrapper that bridges between async task in Rust and async task in Swift
- [ ] Integrate into `swift-transformers` Hub package


