# Ring Docker Images

[![Full Image CI](https://img.shields.io/github/actions/workflow/status/ysdragon/ring-docker/main.yml?label=Full%20Image%20CI&logo=github)](https://github.com/ysdragon/ring-docker/actions/workflows/main.yml)
[![Light Image CI](https://img.shields.io/github/actions/workflow/status/ysdragon/ring-docker/main.yml?label=Light%20Image%20CI&logo=github)](https://github.com/ysdragon/ring-docker/actions/workflows/main.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/ysdragon/ring?logo=docker)](https://hub.docker.com/r/ysdragon/ring)
[![License](https://img.shields.io/github/license/ysdragon/ring-docker.svg)](https://github.com/ysdragon/ring-docker/blob/main/LICENSE)

This repository contains the Dockerfiles and associated scripts to build Docker images for the [Ring programming language](https://ring-lang.github.io/). The images are available in two flavors: `full` and `light`.

These images are automatically built and pushed to:

*   [Docker Hub](https://hub.docker.com/r/ysdragon/ring)
*   [GitHub Container Registry](https://github.com/users/ysdragon/packages/container/package/ring)
*   [Quay.io](https://quay.io/repository/ydrag0n/ring)

## Features

*   **Multiple Flavors:** Choose between a `full` image with extensive libraries, a `light` image for minimal needs, or nightly images for the latest development builds.
*   **Nightly Builds:** Access the latest development versions through nightly images built daily from the master branch.
*   **Version Switching:** Easily switch between different versions of the Ring language.
*   **Package Management:** Install Ring packages using `ringpm` within the container.
*   **Executable Creation:** Compile your Ring scripts into distributable executables.
*   **Multi-platform:** The `full` and `nightly-full` images are built for `linux/amd64` and `linux/arm64`. The `light` and `nightly-light` images support `linux/amd64`, `linux/arm64`, and `linux/riscv64`.

## Image Flavors

### `full`

The `full` image is a comprehensive build that includes all available Ring libraries and extensions. It is ideal for developing applications with graphical user interfaces, games, and other complex projects that require a wide range of functionalities. This image is also used by the [ring-action](https://github.com/ysdragon/ring-action) GitHub Action.

### `light`

The `light` image is a minimal version designed for command-line applications, scripting, and web development. It includes the core Ring language and the following extensions:

*   ConsoleColors
*   CURL
*   FastPro
*   HTTPLib
*   Internet
*   LibUV
*   MurmurHash
*   MySQL
*   ODBC
*   OpenSSL
*   PDFGen
*   PostgreSQL
*   Sockets
*   SQLite
*   Threads
*   Zip

### `nightly-full`

The `nightly-full` (or `nightly`) image is the full image built daily from the latest master branch of the Ring repository. It includes the same extensive libraries as the `full` image but incorporates the most recent changes and bug fixes from ongoing development.

### `nightly-light`

The `nightly-light` image is the light image built daily from the latest master branch, offering the minimal version with the same extensions as the `light` image, ensuring access to the latest features and improvements.

## Usage

### Running a Ring Script

To run a Ring script, you can mount your project directory into the `/app` directory in the container and specify the script to run.

```bash
# For the latest stable full image
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring ysdragon/ring:latest

# For the light image
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring ysdragon/ring:light

# For the nightly full image (latest from master branch)
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring ysdragon/ring:nightly

# For the nightly light image
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring ysdragon/ring:nightly-light
```

### Switching Ring Versions

You can specify a different Ring version by setting the `RING_VERSION` environment variable.

```bash
# For the latest image
docker run --rm -v $(pwd):/app -e RING_VERSION=1.22 -e RING_FILE=myapp.ring ysdragon/ring:latest

# Same applies for nightly, or nightly-light with the appropriate tag
docker run --rm -v $(pwd):/app -e RING_VERSION=1.22 -e RING_FILE/myapp.ring ysdragon/ring:light
```

### Installing Packages

You can install Ring packages from the Ring Package Manager (`ringpm`) by setting the `RING_PACKAGES` environment variable.

```bash
# For the full image
docker run --rm -v $(pwd):/app -e RING_PACKAGES="jsonlib" -e RING_FILE=myapp.ring ysdragon/ring:latest

# For nightly full
docker run --rm -v $(pwd):/app -e RING_PACKAGES="jsonlib" -e RING_FILE=myapp.ring ysdragon/ring:nightly

# For nightly light
docker run --rm -v $(pwd):/app -e RING_PACKAGES="jsonlib" -e RING_FILE=myapp.ring ysdragon/ring:nightly-light
```

### Creating an Executable

To compile your Ring script into a standalone executable, set the `RING_OUTPUT_EXE` environment variable to `true`.

```bash
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring -e RING_OUTPUT_EXE=true ysdragon/ring:latest

# Or with nightly
docker run --rm -v $(pwd):/app -e RING_FILE=myapp.ring -e RING_OUTPUT_EXE=true ysdragon/ring:nightly
```

## Environment Variables

| Variable          | Description                                                                                             | Default |
| ----------------- | ------------------------------------------------------------------------------------------------------- | ------- |
| `RING_FILE`       | The path to the Ring script to execute. This is a **required** variable.                                  |         |
| `RING_VERSION`    | The version of the Ring language to use (e.g., `1.22`).                                                   | `1.23`  |
| `RING_PACKAGES`   | A space-separated list of Ring packages to install using `ringpm`.                                        |         |
| `RING_OUTPUT_EXE` | If set to `true`, compiles the Ring script into an executable.                                            | `false` |
| `RING_ARGS`       | Additional arguments to pass to the Ring Compiler/VM or `Ring2EXE`.                                       |         |

## Building Locally

To build the images locally, you can use the `docker build` command.

### Full Image

```bash
docker build -t ring-full -f Dockerfile .
```

### Light Image

```bash
docker build -t ring-light -f Dockerfile.light .
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.