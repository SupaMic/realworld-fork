FROM gitpod/workspace-postgres
USER root
ENV DEBIAN_FRONTEND noninteractive

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0 \
    && echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc \
    && echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

RUN exec "$SHELL"
    
RUN asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
