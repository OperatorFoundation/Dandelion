FROM swift:latest

WORKDIR /root

RUN git clone https://github.com/OperatorFoundation/Dandelion

WORKDIR /root/Dandelion

RUN swift build
RUN swift run

EXPOSE 5771
