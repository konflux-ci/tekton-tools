FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4-1134

USER 0
RUN ls -l /etc/yum.repos.d
RUN microdnf install -y zsh
