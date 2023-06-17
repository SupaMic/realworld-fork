FROM gitpod/workspace-postgres
USER gitpod
ENV DEBIAN_FRONTEND noninteractive
ENV ASDF_BRANCH v0.12.0
ENV ERLANG_V 25.2
ENV ELIXIR_V 1.14.2-otp-25

SHELL ["/bin/bash", "-lc"]

RUN git config --global advice.detachedHead false
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_BRANCH}
RUN sed -i '1s;^;source $HOME/.asdf/asdf.sh\nsource $HOME/.asdf/completions/asdf.bash\n;' ~/.bashrc

RUN asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf install erlang ${ERLANG_V} && \
    asdf install elixir ${ELIXIR_V} 