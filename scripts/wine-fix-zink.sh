#!/bin/bash
# Wine ZINK error fix script
# MESA: error: ZINK: vkCreateBufferView failed (VK_ERROR_OUT_OF_HOST_MEMORY) 対策

echo "Setting up Wine environment with Vulkan enabled..."

# Vulkan設定（デフォルト有効）
# WINED3D_RENDERER を明示的に設定しない場合、Vulkanが優先的に使用される
# export WINED3D_RENDERER=vulkan            # Vulkanバックエンドを使用（オプション）

# Zink設定（オプション - 必要に応じて有効化）
# export MESA_LOADER_DRIVER_OVERRIDE=zink  # Zinkを使用する場合はこれを有効化

# Vulkan層を有効化
# export VK_INSTANCE_LAYERS=""
# export VK_DEVICE_LAYERS=""

echo "Vulkan enabled - using default Wine/DXVK rendering"
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
