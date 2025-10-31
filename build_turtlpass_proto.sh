#!/usr/bin/env bash
# =============================================================================
#  build_turtlpass_proto.sh
#
#  Description:
#    Generates protobuf bindings for the TurtlPass project across multiple
#    languages (C++/Nanopb, Python, JavaScript, and Kotlin).
#
#  Usage:
#    ./build_turtlpass_proto.sh
#
#  Grant execute permission:
#    chmod +x build_turtlpass_proto.sh
#
#  Output Directories:
#    /out/cpp      -> Nanopb C++ bindings
#    /out/python   -> Python protobuf files
#    /out/js       -> JavaScript protobuf files
#    /out/kotlin   -> Kotlin protobuf files
# =============================================================================
set -e

# === Color codes ===
BOLD=$(tput bold)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)

# --- Paths ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR"
PROTO_DIR="$ROOT_DIR/proto"

# --- Configuration ---
PROTO_FILE="$PROTO_DIR/turtlpass.proto"
OPTIONS_FILE="$PROTO_DIR/turtlpass.options"

# Try to locate nanopb generator
NANOPB_PLUGIN="${NANOPB_PLUGIN:-}"

if [ -z "$NANOPB_PLUGIN" ]; then
  # Check PATH first
  if command -v nanopb_generator.py >/dev/null 2>&1; then
    NANOPB_PLUGIN="$(command -v nanopb_generator.py)"

  # Check inside installed pip package
  elif python3 -c "import nanopb.generator" >/dev/null 2>&1; then
    NANOPB_PLUGIN="$(python3 -c "import os, nanopb.generator; print(os.path.join(os.path.dirname(nanopb.generator.__file__), 'nanopb_generator.py'))")"
  fi
fi

OUT_CPP="$ROOT_DIR/out/cpp"
OUT_PYTHON="$ROOT_DIR/out/python"
OUT_JS="$ROOT_DIR/out/js"
OUT_KOTLIN="$ROOT_DIR/out/kotlin"

# --- Utility: relative path helper ---
relpath() {
  python3 - "$@" <<'END'
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]) if len(sys.argv) >= 3 else "")
END
}

# --- Header ---
echo ""
echo "${BOLD}${CYAN}🔧 [TurtlPass Proto Generator]${RESET}"
echo "========================================"

# --- Dependency checks ---
check_dep() {
  local cmd="$1"
  local msg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "${RED}❌ Error:${RESET} $msg"
    exit 1
  fi
}

check_dep protoc "protoc not found in PATH. Install via: ${YELLOW}brew install protobuf${RESET}"
check_dep python3 "Python 3 not found in PATH. Install via: ${YELLOW}brew install python${RESET}"

# --- Validate Nanopb generator ---
if [ -z "$NANOPB_PLUGIN" ] || [ ! -f "$NANOPB_PLUGIN" ]; then
  echo "${RED}❌ Error:${RESET} Could not locate nanopb_generator.py"
  echo "   Try installing nanopb via: ${YELLOW}pip install nanopb${RESET}"
  exit 1
else
  echo "🧠 Using nanopb generator: ${BLUE}$NANOPB_PLUGIN${RESET}"
fi

# --- Check proto files ---
if [ ! -f "$PROTO_FILE" ]; then
  echo "${RED}❌ Missing:${RESET} $(relpath "$PROTO_FILE" "$ROOT_DIR")"
  exit 1
else
  echo "🧩 Found proto file: ${BLUE}$(relpath "$PROTO_FILE" "$ROOT_DIR")${RESET}"
fi

# --- Check options file (optional) ---
if [ -f "$OPTIONS_FILE" ]; then
  echo "🧩 Found options file: ${BLUE}$(relpath "$OPTIONS_FILE" "$ROOT_DIR")${RESET}"
  OPTIONS_ARG="--options-file=$OPTIONS_FILE"
else
  echo "${YELLOW}⚠️  No turtlpass.options found (continuing without it)${RESET}"
  OPTIONS_ARG=""
fi

# --- Create output directories ---
mkdir -p "$OUT_CPP" "$OUT_PYTHON" "$OUT_JS" "$OUT_KOTLIN"


# --- Generate C++ (Nanopb) ---
echo ""
echo "${BOLD}${CYAN}🚀 Generating C++ (Nanopb) files...${RESET}"
python3 "$NANOPB_PLUGIN" \
  --proto-path="$PROTO_DIR" \
  "$PROTO_FILE" \
  --output-dir="$OUT_CPP" \
  $OPTIONS_ARG


# --- Generate Python ---
echo ""
echo "${BOLD}${CYAN}🐍 Generating Python files...${RESET}"
touch "$OUT_PYTHON/__init__.py"
protoc \
  --proto_path="$PROTO_DIR" \
  --python_out="$OUT_PYTHON" \
  "$PROTO_FILE"


# --- Generate JavaScript ---
echo ""
echo "${BOLD}${CYAN}🧩 Generating JavaScript file...${RESET}"

if ! command -v npx >/dev/null 2>&1; then
  echo "${RED}❌ Error:${RESET} npx not found. Install via: ${YELLOW}npm install --save-dev protobufjs protobufjs-cli esbuild${RESET}"
else
  # Generate CommonJS module
  npx pbjs --target static-module --wrap commonjs \
      --out "$OUT_JS/turtlpass_pb.cjs.js" "$PROTO_FILE"

  # Bundle for browser
  npx esbuild "$OUT_JS/turtlpass_pb.cjs.js" \
      --bundle --format=iife --global-name=proto \
      --outfile="$OUT_JS/turtlpass_pb.js"

  # Delete intermediate CommonJS file
  rm -f "$OUT_JS/turtlpass_pb.cjs.js"
fi


# --- Generate Kotlin ---
echo ""
echo "${BOLD}${CYAN}🤖 Generating Kotlin files...${RESET}"
protoc \
  --proto_path="$PROTO_DIR" \
  --kotlin_out="$OUT_KOTLIN" \
  "$PROTO_FILE"


# --- Summary ---
echo ""
echo "${BOLD}${GREEN}✅ Generation Complete${RESET}"
echo "----------------------------------------"

summarize_dir() {
  local label="$1"
  local dir="$2"
  echo "📁 ${BOLD}$label:${RESET} ${BLUE}$(relpath "$dir" "$ROOT_DIR")${RESET}"
  find "$dir" -type f -maxdepth 1 -printf "   ├─ %f\n" 2>/dev/null | sed '$ s/├/└/'
}

summarize_dir "C++ (Nanopb)" "$OUT_CPP"
summarize_dir "Python" "$OUT_PYTHON"
summarize_dir "JavaScript" "$OUT_JS"
summarize_dir "Kotlin" "$OUT_KOTLIN"

if [ -f "$OPTIONS_FILE" ]; then
  echo ""
  echo "⚙️  Options from: ${BLUE}$(relpath "$OPTIONS_FILE" "$ROOT_DIR")${RESET}"
fi

echo "========================================"
echo ""
