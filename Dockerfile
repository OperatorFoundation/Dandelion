FROM swift:latest

# Test building of Dandelion by itself
WORKDIR /root
RUN git clone https://github.com/OperatorFoundation/Dandelion
WORKDIR /root/Dandelion
RUN git pull origin main
RUN swift package reset
RUN rm -rf Package.resolved .build .swiftpm
RUN swift build

# Test building of Shapeshifter Dispatcher for Swift with Dandelion support
WORKDIR /root
RUN git clone https://github.com/OperatorFoundation/ShapeshifterDispatcherSwift
WORKDIR /root/ShapeshifterDispatcherSwift
RUN git pull origin main
RUN swift package reset
RUN rm -rf Package.resolved .build .swiftpm
RUN swift build

# Open the dispatcher port to the world
EXPOSE 5771

# Run dispatcher
WORKDIR /root/ShapeshifterDispatcherSwift
CMD ["swift", "run"]
