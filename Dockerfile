FROM openjdk:8-jre

ARG DS_VERSION
ENV DS_VERSION ${DS_VERSION}

RUN set -ex \
	&& BUILD_DEPS=" \
	wget" \
	&& seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{} \
	&& apt-get update --fix-missing && apt-get install -y $BUILD_DEPS \
	&& wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash \
	&& echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile \
	&& echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.profile \
	&& echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.profile \
	&& . ~/.profile && nvm install 13.12.0 \
	&& curl -LO "https://dl.k8s.io/release/v1.20.2/bin/linux/amd64/kubectl" \
	&& install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
	&& mkdir -p /root/.ssh \
	&& echo "Host *\n    StrictHostKeyChecking no" > /root/.ssh/config \
	&& apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $BUILD_DEPS \
	&& rm -rf /var/lib/apt/lists/*

RUN apt update --fix-missing \
	&& apt install -y --no-install-recommends git ncurses-bin openssh-client sudo dnsutils docker.io docker-compose \
	&& curl https://sh.rustup.rs -sSf | sh -s -- -y \
	&& echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.profile \
	&& mkdir /root/.config \
	&& printf "DS_UPDATE=false\nDS_BUILD_DIR=/build\n" >> /root/.config/deploy-scripts-defaults.sh \
	&& git config --global init.defaultBranch master \
	&& git clone --depth=1 --single-branch --branch ${DS_VERSION} https://github.com/loanstreet/deploy-scripts /deploy-scripts \
	&& chmod +x /deploy-scripts/docker-entrypoint.sh \
	&& ln -s /deploy-scripts/docker-entrypoint.sh /usr/local/bin/deploy-scripts \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

ENTRYPOINT ["deploy-scripts"]
CMD ["--help"]
