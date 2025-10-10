#!/bin/bash
# Wine ZINK error fix script
# MESA: error: ZINK: vkCreateBufferView failed (VK_ERROR_OUT_OF_HOST_MEMORY) 対策

echo "Setting up Wine environment to fix ZINK memory errors..."

# Mesa/Zink問題の回避設定
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe  # Zinkを無効化してLLVMpipeを使用
export WINED3D_RENDERER=opengl              # OpenGLバックエンドを強制
export WINED3D_MEMORY_LIMIT=1024             # VRAM使用量を1GB制限

# 追加の安全設定
export VK_INSTANCE_LAYERS=""                 # Vulkan層を無効化
export VK_DEVICE_LAYERS=""

echo "Environment variables set:"
echo "  MESA_LOADER_DRIVER_OVERRIDE=$MESA_LOADER_DRIVER_OVERRIDE"
echo "  WINED3D_RENDERER=$WINED3D_RENDERER"
echo "  WINED3D_MEMORY_LIMIT=$WINED3D_MEMORY_LIMIT"
echo "  VK_INSTANCE_LAYERS=$VK_INSTANCE_LAYERS"
echo "  VK_DEVICE_LAYERS=$VK_DEVICE_LAYERS"
echo ""

# 引数が指定されている場合はそのコマンドを実行
if [ $# -gt 0 ]; then
    echo "Running: $@"
    exec "$@"
else
    echo "Usage: $0 <wine command>"
    echo "Example: $0 wine your_application.exe"
    echo "Or source this script: source $0"
fi