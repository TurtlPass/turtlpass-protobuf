# 📘 TurtlPass Protocol Specification

TurtlPass devices communicate with host applications over **serial (USB) using Protocol Buffers (protobuf)**. This guide explains the **data structures, commands, framing, and response formats** needed to integrate with TurtlPass.

> ⚠️ **Note:** This document assumes familiarity with serial communication, Protocol Buffers, and your language of choice (Python, C++, Go, Kotlin, etc.).

---

## 📑 Table of Contents

1. [Protocol Overview](#-protocol-overview)
2. [Commands](#-commands)
3. [Password Generation Options](#-password-generation-options)
4. [Error Handling](#-error-handling)
5. [Message Types](#-message-types)
   * [Command](#command)
   * [Response](#response)
   * [DeviceInfo](#deviceinfo)
   * [GeneratePasswordParams](#generatepasswordparams)
   * [InitializeSeedParams](#initializeseedparams)
6. [Fixed Buffer Sizes](#-fixed-buffer-sizes)
7. [Host Integration Tips](#-host-integration-tips)
8. [Footer](#-footer)

---

## 📦 Protocol Overview

* **Transport:** USB serial (CDC)
* **Serialization:** Protocol Buffers (proto3)
* **Package:** `turtlpass`

TurtlPass uses a **command/response pattern**:

1. Host sends a `Command` message.
2. MCU processes the command.
3. MCU returns a `Response` message.

All payloads are **fixed-size buffers** to simplify MCU parsing.

---

## 🔹 Commands

Commands are defined via the `CommandType` enum:

| Command             | Value | Description                                  |
| ------------------- | ----- | -------------------------------------------- |
| `UNKNOWN`           | 0     | Default / invalid command                    |
| `GET_DEVICE_INFO`   | 1     | Returns version, seed state, etc.            |
| `INITIALIZE_SEED`   | 2     | Store a seed for password derivation         |
| `GENERATE_PASSWORD` | 3     | Derives a password based on parameters       |
| `FACTORY_RESET`     | 4     | Resets device to default state (clears seed) |

> 💡 **Tip:** Always check the MCU response’s `success` and `error` fields to handle failures gracefully.

---

## 🔹 Password Generation Options

TurtlPass supports multiple character sets via the `Charset` enum:

| Charset                   | Value | Description                   |
| ------------------------- | ----- | ----------------------------- |
| `LETTERS_ONLY`            | 0     | Uppercase + lowercase letters |
| `NUMBERS_ONLY`            | 1     | Digits 0–9 only               |
| `LETTERS_NUMBERS`         | 2     | Letters + digits              |
| `LETTERS_NUMBERS_SYMBOLS` | 3     | Letters, digits, symbols      |

---

## 🔹 Error Handling

All responses return an `ErrorCode`:

| ErrorCode                 | Value | Description                           |
| ------------------------- | ----- | ------------------------------------- |
| `NONE`                    | 0     | No error                              |
| `INVALID_COMMAND`         | 1     | Command not recognized                |
| `INVALID_PARAMS`          | 2     | Parameters missing or invalid         |
| `INVALID_ENTROPY_LENGTH`  | 3     | Entropy length outside allowed range  |
| `INVALID_PASSWORD_LENGTH` | 4     | Password length outside allowed range |
| `INVALID_SEED_LENGTH`     | 5     | Seed length outside allowed range     |
| `SEED_NOT_INITIALIZED`    | 6     | Cannot generate password without seed |
| `PASSWORD_FAILED`         | 7     | Password derivation failed            |
| `PROTO_DECODING_FAILED`   | 8     | Protobuf decoding failed              |
| `PROTO_ENCODING_FAILED`   | 9     | Protobuf encoding failed              |
| `INTERNAL_ERROR`          | 10    | Unspecified internal error            |

> ⚡ **Best practice:** Always handle error codes before using `data` or `device_info`.

---

## 🔹 Message Types

### Command

```proto
message Command {
  CommandType type = 1;

  oneof parameters {
    GeneratePasswordParams gen_pass = 2;
    InitializeSeedParams init_seed = 3;
  }
}
```

* Use `gen_pass` for `GENERATE_PASSWORD` commands
* Use `init_seed` for `INITIALIZE_SEED` commands

---

### Response

```proto
message Response {
  bool success = 1;             // True if command succeeded
  ErrorCode error = 2;          // Error code
  DeviceInfo device_info = 3;   // Populated for GET_DEVICE_INFO
  bytes data = 4;               // Optional command-specific data
}
```

* `success = true` → `error` is `NONE`
* `data` contains raw output (e.g., generated password bytes)
* `device_info` contains structured info about the device firmware and environment

---

### DeviceInfo

```proto
message DeviceInfo {
  string turtlpass_version = 1;     // e.g., "3.0.0"
  string arduino_version = 2;       // e.g., "10810"
  string compiler_version = 3;      // e.g., "14.3.0"
  string nanopb_version = 4;        // e.g., "nanopb-1.0.0"
  string board_name = 5;            // e.g., "pico"
  bytes unique_board_id = 6;        // 16-byte unique MCU identifier
}
```

* Provides MCU versioning and unique board identifier
* Useful for host apps to validate device compatibility

---

### GeneratePasswordParams

```proto
message GeneratePasswordParams {
  bytes entropy = 1;         // Entropy source (1–64 bytes)
  uint32 length = 2;         // Desired password length (default: 100 chars)
  Charset charset = 3;       // Character set to use (default: LETTERS_NUMBERS)
}
```

* `entropy` can be a hash of domain + account + PIN
* MCU will deterministically derive the password using stored seed

---

### InitializeSeedParams

```proto
message InitializeSeedParams {
  bytes seed = 1;            // Seed bytes (64)
}
```

* Used once per device, securely stored in emulated EEPROM
* Required before password generation

---

## 🔹 Fixed Buffer Sizes

| Field                            | Max Size  |
| -------------------------------- | --------- |
| `GeneratePasswordParams.entropy` | 64 bytes  |
| `InitializeSeedParams.seed`      | 64 bytes  |
| `Response.data`                  | 512 bytes |
| `DeviceInfo.turtlpass_version`   | 32 bytes  |
| `DeviceInfo.arduino_version`     | 16 bytes  |
| `DeviceInfo.compiler_version`    | 32 bytes  |
| `DeviceInfo.nanopb_version`      | 32 bytes  |
| `DeviceInfo.board_name`          | 32 bytes  |
| `DeviceInfo.unique_board_id`     | 16 bytes  |

> 💡 Ensures MCU can parse messages efficiently without dynamic memory allocation.

---

## 🔹 Host Integration Tips

1. **Use protobuf libraries** for your language (Python: `protobuf`, Node.js: `protobufjs`, etc.)
2. **Frame messages with a 2-byte little-endian length prefix**

   * Before sending: `size = len(serialized_data).to_bytes(2, "little")`
   * Send `size + serialized_data` over serial
3. **Read the length first** when receiving a response, then read exactly that many bytes
4. **Check `Response.success` and `Response.error`** before processing `data`
5. **Serialize entropy deterministically** for reproducible password generation
6. **Use the unique board ID** to bind credentials to a specific device

> ⚡ **Tip:** Framing ensures reliable parsing on the MCU even when multiple commands are sent sequentially over serial.

---

## 📌 Footer

For developers extending TurtlPass:

* Refer to the [Protocol Buffers definition](proto/turtlpass.proto) for message structure and enums.
* Respect MCU buffer sizes and deterministic parsing.
* Follow cryptographic best practices when handling seeds and password entropy.

> ⚡ **Reminder:** Test your integration in a sandbox or with a separate device before using production credentials.
