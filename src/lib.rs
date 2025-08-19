use data::{data_client, XetFileInfo};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[repr(C)]
#[derive(Clone, Debug)]
pub struct CXetDownloadInfo {
    pub destination_path: *const c_char,
    pub hash: *const c_char,
    pub file_size: u64,
}

#[allow(clippy::from_over_into)]
impl Into<(XetFileInfo, String)> for CXetDownloadInfo {
    fn into(self) -> (XetFileInfo, String) {
        let destination_path = unsafe { CStr::from_ptr(self.destination_path) }
            .to_string_lossy()
            .into_owned();
        let hash = unsafe { CStr::from_ptr(self.hash) }
            .to_string_lossy()
            .into_owned();
        (XetFileInfo::new(hash, self.file_size), destination_path)
    }
}

#[repr(C)]
pub struct CTokenInfo {
    pub token: *const c_char,
    pub expiry: u64,
}

///Async FFI is a tricky one here
///Would be amazing to communicate the status from Rust -> C -> Swift in a format that could be
///integrated with Swift's async/await model, but seems like a lot of work for now.
///Using a callback-esque system would be good.
///
/// # Safety
/// This function is unsafe because it dereferences raw pointers and assumes that the pointers are
/// valid and point to properly allocated memory.
/// # Arguments
/// * `files` - A vector of `CXetDownloadInfo` structs containing information about the files to
/// download.
/// * `endpoint` - A pointer to a C string representing the endpoint URL.
/// * `token_info` - An optional `CTokenInfo` struct containing token information for
/// authentication.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn download_files(
    files: *const CXetDownloadInfo,
    file_count: usize,
    endpoint: *const c_char,
    token_info: *const CTokenInfo,
) -> *mut c_char {
    if files.is_null() || file_count == 0 {
        return std::ptr::null_mut();
    }
    let infos_slice = unsafe { std::slice::from_raw_parts(files, file_count) };
    let file_infos: Vec<(XetFileInfo, String)> =
        infos_slice.iter().map(|info| info.clone().into()).collect();

    let c_str = unsafe { CStr::from_ptr(endpoint) };
    let r_endpoint = c_str.to_string_lossy().into_owned();

    let token = if !token_info.is_null() {
        let token_info = unsafe { &*token_info };
        let token_str = unsafe { CStr::from_ptr(token_info.token) }
            .to_string_lossy()
            .into_owned();
        Some((token_str, token_info.expiry))
    } else {
        None
    };

    let runtime = tokio::runtime::Runtime::new().unwrap();
    let result = runtime.block_on(async {
        data_client::download_async(file_infos, Some(r_endpoint), token, None, None).await
    });

    match result {
        Ok(files) => {
            if let Some(first_file) = files.first() {
                CString::new(first_file.clone()).unwrap().into_raw()
            } else {
                std::ptr::null_mut()
            }
        }
        Err(e) => {
            println!("Error downloading files: {}", e);
            std::ptr::null_mut()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_cxet_file_download() {
        println!("Starting test for CXetFileDownload...");
        let destination_path = CString::new("/Users/fleetwood/Code/xet-swift/testing").unwrap();
        let hash = CString::new("6aec39639a0a2d1ca966356b8c2b8426a484f80ff80731f44fa8482040713bdf")
            .unwrap();
        let info = CXetDownloadInfo {
            destination_path: destination_path.as_ptr(),
            hash: hash.as_ptr(),
            file_size: 11422654,
        };

        let token = CString::new("NOT_TODAY_HACKERS").unwrap();
        let token_info = CTokenInfo {
            token: token.as_ptr(),
            expiry: 1755615704,
        };
        let endpoint = CString::new("https://cas-server.xethub.hf.co").unwrap();
        let files = [info];
        let result = unsafe {
            download_files(
                files.as_ptr(),
                files.len(),
                endpoint.as_ptr(),
                &token_info as *const CTokenInfo,
            )
        };
        if result.is_null() {
            panic!("download_files returned null pointer");
        } else {
            let c_str = unsafe { CStr::from_ptr(result) };
            let file_path = c_str.to_string_lossy().into_owned();
            println!("Downloaded file path: {}", file_path);
            unsafe { CString::from_raw(result) }; // Free the memory allocated by CString::new
        }
    }
}
