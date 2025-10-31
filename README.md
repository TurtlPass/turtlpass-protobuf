<p align="center">
  <img src="https://raw.githubusercontent.com/TurtlPass/turtlpass-firmware-arduino/master/assets/icon.png" alt="Logo" width="133"/>
</p>

<h2 align="center">🔗 TurtlPass Ecosystem</h2>

<p align="center">
  🐢 <a href="https://github.com/TurtlPass/turtlpass-firmware-arduino"><b>Firmware</b></a> •
  💾 <a href="https://github.com/TurtlPass/turtlpass-protobuf"><b>Protobuf</b></a> •
  💻 <a href="https://github.com/TurtlPass/turtlpass-python"><b>Host</b></a> •
  🌐 <a href="https://github.com/TurtlPass/turtlpass-chrome-extension"><b>Chrome</b></a> •
  📱 <a href="https://github.com/TurtlPass/turtlpass-android"><b>Android</b></a>
</p>

---

# 💾 TurtlPass Protocol Buffers

[![](https://img.shields.io/github/v/release/TurtlPass/turtlpass-protobuf?color=green&label=Release)](https://github.com/TurtlPass/turtlpass-protobuf/releases/latest "GitHub Release")
[![](https://img.shields.io/badge/protobuf-v3-green)](https://developers.google.com/protocol-buffers "Protocol Buffers")
[![](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT "License: MIT")
[![](https://img.shields.io/badge/Documentation-green?label=GitBook&logo=gitbook)](https://ryanamaral.gitbook.io/turtlpass "GitBook Documentation")

This repository contains the official Protocol Buffer (`.proto`) schema for the **TurtlPass** project and a reproducible build script to generate language bindings for C++, Python, JavaScript and Kotlin. It enables host applications to communicate with TurtlPass hardware over USB using a consistent, cross-platform data format.

---

## 📦 Repository Layout

```

turtlpass-protobuf/
├── proto/
│   ├── turtlpass.proto       # Core protobuf definition
│   └── turtlpass.options     # Nanopb / protobuf options
├── build_turtlpass_proto.sh  # Script to generate all bindings
├── PROTOCOL.md
├── README.md
└── LICENSE

````

---

## ⚙️ Requirements

You must have all of the following tools installed **and available in your system `PATH`**:

| Tool | Purpose | Install Command |
|------|----------|----------------|
| **protoc** | Protocol Buffers compiler | `brew install protobuf` |
| **python3** | For running the Nanopb generator | `brew install python` |
| **nanopb_generator.py** | Generates C/Nanopb source files | `pip install nanopb` |
| **protobufjs / pbjs** | JS protobuf generation | `npm install --save-dev protobufjs protobufjs-cli` |
| **esbuild** | JS bundling for browser | `npm install --save-dev esbuild` |
| **gradle** | Kotlin protobuf generation | `brew install gradle` |

---

## 🚀 Usage

From the repository root:

```bash
./build_turtlpass_proto.sh
```

The script will:

1. Validate dependencies
2. Generate protobuf bindings for:

   * C++ / Nanopb
   * Python
   * JavaScript
   * Kotlin

3. Create output directories automatically:

   ```
   /out/cpp
   /out/python
   /out/js
   /out/kotlin
   ```

---

## 📄 Outputs Example

After running the build script, you’ll see a structure like this:

```
cpp/
├── turtlpass.pb.c
└── turtlpass.pb.h

python/
├── __init__.py
└── turtlpass_pb2.py

js/
└── turtlpass_pb.js

kotlin/
└── turtlpass/
    ├── CommandKt.kt
    ├── DeviceInfoKt.kt
    ├── GeneratePasswordParamsKt.kt
    ├── InitializeSeedParamsKt.kt
    ├── ResponseKt.kt
    └── TurtlpassKt.proto.kt
```

---

## 📘 Protocol Overview

* **Transport:** USB serial (CDC)  
* **Serialization:** Protocol Buffers (proto3)  
* **Pattern:** Command / Response  

**Key Commands:**
- `GET_DEVICE_INFO`: Fetch device version and seed state  
- `INITIALIZE_SEED`: Store a seed for password derivation  
- `GENERATE_PASSWORD`: Generate password using stored seed  
- `FACTORY_RESET`: Reset device to default state  

**Message Highlights:**
- `Command` / `Response` pair for communication  
- Fixed-size buffers for reliable MCU parsing  
- `DeviceInfo` includes firmware and MCU identifiers  

> For full details, see [the complete protocol specification](./PROTOCOL.md).

---

## 🧩 Purpose

This repository is intentionally minimal.
It exists solely to:

1. Define the canonical `.proto` schema for TurtlPass.
2. Provide a single reproducible script to generate bindings for all supported languages.

---

## 🧰 Troubleshooting

Check your `PATH` and ensure that all required executables can be run directly from the terminal.
You can also verify your Protobuf installation:

```bash
protoc --version
```

If it runs successfully, `protoc` itself is correctly installed.

---

## 📜 License

This repository is licensed under the [MIT License](./LICENSE).
