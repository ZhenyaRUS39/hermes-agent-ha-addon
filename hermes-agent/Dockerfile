ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PYTHONUNBUFFERED=1
ENV HERMES_HOME="/data"
ARG HERMES_VERSION=v2026.4.23

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-venv \
    python3-pip \
    curl \
    jq \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && find /usr/local \
        \( -type d -a -name test -o -name tests -o -name '__pycache__' \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + || true

# Clone and install hermes-agent at BUILD TIME
RUN git clone --branch ${HERMES_VERSION} --depth 1 \
        https://github.com/NousResearch/hermes-agent.git \
        /opt/hermes-agent \
    && cd /opt/hermes-agent \
    && python3 -m venv venv \
    && ./venv/bin/pip install --upgrade pip \
    && ./venv/bin/pip install -e .

COPY hermes-agent/rootfs /
