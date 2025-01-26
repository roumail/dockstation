# Dev env setup

This project contains docker-compose files for dev tools like vim and bash. The
Vim setup, in particular, allows you to open any directory in a pre-configured
Vim environment running inside a Docker container. This project is designed to
work alongside the [dotfiles](git@github.com:roumail/dotfiles.git) repo,
which contains various configuration files. It's expected to be checked
out next to this project so we can use `..` to reference files within that
directory.

## Features

- Vim Configs and Plugins: Pre-configured Vim environment with essential plugins.
- Directory Mounting: Mount any project directory from your host machine into the container.
- Cross-Platform Bootstrap: Quickly set up the same Vim environment across different machines (Windows, macOS, etc.).
- Config Experimentation: Easily experiment with configuration changes or run multiple containers with different configurations.
- Host-Based Plugin Persistence: Store Vim plugins on the host machine, reducing image size and ensuring persistence across container rebuilds.

## Directory Structure

Apart from this repository and the dotfiles repository, you typically load the directory you want to work on as well. This folder is specified using a .env file, which expects the following values:

- HOST_APP_DIR: The path to the project directory on your host machine.
- BASE_IMAGE: The base Docker image that includes your project dependencies.
- DEV_IMAGE_NAME: A descriptive name for your development environment image (e.g., vim_env_go_tutorial).
- PLUGINS_DIR: A directory to hold plugins installed in the container.
- BASH_HISTORY_FPATH: Path to bash history file for the mounted directory. This
  follows the convention of ~/bash_histories/${DEV_IMAGE_NAME}-bash_history.
- DOTFILES_BASENAME: This is the relative path to the directory containing a 
specific git checkout of your dotfiles repository.
- DOTFILES_DIR: The path to your dotfiles repository on the host machine. This 
can be a plain checkout or a git worktree. 
- VIM_DOTFILES_DIR: Directory within the dotfiles repository containing Vim configuration files.
- VIM_RC_FPATH: Path to the .vimrc file within the Vim dotfiles directory.
- VIM_CONFIG_DIR: Path to the .vim/config directory within the Vim dotfiles directory.

```bash
/path/to/
├── dev-env-setup/           # This repository
├── dotfileswt/              # Your dotfiles repository
└── your-project/            # The project you are working on

```
>NOTE: Do not depend on `~` in your `.env` declarations as those don't always 
expand appropriately

As a concrete example, if we wanted to host this repo inside a containerized
vim session, we'd use the following build command:
`HOST_APP_DIR=$(pwd) docker-compose --env-file .env build vim`

with the `.env`

```bash
BASE_IMAGE=debian:stable-slim
DEV_IMAGE_NAME=dev_env_test
PLUGINS_DIR=~/vim_plugins/
# Define the basename for the dotfiles directory (relative path from root)
DOTFILES_BASENAME=dotfileswt/main
# DOTFILES_BASENAME=dotfileswt/golang-lsp
# DOTFILES_BASENAME=dotfiles # checkouted out without worktree
DOTFILES_DIR=/path/to/${DOTFILES_BASENAME}
VIM_DOTFILES_DIR=${DOTFILES_DIR}/vim-rc
VIM_RC_FPATH=${VIM_DOTFILES_DIR}/.vimrc
VIM_CONFIG_DIR=${VIM_DOTFILES_DIR}/.vim/config
BASH_HISTORY_FPATH=/path/to/bash_histories/${DEV_IMAGE_NAME}-bash
```

## Quick Start

Clone or copy the `dotfiles` repository to your machine, `next` to this project.

Ensure you have Docker desktop installed. Let's assume we're interested in working
with a project checked out here: `/Users/rohailtaimour/home/1_Projects/go-tutorial`
which has a dependency on `go` version `1.2.4`.

The contents of the `.env` file in this case would be

```bash
HOST_APP_DIR=/path/to/go-tutorial
BASE_IMAGE=golang:1.23.4
DEV_IMAGE_NAME=go_tutorial
PLUGINS_DIR=/Users/rohailtaimour/vim_plugins/
# Define the basename for the dotfiles directory (relative path from root)
DOTFILES_BASENAME=dotfileswt/golang-lsp
DOTFILES_DIR=/path/to/${DOTFILES_BASENAME}
VIM_DOTFILES_DIR=${DOTFILES_DIR}/vim-rc
VIM_RC_FPATH=${VIM_DOTFILES_DIR}/.vimrc
VIM_CONFIG_DIR=${VIM_DOTFILES_DIR}/.vim/config
BASH_HISTORY_FPATH=/Users/rohailtaimour/bash_histories/${DEV_IMAGE_NAME}-bash_history
```
Then you can go to the project directory and run the build command
```bash
cd /path/to/go-tutorial
docker-compose --env-file .env -f /path/to/dev-env-setup/docker-compose.yml build vim
```

This would ensure that we're able to have an environment, configured with `Go`
for our project.

```bash
docker-compose --env-file .env -f /path/to/dev-env-setup/docker-compose.yml run --rm vim
```

The directory `HOST_APP_DIR` will point to the location `/root/workspace` in
the container and the built image will be name `DEV_IMAGE_NAME`. At this point,
if you have an empty `$PLUGINS_DIR` it will be populated at runtime with the
result of installing the plugins.

## Known caveats

### Clipboard Sync

Running Vim inside a container presents challenges for clipboard access between the host and the container. Currently, Vim can only access the container's clipboard. To enable clipboard sharing between the host and the container, consider the following options:

1. SSH with X11 Forwarding:

- Install xclip or xsel inside the container.
- Use ssh -X to enable X11 forwarding for clipboard commands.
- Manually sync the clipboard or automate the process with scripts.

2. Bracketed Paste: Use terminal emulators that support bracketed paste (e.g., iTerm2, Alacritty) to allow standard Ctrl/Cmd+C/V operations.
3. Clipboard Sharing Tools: Explore tools like clipboardctl or xsel that facilitate clipboard sharing between the host and the container.
