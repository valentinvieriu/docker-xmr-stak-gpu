###
# Build image
###
FROM nvidia/cuda:8.0-devel-ubuntu16.04 AS build

ENV XMR_STAK_GPU_VERSION v1.1.1-1.4.0

WORKDIR /usr/local/src


RUN apt-get update \
    && apt-get -qq --no-install-recommends install \
        libmicrohttpd10 \
        libssl1.0.0 \
    && rm -r /var/lib/apt/lists/*

COPY app /app

RUN set -x \
    && buildDeps=' \
        git \
        libmicrohttpd-dev \
        libssl-dev \
        cmake \
        cmake-curses-gui \
        build-essential \
    ' \
    && apt-get -qq update \
    && apt-get -qq --no-install-recommends install $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    \
    && mkdir -p /usr/local/src/xmr-stak-nvidia \
    && cd /usr/local/src/xmr-stak-nvidia/ \
    && git config --system http.sslverify false \
    && git clone https://github.com/fireice-uk/xmr-stak-nvidia.git . \
    && git checkout -b build ${XMR_STAK_GPU_VERSION} \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' donate-level.h \
    && cmake -DCMAKE_LINK_STATIC=ON -DHWLOC_ENABLE=OFF -DMICROHTTPD_ENABLE=OFF -DCUDA_ARCH=61 . \
    && make -j$(nproc) \
    && cp bin/xmr-stak-nvidia /usr/local/bin/ \
    && cp -t /app bin/xmr-stak-nvidia config.txt \
    && chmod 777 -R /app \
    && rm -r /usr/local/src/xmr-stak-nvidia \
    && apt-get -qq --auto-remove purge $buildDeps


###
# Deployed image
###
FROM nvidia/cuda:8.0-devel-ubuntu16.04

WORKDIR /app

RUN set -x \
    && buildDeps=' \
        git \
        libmicrohttpd-dev \
      openssl \
      hwloc \
      python2.7 \
      python-pip \
      python-setuptools \
    ' \
    && apt-get -qq update \
    && apt-get -qq --no-install-recommends install $buildDeps \
    && pip install --upgrade pip \
    && pip install envtpl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build app .

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["xmr-stak-nvidia"]

