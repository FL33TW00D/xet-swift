use data::{data_client, XetFileInfo};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

///Async FFI is a tricky one here
///Would be amazing to communicate the status from Rust -> C -> Swift in a format that could be
///integrated with Swift's async/await model, but seems like a lot of work for now.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn xet_download(
    file_hash: *const c_char,
    file_size: usize,
    output_path: *const c_char,
) -> *mut c_char {
    let file_hash = unsafe { CStr::from_ptr(file_hash).to_string_lossy().into_owned() };
    let output_path = unsafe { CStr::from_ptr(output_path).to_string_lossy().into_owned() };

    let file_infos = vec![(XetFileInfo::new(file_hash, file_size as u64), output_path)];

    let runtime = tokio::runtime::Runtime::new().unwrap();
    let result = runtime.block_on(async {
        data_client::download_async(
            file_infos,
            Some(String::from("https://cas-server.xethub.hf.co")),
            None,
            None,
            None,
        )
        .await
    });

    match result {
        Ok(files) => {
            if let Some(first_file) = files.first() {
                CString::new(first_file.clone()).unwrap().into_raw()
            } else {
                std::ptr::null_mut()
            }
        }
        Err(_) => std::ptr::null_mut(),
    }
}
