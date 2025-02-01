# Base Stage: Install common packages
ARG BASE_IMAGE=debian:stable-slim
FROM ${BASE_IMAGE} AS base
# https://stackoverflow.com/questions/53681522/share-variable-in-multi-stage-dockerfile-arg-before-from-not-substituted
ARG BASE_IMAGE
ARG DEV_IMAGE_NAME=dev-env
ARG DOTFILES_BASENAME
ARG DOCKSTATION_VERSION
LABEL version="${DOCKSTATION_VERSION}"
LABEL org.opencontainers.image.authors="rohailt"
LABEL org.opencontainers.image.source="https://github.com/rohailt/docstation"
LABEL maintainer.email="sigmagraphinc@gmail.com"
LABEL org.opencontainers.image.base="$BASE_IMAGE"
LABEL org.opencontainers.image.name="$DEV_IMAGE_NAME"
LABEL org.opencontainers.image.description="Base stage for development environment with common utilities."
LABEL stage="base"
LABEL org.opencontainers.image.created=$(date)


RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    tar \
    bash \
    tmux \
    bat \
    fontconfig \
    tmuxp\
    tree \
    ca-certificates \
    # For terminal support (xterm_clipboard feature)    
    vim-nox \  
    # Clipboard integration
    xclip \  
    jq \
    fd-find \
    ripgrep \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/batcat /usr/bin/bat && \
    ln -s $(which fdfind) /usr/bin/fd 

ENV SHELL=/bin/bash

# Font Installation Stage: Handle fonts in a separate stage
FROM base AS fonts
LABEL stage="fonts"
LABEL org.opencontainers.image.description="Stage for ensuring fonts and installed and configured."

RUN mkdir -p /usr/share/fonts/meslo && \
    curl -fsSL -o /usr/share/fonts/meslo/MesloLGS_NF_Regular.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Regular.ttf && \
    curl -fsSL -o /usr/share/fonts/meslo/MesloLGS_NF_Bold.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold.ttf && \
    curl -fsSL -o /usr/share/fonts/meslo/MesloLGS_NF_Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Italic.ttf && \
    curl -fsSL -o /usr/share/fonts/meslo/MesloLGS_NF_Bold_Italic.ttf https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/MesloLGS%20NF%20Bold%20Italic.ttf && \
    fc-cache -fv

FROM base AS tools
LABEL stage="tools"

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y && \
    curl -fsSL https://astral.sh/ruff/install.sh | sh && \
    curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="/usr/local/bin" sh && \
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    arch=$(uname -m) && \
    fzf_arch="" && \
    if [ "$arch" = "x86_64" ]; then \
        fzf_arch="amd64"; \
    elif [ "$arch" = "aarch64" ]; then \
        fzf_arch="arm64"; \
    else \
        echo "Unsupported architecture: $arch" && exit 1; \
    fi && \
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v0.58.0/fzf-0.58.0-linux_${fzf_arch}.tar.gz" -o /tmp/fzf.tar.gz && \
    tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/fzf && \
    # Install Node.js, npm, and Pyright
    curl -fsSL https://deb.nodesource.com/setup_18.x | sh && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g ajv-cli dockerfile-language-server-nodejs \
    bash-language-server \
    @microsoft/compose-language-service \
    pyright && \
    echo "Node.js global packages installed in: $(npm root -g)" && \
    rm /tmp/fzf.tar.gz && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]

# Bash Stage: Default bash command
FROM base AS bash
LABEL stage="bash"
ARG DOTFILES_BASENAME
LABEL org.opencontainers.image.description="Stage for configuring bash with tools."

# Copy fonts
COPY --from=fonts /usr/share/fonts /usr/share/fonts

# Copy the entire Node.js global packages directory
COPY --from=tools /usr/lib/node_modules /usr/lib/node_modules

# Copy binaries from the tools stage
COPY --from=tools /usr/bin/ /usr/bin
COPY --from=tools /usr/local/bin/ /usr/local/bin/

# Copy ruff binary from tools stage
COPY --from=tools /root/.local/bin/ruff /usr/local/bin/ruff

# Vim plug directories
COPY --from=tools /root/.vim/autoload /root/.vim/autoload

# Copy starship configuration
COPY ${DOTFILES_BASENAME}/bash-rc/starship.toml /root/.config/starship.toml

# Copy bashrc and other dotfiles
COPY ${DOTFILES_BASENAME}/bash-rc/.fzf-config /root/.fzf-config
COPY ${DOTFILES_BASENAME}/bash-rc/tmuxp/vscode_layout.yaml /root/.config/tmuxp/vscode_layout.yaml
COPY ${DOTFILES_BASENAME}/bash-rc/.bashrc /root/.bashrc
COPY ${DOTFILES_BASENAME}/bash-rc/.editorconfig /root/.editorconfig
COPY ${DOTFILES_BASENAME}/bash-rc/.terminfo /root/.terminfo

CMD ["/bin/bash"]

# Validate Stage: Ensure .env matches schema and version is correct
FROM bash AS validate
LABEL stage="validate"
LABEL org.opencontainers.image.description="Stage for validating .env schema and version."

ARG DOCKSTATION_VERSION

ARG ENV_FILE="/tmp/.env_$DEV_IMAGE_NAME"

# Copy the correct .env file based on `DEV_IMAGE_NAME`
COPY .env_${DEV_IMAGE_NAME} ${ENV_FILE}

COPY VERSION /tmp/VERSION
COPY env.schema.json /tmp/env.schema.json
COPY convert_env_to_json.sh /tmp/convert_env_to_json.sh

# Ensure the script is executable
RUN chmod +x /tmp/convert_env_to_json.sh

# **Use CMD instead of RUN** for interactive debugging
CMD ["/bin/bash"]

RUN set -eux; \
    chmod +x /tmp/convert_env_to_json.sh; \
    if ! /tmp/convert_env_to_json.sh ${ENV_FILE}; then \
      echo "❌ ERROR: Failed to convert .env to JSON"; \
      exit 1; \
    fi; \
    # Run JSON Schema validation 
    ajv validate -s /tmp/env.schema.json -d /tmp/env.json || \
    (echo "❌ .env validation failed!" && cat /tmp/env.json && exit 1); \
    # Read the repo's official version from /tmp/VERSION
    REPO_VERSION="$(cat /tmp/VERSION)"; \
    # Compare with user-provided version (FAIL FAST)
    if [ "$REPO_VERSION" != "$DOCKSTATION_VERSION" ]; then \
      echo "❌ ERROR: .env DOCKSTATION_VERSION=$DOCKSTATION_VERSION, but dockstation/VERSION=$REPO_VERSION. Aborting."; \
      exit 1; \
    fi

# Vim Plugins install
FROM validate AS vim_plugins
LABEL stage="vim_plugins"
LABEL org.opencontainers.image.description="Stage for configuring Vim with plugins."
# Copy vim-plug and plugin initialization file
COPY ${DOTFILES_BASENAME}/vim-rc/custom/plug.vim  /root/.vim/custom/plug.vim
# Add coc-settings to ~/.vim directory
COPY ${DOTFILES_BASENAME}/vim-rc/custom/coc-settings.json  /root/.vim/coc-settings.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Load entry point
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]

# Install Python 3.11 and Jupyter using uv
FROM vim_plugins AS jupyter
LABEL stage="jupyter"
LABEL org.opencontainers.image.description="Stage for configuring a python installation with a jupyter notebook interface."

RUN uv python install 3.11 && \
    uv venv .venv --python 3.11 && \
    . .venv/bin/activate && \ 
    uv pip install jupyter

ENV PATH="/root/workspace/.venv/bin:$PATH"

# Default command for Jupyter stage
CMD ["jupyter", "notebook", "--allow-root", "--ip", "0.0.0.0", "--no-browser", "&"]