#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct CXetDownloadInfo {
  const char *destination_path;
  const char *hash;
  uint64_t file_size;
} CXetDownloadInfo;

typedef struct CTokenInfo {
  const char *token;
  uint64_t expiry;
} CTokenInfo;

/**
 *Async FFI is a tricky one here
 *Would be amazing to communicate the status from Rust -> C -> Swift in a format that could be
 *integrated with Swift's async/await model, but seems like a lot of work for now.
 *Using a callback-esque system would be good.
 *
 * # Safety
 * This function is unsafe because it dereferences raw pointers and assumes that the pointers are
 * valid and point to properly allocated memory.
 * # Arguments
 * * `files` - A vector of `CXetDownloadInfo` structs containing information about the files to
 * download.
 * * `endpoint` - A pointer to a C string representing the endpoint URL.
 * * `token_info` - An optional `CTokenInfo` struct containing token information for
 * authentication.
 */
char *download_files(const struct CXetDownloadInfo *files,
                     uintptr_t file_count,
                     const char *endpoint,
                     const struct CTokenInfo *token_info);
