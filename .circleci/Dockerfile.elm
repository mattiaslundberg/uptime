FROM ubuntu:latest

RUN apt-get update -y -qq && apt-get install -y -qq git g++ make bash gnupg curl
RUN git clone https://github.com/obmarg/libsysconfcpus.git &&\
    cd libsysconfcpus &&\
    ./configure &&\
    make && make install

RUN useradd -ms $(which bash) asdf

ENV PATH /home/asdf/.asdf/bin:/home/asdf/.asdf/shims:$PATH

USER asdf

ENV NODEJS_CHECK_SIGNATURES no

RUN /bin/bash -c "git clone https://github.com/asdf-vm/asdf.git ~/.asdf && \
                  asdf plugin-add nodejs && \
                  asdf plugin-add elm"

RUN mkdir /home/asdf/repo/
WORKDIR /home/asdf/repo/

ADD --chown=asdf uptime_gui/assets/elm /home/asdf/repo

RUN /bin/bash -c "asdf install && asdf install && rm -rf /tmp/*"

CMD /bin/bash -c "elm-package install -y && \
                  elm-make App.elm"
