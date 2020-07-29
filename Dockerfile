FROM registry.access.redhat.com/ubi8/ubi:8.2-343

RUN dnf -y --disableplugin=subscription-manager module enable ruby:2.5 && \
    dnf -y --disableplugin=subscription-manager --setopt=tsflags=nodocs install \
    # ruby 2.5 via module
    ruby-devel \
    # build utilities
    gcc-c++ git make redhat-rpm-config \
    # libraries
    postgresql-devel openssl-devel libxml2-devel \
    #ImageMagick deps
    autoconf libpng-devel libjpeg-devel librsvg2 && \ 

    dnf clean all

# Compile ImageMagick 6 from source.
COPY docker-assets/ImageMagick6-6.9.10-90.tar.gz /tmp/
RUN cd /tmp/ && tar -xf ImageMagick6-6.9.10-90.tar.gz && cd ImageMagick6-6.9.10-90 && \
    ./configure --prefix=/usr --disable-docs && \
    make install && \
    cd $WORKDIR && rm -rvf /tmp/ImageMagick*

ENV WORKDIR /opt/catalog-api/
ENV RAILS_ROOT $WORKDIR
WORKDIR $WORKDIR

COPY Gemfile $WORKDIR
RUN echo "gem: --no-document" > ~/.gemrc && \
    gem install bundler --conservative --without development:test && \
    bundle install --jobs 8 --retry 3 && \
    find $(gem env gemdir)/gems/ | grep "\.s\?o$" | xargs rm -rvf && \
    rm -rvf $(gem env gemdir)/cache/* && \
    rm -rvf /root/.bundle/cache

COPY . $WORKDIR
COPY docker-assets/entrypoint /usr/bin
COPY docker-assets/run_rails_server /usr/bin

RUN chgrp -R 0 $WORKDIR && \
    chmod -R g=u $WORKDIR

EXPOSE 3000

ENTRYPOINT ["entrypoint"]
CMD ["run_rails_server"]
