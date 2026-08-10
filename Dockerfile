FROM runpod/worker-comfyui:5.8.6-base

ARG COMFYUI_TAG=v0.31.0
ARG COMFYUI_COMMIT=43cb4fffc89bba20ab7bd61467a36d0339338dab

# worker-comfyui 5.8.6 predates ComfyUI's native INT8/ConvRot support.
# Pin a stable ComfyUI release which includes both native INT8 support and the
# fix that preserves ConvRot quantization parameters while applying LoRAs.
RUN git -C /comfyui fetch --depth=1 origin "refs/tags/${COMFYUI_TAG}:refs/tags/${COMFYUI_TAG}" \
    && git -C /comfyui checkout --detach "${COMFYUI_COMMIT}" \
    && test "$(git -C /comfyui rev-parse HEAD)" = "${COMFYUI_COMMIT}" \
    && uv pip install -r /comfyui/requirements.txt \
    && uv pip install "transformers>=4.50.3,<5" "huggingface-hub<1.0" \
    && cd /comfyui \
    && timeout 300 python main.py --quick-test-for-ci --cpu

LABEL org.opencontainers.image.source="https://github.com/Meln1kz/runpod-comfyui-klein-int8"
LABEL org.opencontainers.image.description="RunPod ComfyUI worker with native INT8 ConvRot and LoRA support"
LABEL io.comfyui.version="v0.31.0"

