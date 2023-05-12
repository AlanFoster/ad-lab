FROM ubuntu:22.04
WORKDIR /ansible

# to use the 'ssh' connection type with passwords or pkcs11_provider, you must install the sshpass program
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install python3-pip curl sshpass

RUN python3 -m pip install ansible

COPY ./ansible/requirements.yml .
RUN ansible-galaxy install -r requirements.yml
