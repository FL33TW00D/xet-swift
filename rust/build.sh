#!/bin/bash

set -e

LIB_NAME="libxet_sys.a"
FRAMEWORK_NAME="XetSys"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-13.0}"
MIN_MACOS_VERSION="${MIN_MACOS_VERSION:-11.0}"

echo "Building XCFramework for xet-swift"
echo "Min iOS: ${MIN_IOS_VERSION}, Min macOS: ${MIN_MACOS_VERSION}"

rm -rf target/xcframework
rm -rf "${FRAMEWORK_NAME}.xcframework"
mkdir -p target/xcframework/include

rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim 2>/dev/null || true
rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true

echo "Generating header..."
cbindgen --lang c --crate xet-swift --output target/xcframework/include/${FRAMEWORK_NAME}.h

# cbindgen doesn't create modulemap for us, UniFFI does.
echo "Generating module map..."
cat > target/xcframework/include/module.modulemap << EOF
module ${FRAMEWORK_NAME} {
    header "${FRAMEWORK_NAME}.h"
    export *
}
EOF

export IPHONEOS_DEPLOYMENT_TARGET=$MIN_IOS_VERSION
export MACOSX_DEPLOYMENT_TARGET=$MIN_MACOS_VERSION

echo "Building for iOS device..."
cargo build --lib --release --target aarch64-apple-ios

echo "Building for iOS simulator (arm64)..."
cargo build --lib --release --target aarch64-apple-ios-sim

echo "Building for iOS simulator (x86_64)..."
cargo build --lib --release --target x86_64-apple-ios

echo "Building for macOS (arm64)..."
cargo build --lib --release --target aarch64-apple-darwin

echo "Building for macOS (x86_64)..."
cargo build --lib --release --target x86_64-apple-darwin

echo "Creating universal binaries..."
mkdir -p target/xcframework/ios-simulator
lipo -create \
    target/aarch64-apple-ios-sim/release/$LIB_NAME \
    target/x86_64-apple-ios/release/$LIB_NAME \
    -output target/xcframework/ios-simulator/$LIB_NAME

mkdir -p target/xcframework/macos
lipo -create \
    target/aarch64-apple-darwin/release/$LIB_NAME \
    target/x86_64-apple-darwin/release/$LIB_NAME \
    -output target/xcframework/macos/$LIB_NAME

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/$LIB_NAME \
    -headers target/xcframework/include \
    -library target/xcframework/ios-simulator/$LIB_NAME \
    -headers target/xcframework/include \
    -library target/xcframework/macos/$LIB_NAME \
    -headers target/xcframework/include \
    -output "${FRAMEWORK_NAME}.xcframework"

echo "Successfully created ${FRAMEWORK_NAME}.xcframework"
