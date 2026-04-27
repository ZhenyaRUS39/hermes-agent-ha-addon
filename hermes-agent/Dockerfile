ARG BUILD_FROM
FROM $BUILD_FROM

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PYTHONUNBUFFERED=1
ENV HERMES_HOME="/data"

RUN apk add --no-cache         git         python3         py3-pip         curl     && pip3 install --no-cache-dir --break-system-packages pip     && find /usr/local         \( -type d -a -name test -o -name tests -o -name '__pycache__' \)         -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \)         -exec rm -rf '{}' + || true

ARG HERMES_VERSION=v2026.4.23

WORKDIR /opt

RUN git clone --branch ${HERMES_VERSION} --depth 1 https://github.com/NousResearch/hermes-agent.git "${HERMES_HOME}/hermes-agent" && \
    echo "Cloned Hermes Agent ${HERMES_VERSION}"

ENV HERMES_VERSION=${HERMES_VERSION}

WORKDIR "${HERMES_HOME}/hermes-agent"
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --quiet -e . && \
    echo "Hermes Agent installed"

RUN mkdir -p "${HERMES_HOME}/.hermes"

COPY rootfs /

RUN chmod +x /etc/s6-overlay/s6-rc.d/hermes/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/hermes/finish

HEALTHCHECK CMD curl --fail http://127.0.0.1:8000/health 2>/dev/null || exit 1

EXPOSE 8000

CMD ["/init"]
