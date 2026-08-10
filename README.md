# RunPod ComfyUI Klein INT8 worker

Small derivative of `runpod/worker-comfyui:5.8.6-base` pinned to ComfyUI
`v0.31.0` (`43cb4fffc89bba20ab7bd61467a36d0339338dab`). This release contains native
INT8/ConvRot loading and the INT8 + LoRA requantization fix required by the
Klein workflow.

The image contains no model files and no secrets. Models are loaded from the
RunPod network volume using the standard worker directory layout.

