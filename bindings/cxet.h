#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 *Async FFI is a tricky one here
 *Would be amazing to communicate the status from Rust -> C -> Swift in a format that could be
 *integrated with Swift's async/await model, but seems like a lot of work for now.
 */
char *xet_download(const char *file_hash, uintptr_t file_size, const char *output_path);
