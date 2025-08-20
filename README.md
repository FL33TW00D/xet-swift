# Xet-Swift

POC repo that shows how to download files from a Xet backed HF repo using Swift! 

This is done by building a C FFI for the Rust crate in the `/rust` folder, and then calling the C API from swift following the ideas in [this post](https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html) from the Swift team! 

Luckily, the API surface for Xet can be made intentionally small! Only a little unsafe code is required! 
