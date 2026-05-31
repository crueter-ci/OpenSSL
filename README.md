# OpenSSL CI

Scripts and CI for OpenSSL

- [**Releases**](https://github.com/crueter-ci/OpenSSL/releases)
- Shared libraries (`BUILD_SHARED_LIBS=ON`) are supported.
- CMake targets: `OpenSSL::SSL`, `OpenSSL::Crypto`

macOS target is ARM-only

## Building and Usage

See the [spec](https://github.com/crueter-ci/spec).

These builds of OpenSSL contain a bundled Mozilla certificate store that you must import manually. To do so, e.g. via httplib:

```cpp
#include <openssl/cert.h>
#include <httplib.h>

std::unique_ptr<httplib::Client> client = std::make_unique<httplib::Client>(url);
client->load_ca_cert_store(kCert, sizeof(kCert));
```

With raw OpenSSL: see [`eden-emu/eden#8ae797409`](https://git.eden-emu.dev/eden-emu/eden/commit/8ae797409205be4ab8ccc9a87283b77ba01cfb9c)

## Dependencies

All: GNU make, curl, zstd, tar, perl, bash
