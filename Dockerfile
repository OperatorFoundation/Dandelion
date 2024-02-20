FROM swift:latest

WORKDIR /root

RUN git clone https://github.com/OperatorFoundation/Dandelion

WORKDIR /root/Dandelion

RUN git pull origin main
RUN swift package reset
RUN rm -rf Package.resolved .build .swiftpm
RUN swift build
RUN swift run

EXPOSE 5771
