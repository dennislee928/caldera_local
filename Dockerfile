FROM ubuntu:focal

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

WORKDIR /usr/src/app

ENV DEBIAN_FRONTEND=noninteractive

# Make apt more resilient to transient network timeouts during docker builds
RUN printf '%s\n' \
    'Acquire::Retries "8";' \
    'Acquire::http::Timeout "60";' \
    'Acquire::https::Timeout "60";' \
    'Acquire::http::No-Cache "true";' \
    > /etc/apt/apt.conf.d/80caldera-retries

RUN apt-get update -o Acquire::Retries=8 && \
    apt-get -y install --no-install-recommends -o Acquire::Retries=8 --fix-missing ca-certificates && \
    sed -i 's|http://ports.ubuntu.com|https://ports.ubuntu.com|g' /etc/apt/sources.list && \
    apt-get update -o Acquire::Retries=8 && \
    apt-get -y install --no-install-recommends -o Acquire::Retries=8 --fix-missing \
      python3 python3-pip python3-dev \
      git \
      build-essential pkg-config \
      libffi-dev libssl-dev \
      zlib1g-dev \
      libjpeg-dev libfreetype6-dev \
      libxml2-dev libxslt1-dev && \
    apt-get -y install --no-install-recommends -o Acquire::Retries=8 --fix-missing golang && \
    rm -rf /var/lib/apt/lists/*

#WIN_BUILD is used to enable windows build in sandcat plugin
ARG WIN_BUILD=false
RUN if [ "$WIN_BUILD" = "true" ] ; then apt-get -y install mingw-w64; fi

ADD requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

ADD . .

EXPOSE 8888
EXPOSE 7010
EXPOSE 7011/udp
EXPOSE 7012

ENTRYPOINT ["python3", "server.py"]
