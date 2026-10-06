FROM nvcr.io/nvidia/cuda:13.3.1-devel-ubuntu24.04

ARG USERNAME=cudadev


RUN usermod --login ${USERNAME} --move-home --home /home/${USERNAME} ubuntu && \
    groupmod --new-name ${USERNAME} ubuntu && \
    apt-get update && apt-get install -y --no-install-recommends \
    git build-essential gdb sudo curl ca-certificates wget zsh \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Install mise
ENV MISE_INSTALL_PATH=/usr/local/bin/mise
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise
ENV PATH="/opt/mise/shims:$PATH"

RUN curl -fsSL https://mise.run | sh

# Install Zsh plugins globally
RUN mkdir -p /opt/zsh-plugins \
    && git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions /opt/zsh-plugins/zsh-autosuggestions \
    && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting /opt/zsh-plugins/zsh-syntax-highlighting \
    && chmod -R 755 /opt/zsh-plugins

RUN \
    # Basic Zsh history settings
    echo 'HISTFILE=~/.zsh_history' >> /etc/zsh/zshrc && \
    echo 'HISTSIZE=10000' >> /etc/zsh/zshrc && \
    echo 'SAVEHIST=10000' >> /etc/zsh/zshrc && \
    echo 'setopt appendhistory' >> /etc/zsh/zshrc && \
    # Load plugins
    echo 'autoload -Uz compinit && compinit' >> /etc/zsh/zshrc && \
    echo 'source /opt/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc && \
    echo 'source /opt/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc && \
    # Initialize mise and starship for Zsh
    echo 'eval "$(mise activate zsh)"' >> /etc/zsh/zshrc && \
    echo 'eval "$(starship init zsh)"' >> /etc/zsh/zshrc && \
    # Provide a fallback for bash users
    echo 'eval "$(mise activate bash)"' >> /etc/bash.bashrc

RUN mise use --global cmake@3.31 starship@latest && \
    chmod -R 777 /opt/mise

USER $USERNAME
WORKDIR /workspace