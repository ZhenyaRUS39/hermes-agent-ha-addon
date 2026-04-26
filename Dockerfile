ARG BUILD_FROM
FROM $BUILD_FROM

ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PYTHONUNBUFFERED=1
ENV HERMES_HOME="/data"

# Install git, Python, and curl
RUN apk add --no-cache \
        git \
        python3 \
        py3-pip \
        curl \
    && pip3 install --no-cache-dir --break-system-packages pip \
    && find /usr/local \
        \( -type d -a -name test -o -name tests -o -name '__pycache__' \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + || true

# Pin specific Hermes version (update this when new release is available)
# Check https://github.com/NousResearch/hermes-agent/releases for latest
ARG HERMES_VERSION=v0.11.0

# Install Hermes Agent
WORKDIR /opt

# Clone specific tagged release (depth=1 for faster clone)
RUN git clone --branch ${HERMES_VERSION} --depth 1 https://github.com/NousResearch/hermes-agent.git "${HERMES_HOME}/hermes-agent" && \
    echo "Cloned Hermes Agent ${HERMES_VERSION}"

# ARG for build-time, ENV for runtime
ENV HERMES_VERSION=${HERMES_VERSION}

# Set up venv and install Hermes with dependencies
WORKDIR "${HERMES_HOME}/hermes-agent"
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --quiet -e . && \
    echo "Hermes Agent installed"

# Create Hermes config directory
RUN mkdir -p "${HERMES_HOME}/.hermes"

# Copy service files
COPY rootfs /

# Make service scripts executable (s6-overlay style)
RUN chmod +x /etc/s6-overlay/s6-rc.d/hermes/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/hermes/finish

# Healthcheck - Hermes gateway health endpoint
HEALTHCHECK CMD curl --fail http://127.0.0.1:8000/health 2>/dev/null || exit 1

# Default port
EXPOSE 8000

# Run entrypoint
CMD ["/init"]
