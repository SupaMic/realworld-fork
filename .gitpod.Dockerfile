FROM gitpod/workspace-postgres

ENV DEBIAN_FRONTEND noninteractive
ENV ASDF_BRANCH v0.12.0
ENV ERLANG_V 25.2
ENV ELIXIR_V 1.14.2-otp-25
ENV KERL_BUILD_DOCS yes

USER root
# install dependencies here
RUN apt-get clean && apt-get update && apt-get -y install --no-install-recommends \
    build-essential inotify-tools jq xsltproc libncurses-dev automake autoconf xsltproc fop \
    && rm -rf /var/lib/apt/lists/*

USER gitpod
SHELL ["/bin/bash", "-lc"]

RUN git config --global advice.detachedHead false
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_BRANCH}

RUN sed -i '1s;^;source $HOME/.asdf/asdf.sh\nsource $HOME/.asdf/completions/asdf.bash\n;' ~/.bashrc

RUN asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf install erlang ${ERLANG_V} && \
    asdf install elixir ${ELIXIR_V}
RUN echo -e "erlang ${ERLANG_V}\nelixir ${ELIXIR_V}" > ~/.tool-versions