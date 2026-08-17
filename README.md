# RunPod ComfyUI Klein INT8 worker

CUDA 12.4 worker pinned to ComfyUI `v0.31.0`
(`43cb4fffc89bba20ab7bd61467a36d0339338dab`) and PyTorch `2.6.0+cu124`.
This release contains native INT8/ConvRot loading and the INT8 + LoRA
requantization fix required by the Klein workflow. On CUDA 12.4 ComfyUI uses
the portable comfy-kitchen eager backend instead of its CUDA 13 optimized
backend.

The image contains no model files and no secrets. Models are loaded from the
RunPod network volume using the standard worker directory layout.
