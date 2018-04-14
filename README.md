# build-go-docker

Build a basic GOPATH image for building a golang program

### Usage

1. First, build an invariant image, where the code is basically a fixed third-party package.
    ```sh
    ./build.sh -d "your/project/package/name" -e "your/project/package/name" -t test/gobuild:v1
    ```

1. Then, based on the image of the first step, create a new image, copy your project code into it.
    ```sh
        ./build.sh -p "your/project/package/name" -t test/gobuild:v2 -f test/gobuild:v1
    ```

1. Finally, you can build your golang program with the test/gobuild:v2 image.


### Features

When building a golang program, you do not need to synchronize the fixed version of the package from the network or local to the image.

### Dependency

- [govendor](https://github.com/kardianos/govendor): Use govendor to analyze all third-party packages that your project depends on.