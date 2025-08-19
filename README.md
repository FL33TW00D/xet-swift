# Calling Xet from Swift

Before integrating into `swift-transformers`, it would be good to have a simple example of the Swift -> C -> Rust call
chain.

```python
from huggingface_hub import hf_hub_download
hf_hub_download(repo_id="Qwen/Qwen3-0.6B", filename="tokenizer.json")
```

If we call the following in Python, what happens down the line to perform our download?

`hf_hub_download` -> `_hf_hub_download_to_local_dir` -> `_get_metadata_or_catch_error` -> `get_hf_file_metadata`

Once we fetch this `metadata` from the Hub, if our file is stored using `Xet` it will have `xet_file_data` attached.
We are already able to fetch this in `swift-transformers`, [in this PR](https://github.com/huggingface/swift-transformers/pull/215/files#diff-d008547ca96c12875517345e1c3ddd2cdae19582c8f414b275e8b29f10bf801fR668).

After we have this `xet_file_data`, we pop back up to `_hf_hub_download_to_local_dir` and then to `_download_to_tmp_and_move`,
this is where we call the key method `xet_get` if the `xet_file_data` is present.

```python
xet_get(
    incomplete_path=incomplete_path,
    xet_file_data=xet_file_data,
    headers=headers,
    expected_size=expected_size,
    displayed_filename=filename,
)
```

Inside `xet_get`, we finally end up calling into Rust via PyO3:
```python
download_files(
    xet_download_info,
    endpoint=connection_info.endpoint,
    token_info=(connection_info.access_token, connection_info.expiration_unix_epoch),
    token_refresher=token_refresher,
    progress_updater=[progress_updater],
)
```

Therefore, for our Swift -> C -> Rust call chain, we simply need to expose the `download_files` function from Rust to C,
and then the surrounding call chain can be implemented in Swift! One method! 


```rust
#[pyfunction]
#[pyo3(signature = (files, endpoint, token_info, token_refresher, progress_updater), text_signature = "(files: List[PyXetDownloadInfo], endpoint: Optional[str], token_info: Optional[(str, int)], token_refresher: Optional[Callable[[], (str, int)]], progress_updater: Optional[List[Callable[[int], None]]]) -> List[str]")]
pub fn download_files(
    py: Python,
    files: Vec<PyXetDownloadInfo>,
    endpoint: Option<String>,
    token_info: Option<(String, u64)>,
    token_refresher: Option<Py<PyAny>>,
    progress_updater: Option<Vec<Py<PyAny>>>,
) -> PyResult<Vec<String>> {
    let file_infos: Vec<_> = files.into_iter().map(<(XetFileInfo, DestinationPath)>::from).collect();
    let refresher = token_refresher.map(WrappedTokenRefresher::from_func).transpose()?.map(Arc::new);
    let updaters = progress_updater.map(try_parse_progress_updaters).transpose()?;

    let x: u64 = rand::rng().random();

    let file_names = file_infos.iter().take(3).map(|(_, p)| p).join(", ");

    async_run(py, async move {
        debug!(
            "Download call {x:x}: (PID = {}) Downloading {} files {file_names}{}",
            std::process::id(),
            file_infos.len(),
            if file_infos.len() > 3 { "..." } else { "." }
        );

        let out: Vec<String> =
            data_client::download_async(file_infos, endpoint, token_info, refresher.map(|v| v as Arc<_>), updaters)
                .await
                .map_err(convert_data_processing_error)?;

        debug!("Download call {x:x}: Completed.");

        PyResult::Ok(out)
    })
}
```
We can see how the Rust -> Python call chain is set up, we will reimplement this exposing the same interface in C.



