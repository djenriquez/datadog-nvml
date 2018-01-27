FROM datadog/docker-dd-agent:latest

RUN /opt/datadog-agent/embedded/bin/pip install nvidia-ml-py==7.352.0