nohup java -javaagent:jmx/jmx_prometheus_javaagent-0.13.0.jar=8081:jmx/config.yaml -jar prometheus-proxy.jar --config ./simple.conf &> log.out &