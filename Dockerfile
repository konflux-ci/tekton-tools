FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5-1731518200

USER 0
# Make sure the only repos we have are the ones fetched by the compose task
RUN cd /etc/yum.repos.d \
    && for f in $(ls -1 | grep -v tmp); do rm $f; done \
    && ls -l /etc/yum.repos.d
RUN microdnf install -y zsh
