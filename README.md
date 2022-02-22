# Build wasm for Draw Harness

This project helps you build WASM files for this project:
https://github.com/gkv311/occt-draw

# How to do
1. Install the Ddocker and BuildKit. The latest version of Docker has been integrated with BuildKit.
2. Clone this project.
3. Run
    ~~~~~ bash
    `DOCKER_BUILDKIT=1 docker build -o type=local,dest=WASM_OUTPUT_PATH .` 
    ~~~~~
    Build the single-threaded DRAWEXE.
    ~~~~~ bash
    `DOCKER_BUILDKIT=1 docker build -o type=local,dest=WASM_OUTPUT_PATH --build-arg pthread=-pthread .` 
    ~~~~~
    Build multi-threaded DRAWEXE.