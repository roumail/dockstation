# Dockstation

This project contains definitions for dev tools like vim, bash and their
corresponding dotfiles via a submodule pointing to the repository [here](git@github.com:roumail/dotfiles.git). The Vim setup, in particular, allows you to open any directory in a pre-configured
Vim environment running inside a Docker container. 

While normally there ought to be a single configuration that you use, you do have
the possibility of having multiple configurations in parallel. See section below: 

## Features

- Vim Configs and Plugins: Pre-configured Vim environment with essential plugins.
- Directory Mounting: Mount any project directory from your host machine into the container.
- Cross-Platform Bootstrap: Quickly set up the same Vim environment across different machines (Windows, macOS, etc.).
- Config Experimentation: Easily experiment with configuration changes or run multiple containers with different configurations.
- Host-Based Plugin Persistence: Store Vim plugins on the host machine, reducing image size and ensuring persistence across container rebuilds.

The schema of the `.env` is in the `.env.schema.json` file.

## Quick Start 
1. Ensure you have Docker installed on your PC. 
2. Create a `.env` file inside the project directory you want to mount.
3. Place the `build_with_env.sh` script in your `$PATH` so you can call it in 
the directory you want to mount into the containerized environment. 
4. When building, pass ...
5. Once build is successful, you're not able to do ...


Let's assume we're interested in working
with a project checked out here: `/Users/rohailtaimour/home/1_Projects/go-tutorial`
which has a dependency on `go` version `1.2.4`.

The contents of the `.env` file in this case would be

```bash
DOCKSTATION_VERSION=0.0.0
HOST_APP_DIR=/path/to/go-tutorial
BASE_IMAGE=golang:1.23.4
DEV_IMAGE_NAME=go_tutorial
PLUGINS_DIR=/Users/rohailtaimour/vim_plugins/
DOTFILES_BASENAME=dotfiles
DOTFILES_DIR=/path/to/${DOTFILES_BASENAME}
VIM_DOTFILES_DIR=${DOTFILES_DIR}/vim-rc
VIM_RC_FPATH=${VIM_DOTFILES_DIR}/.vimrc
VIM_CONFIG_DIR=${VIM_DOTFILES_DIR}/.vim/config
BASH_HISTORY_FPATH=/Users/rohailtaimour/bash_histories/${DEV_IMAGE_NAME}-bash_history
COC_DATA_DIR=/Users/rohailtaimour/vim-coc
```

Then you can go to the project directory and run the build command

```bash
cd /path/to/go-tutorial
build_with_env.sh build
```

This would ensure that we're able to have an environment, configured with `Go`
for our project.

```bash
build_with_env.sh run
```

The directory `HOST_APP_DIR` will point to the location `/root/workspace` in
the container and the built image will be name `DEV_IMAGE_NAME`. At this point,
if you have an empty `$PLUGINS_DIR` it will be populated at runtime with the
result of installing the plugins.

## Known caveats

### Volume mounts and file paths

> NOTE: Do not depend on `~` in your `.env` declarations as those don't always
> expand appropriately

### Clipboard Sync

Running Vim inside a container presents challenges for clipboard access between the host and the container. Currently, Vim can only access the container's clipboard. To enable clipboard sharing between the host and the container, consider the following options:

1. SSH with X11 Forwarding:

- Install xclip or xsel inside the container.
- Use ssh -X to enable X11 forwarding for clipboard commands.
- Manually sync the clipboard or automate the process with scripts.

2. Bracketed Paste: Use terminal emulators that support bracketed paste (e.g., iTerm2, Alacritty) to allow standard Ctrl/Cmd+C/V operations.
3. Clipboard Sharing Tools: Explore tools like clipboardctl or xsel that facilitate clipboard sharing between the host and the container.

### Debugging

Use the services `tools` or `bash` to see how you can for example, reduce the 
image size, diagnose why binaries are not found as expected, etc.  

```yaml
 # useful for debugging
  # docker-compose --env-file .env -f /Users/rohailtaimour/home/2_AREAS/work/dockstation/docker-compose.yml build tools --no-cache
  tools: 
    build:
      context: .
      dockerfile: Dockerfile
      <<: *build-args
      target: tools
    image: rohailt/${DEV_IMAGE_NAME}-tools-debug
    working_dir: /root/workspace
    stdin_open: true
    environment:
      # where extensions are added
      XDG_CONFIG_HOME: /coc
    tty: true
    volumes: *dotfiles_and_app_dir
  bash: 
    build:
      context: .
      dockerfile: Dockerfile
      <<: *build-args
      target: bash
    image: rohailt/${DEV_IMAGE_NAME}-bash-debug
    working_dir: /root/workspace
    stdin_open: true
    environment:
      # where extensions are added
      XDG_CONFIG_HOME: /coc
    tty: true
    volumes: *dotfiles_and_app_dir
```