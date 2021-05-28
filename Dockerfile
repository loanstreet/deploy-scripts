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
	&& apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $BUILD_DEPS \
	&& rm -rf /var/lib/apt/lists/*

RUN apt update --fix-missing \
	&& apt install -y --no-install-recommends git ncurses-bin openssh-client sudo \
	&& mkdir /root/.config \
	&& printf "DS_UPDATE=false\nDS_BUILD_DIR=/build\n" >> /root/.config/deploy-scripts-defaults.sh \
	&& git config --global init.defaultBranch master \
	&& git clone --depth=1 --single-branch --branch ${DS_VERSION} https://github.com/loanstreet/deploy-scripts /root/.deploy-scripts \
	&& chmod +x /root/.deploy-scripts/docker-entrypoint.sh \
	&& ln -s /root/.deploy-scripts/docker-entrypoint.sh /usr/local/bin/deploy-scripts \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/

ENTRYPOINT ["deploy-scripts"]
CMD ["--help"]
