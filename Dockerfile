FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ARG COMFYUI_COMMIT=43cb4fffc89bba20ab7bd61467a36d0339338dab
ARG WORKER_COMMIT=066a11c49cfe6357902d1b2d8bc8d86bc55128b0

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_PREFER_BINARY=1 \
    PATH=/opt/venv/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl ffmpeg git libgl1 libglib2.0-0 libsm6 libxext6 \
       libxrender1 libgoogle-perftools4 openssh-server python3 python3-venv wget \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/local/bin/python

RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && uv venv /opt/venv

# PyTorch 2.6.0 is the newest official release published for CUDA 12.4.
RUN uv pip install \
      torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124 \
      --index-url https://download.pytorch.org/whl/cu124 \
    && printf '%s\n' \
       'torch==2.6.0+cu124' \
       'torchvision==0.21.0+cu124' \
       'torchaudio==2.6.0+cu124' > /tmp/torch-cu124.constraints

# 0.2.28 uses custom-op annotations that require newer PyTorch. Version
# 0.2.27 keeps INT8 ConvRot + LoRA requantization and supports PyTorch 2.6.
RUN git clone https://github.com/Comfy-Org/ComfyUI.git /comfyui \
    && git -C /comfyui checkout --detach "${COMFYUI_COMMIT}" \
    && test "$(git -C /comfyui rev-parse HEAD)" = "${COMFYUI_COMMIT}" \
    && sed -i 's/comfy-kitchen==0.2.28/comfy-kitchen==0.2.27/' /comfyui/requirements.txt \
    && uv pip install -r /comfyui/requirements.txt \
       -c /tmp/torch-cu124.constraints \
       --extra-index-url https://download.pytorch.org/whl/cu124 \
       --index-strategy unsafe-best-match \
    && uv pip install "transformers>=4.50.3,<5" "huggingface-hub<1.0" \
       runpod requests websocket-client

# Reuse the official RunPod worker handler at the exact 5.8.6 commit, while
# keeping the CUDA/PyTorch runtime under our control.
RUN git clone https://github.com/runpod-workers/worker-comfyui.git /tmp/worker-comfyui \
    && git -C /tmp/worker-comfyui checkout --detach "${WORKER_COMMIT}" \
    && install -m 0755 /tmp/worker-comfyui/src/start.sh /start.sh \
    && install -m 0644 /tmp/worker-comfyui/handler.py /handler.py \
    && install -m 0644 /tmp/worker-comfyui/src/network_volume.py /network_volume.py \
    && install -m 0644 /tmp/worker-comfyui/src/extra_model_paths.yaml /comfyui/extra_model_paths.yaml \
    && install -m 0755 /tmp/worker-comfyui/scripts/comfy-manager-set-mode.sh /usr/local/bin/comfy-manager-set-mode \
    && rm -rf /tmp/worker-comfyui /tmp/torch-cu124.constraints

RUN cd /comfyui \
    && timeout 300 python main.py --quick-test-for-ci --cpu \
    && python -c "import torch; assert torch.__version__.startswith('2.6.0+cu124'); print(torch.__version__, torch.version.cuda)"

WORKDIR /
CMD ["/start.sh"]

LABEL org.opencontainers.image.source="https://github.com/Meln1kz/runpod-comfyui-klein-int8" \
      org.opencontainers.image.description="RunPod ComfyUI worker with CUDA 12.4 and INT8 ConvRot eager fallback" \
      io.comfyui.version="v0.31.0" \
      io.pytorch.version="2.6.0+cu124" \
      io.comfy-kitchen.version="0.2.27"
