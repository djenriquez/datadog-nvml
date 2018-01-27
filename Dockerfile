FROM nvidia/cuda:9.1-devel

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.21.0-1 \
    DD_ETC_ROOT=/etc/dd-agent \
    PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:${PATH}" \
    PYTHONPATH=/opt/datadog-agent/agent \
    DD_CONF_LOG_TO_SYSLOG=no \
    NON_LOCAL_TRAFFIC=yes \
    DD_SUPERVISOR_DELETE_USER=yes \
    DD_CONF_PROCFS_PATH="/host/proc"

# Install the Agent
RUN echo "deb http://apt.datadoghq.com/ stable main" > /etc/apt/sources.list.d/datadog.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 \
 && apt-get update \
 && apt-get install --no-install-recommends -y datadog-agent="${AGENT_VERSION}" \
 && apt-get install --no-install-recommends -y ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download required scripts
RUN curl https://raw.githubusercontent.com/DataDog/docker-dd-agent/master/probe.sh > /probe.sh && \
    curl https://raw.githubusercontent.com/DataDog/docker-dd-agent/master/entrypoint.sh > /entrypoint.sh && \
    curl https://raw.githubusercontent.com/DataDog/docker-dd-agent/master/conf.d/docker_daemon.yaml > ${DD_ETC_ROOT}/conf.d/docker_daemon.yaml && \
    curl https://raw.githubusercontent.com/DataDog/docker-dd-agent/master/config_builder.py > /config_builder.py && \
    chmod +x /probe.sh /entrypoint.sh /config_builder.py


# Configure the Agent
# 1. Remove dd-agent user from init.d configuration
# 2. Fix permission on /etc/init.d/datadog-agent
# 3. Make healthcheck script executable
RUN mv ${DD_ETC_ROOT}/datadog.conf.example ${DD_ETC_ROOT}/datadog.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && chmod +x /etc/init.d/datadog-agent \
 && chmod +x /probe.sh


# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD ./probe.sh

# Install Nvidia python library + add ngi644/datadog_nvml check
RUN /opt/datadog-agent/embedded/bin/pip install nvidia-ml-py==7.352.0 && \
    curl https://raw.githubusercontent.com/ngi644/datadog_nvml/master/nvml.py > /etc/dd-agent/checks.d/nvml.py && \
    curl https://raw.githubusercontent.com/ngi644/datadog_nvml/master/nvml.yaml.default > /etc/dd-agent/conf.d/nvml.yaml.default

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]

