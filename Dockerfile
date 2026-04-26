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

# Install Hermes Agent
WORKDIR /opt

# Clone Hermes Agent (persistent in /data via map)
RUN git clone https://github.com/NousResearch/hermes-agent.git "${HERMES_HOME}/hermes-agent" && \
    echo "Cloned Hermes Agent"

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
