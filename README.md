# datadog-nvml
Datadog Agent /w NVIDIA Drivers

```
docker run -d \
--net host \
--name dd-agent \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
-v /proc/:/host/proc/:ro \
-v /cgroup/:/host/sys/fs/cgroup:ro \
-e API_KEY=${DD_API_KEY} \
-e SD_BACKEND=docker djenriquez/datadog-nvml:latest
```