# The Operator Foundation

[Operator](https://operatorfoundation.org) makes usable tools to help people around the world with censorship, security, and privacy.

## Shapeshifter

The Shapeshifter project provides network protocol shapeshifting technology
(also sometimes referred to as obfuscation). The purpose of this technology is
to change the characteristics of network traffic so that it is not identified
and subsequently blocked by network filtering devices.

There are two components to Shapeshifter: transports and the dispatcher. Each
transport provide different approach to shapeshifting. ShadowSwift is provided as a 
Swift library which can be integrated directly into applications.

If you are a tool developer working in the Swift programming language, then you
are in the right place. If you are a tool developer working in other languages we have 
several other tools available to you:

- A Go transports library that can be used directly in your application:
[shapeshifter-transports](https://github.com/OperatorFoundation/shapeshifter-transports)

- A Kotlin transports library that can be used directly in your Android application (currently supports Shadow):
[ShapeshifterAndroidKotlin](https://github.com/OperatorFoundation/ShapeshifterAndroidKotlin)

- A Java transports library that can be used directly in your Android application (currently supports Shadow):
[ShapeshifterAndroidJava](https://github.com/OperatorFoundation/ShapeshifterAndroidJava)

If you want a end user that is trying to circumvent filtering on your network or
you are a developer that wants to add pluggable transports to an existing tool
that is not written in the Swift programming language, then you probably want the
dispatcher. Please note that familiarity with executing programs on the command
line is necessary to use this tool.
<https://github.com/OperatorFoundation/shapeshifter-dispatcher>

If you are looking for a complete, easy-to-use VPN that incorporates
shapeshifting technology and has a graphical user interface, consider
[Moonbounce](https://github.com/OperatorFoundation/Moonbounce), an application for macOS which incorporates shapeshifting without
the need to write code or use the command line.

### Shapeshifter Transports

Shapeshifter Transports is a suite of pluggable transports implemented in a variety of langauges. This repository 
is an implementation of the Shadow transport in the Swift programming language. 

If you are looking for a tool which you can install and
use from the command line, take a look at [shapeshifter-dispatcher](https://github.com/OperatorFoundation/shapeshifter-dispatcher.git) instead.

ShadowSwift implements the Pluggable Transports 3.0 specification available here:
<https://github.com/Pluggable-Transports/Pluggable-Transports-spec/tree/main/releases/PTSpecV3.0> Specifically,
they implement the [Swift Transports API v3.0](https://github.com/Pluggable-Transports/Pluggable-Transports-spec/blob/main/releases/PTSpecV3.0/Pluggable%20Transport%20Specification%20v3.0%20-%20Swift%20Transport%20API%20v3.0.md).

The purpose of the transport library is to provide a set of different
transports. Each transport implements a different method of shapeshifting
network traffic. The goal is for application traffic to be sent over the network
in a shapeshifted form that bypasses network filtering, allowing
the application to work on networks where it would otherwise be blocked or
heavily throttled.

# Dandelion

## Introduction

Dandelion is an innovative new circumvention solution that combines the best in Pluggable
Transports with the new cutting-edge Turbo Tunneling approach. With Turbo Tunneling, a long-lived connection between the transport client and transport server can be split up into multiple short-lived connections while still maintaining a single long-lived virtual connection between the application client and application server. For instance, a long-lived VPN connection can be maintained over a series of short Pluggable Transport connections. As with other Pluggable Transports conforming to the Pluggable Transports Specification v3.0, it supports the proxying of both TCP application traffic (such as HTTP) and UDP application traffic (such as Wireguard) while providing obfuscation of the network traffic to avoiding blocking due to protocol identification and other Deep Packet Inspection techniques. In addition, it adds the new innovation of multi-server Turbo Tunneling. With multi-server Turbo Tunneling, each short-lived transport connection can be to a different transport server. This combination of features is specifically designed to mitigate against known attacks being deployed in-country that render previously effective transports totally ineffective.

## Architecture Overview

Dandelion is a Pluggable Transport that works in concert with other Pluggable Transports to allow for the improvised construction of effective censorship circumvention solutions. Another way to think of this is that Dandelion adds Turbo Tunnel capabilities to existing transports. In addition to basic Turbo Tunnel capabilities, it also allows a multi-server Turbo Tunnel mode, as well as limiting the duration of each individual real network connection. This avoids attacks where adversaries blocklist servers that have connections with high uptimes.

As with most Pluggable Transports, there is an application client and an application server. For instance, the application client could be a web browser and the application server would be a web server. The job of the Pluggable Transport is to get the traffic from the application client to the application server and vice versa, while avoiding being blocked by any network filtering. On the client side, this is accomplished by configuring the application client to route its traffic through the Pluggable Transport client, in this case the Dandelion client. While most Pluggable Transport clients connect directly to a Pluggable Transport server, Dandelion is more sophisticated. It is stocked with a variety of Pluggable Transport server configurations that it can use. These servers can be running on a variety of IP addresses and a variety of ports and also use a variety of Pluggable Transports. When the Dandelion client picks a configuration, it loads the appropriate Pluggable Transport client internally. For instance, if Dandelion chooses a Shadow server, then it will load the Shadow client. All traffic for the Dandelion transport is now routed through the Shadow transport, from the Shadow client to the Shadow server. The Shadow server is configured to route client traffic to a Dandelion server and vice versa. Once connected through the chosen transport, the Dandelion client and server speak the custom Dandelion protocol, facilitating Turbo Tunnel functionality. The ultimate goal is to establish a virtual tunnel for communication between the application client and application server.

The special affordance provided by Dandelion is that not only can it use any provided Pluggable Transport for its connection, it will also limit the time that connection is up. When the time is out, it will refresh its connection to the Dandelion server. This process shuts down the Pluggable Transport being used (for instance, a Shadow client) and picks a new configuration from those available (for instance, a Starbridge client). It then re-establishes a connection to the Dandelion server and uses the Dandelion protocol to resume the connection using Turbo Tunneling. This allows the application client to have one seamless connection to the application server, whose traffic is actually carried over multiple different Pluggable Transport clients, each one potentially using a different server, port, and transport type.

## Installing Dandelion Server

There are two unique components to the Dandelion architecture: the Dandelion server and the Dandelion client. You will also need some other Pluggable Transport servers and clients, such as Shadow or Starbridge. Setting up other transports is covered in the documentation for each transport, but special instructions will be provided here for integrating with Dandelion once you have followed the original setup steps.

The easiest way to run a Dandelion server is with the Shapeshifter Dispatcher for Swift command line tool. It allows for generation of configuration files and launching of servers for all supported Pluggable Transport types. The Shapeshifter Dispatcher for Swift command line tool is currently available for Ubuntu 22.04.

Clone ShapeshifterDispatcherSwift: https://github.com/OperatorFoundation/ShapeshifterDispatcherSwift.git

### Generating Configuration files

The ShapeshifterDispatcherSwift project has an executable target called ShapeshiterConfigs. Use this to create configuration files for the server and the client before running the server. To do this, run the following command, providing the full path to the directory where you would like the files to be saved: 

```
ShapeshifterConfigs dandelion --host <serverIP> --port <serverPort> --directory <pathToSaveDirectory>
```

### Running a Dandelion Server

The following command is an example of how you would use Dispatcher to run a Dandelion server pointed at a specific target server:

```
ShapeshifterDispatcherSwift -ptversion 3.0 -server  -transport dandelion -bindhost <server IP> -bindport <server port> -optionsfile <path to DandelionServerConfig.json> -targethost <target IP> -targetport <target port>
```

## Installing Dandelion Client

The Dandelion client is currently only available as a library for Android 11.

Declare the library dependency in your app/module build.gradle (or build.gradle.kts):

```
dependencies {
        implementation 'com.github.operatorfoundation:DandelionAndroid:1.0.0'
}
```

To use the library in your app/module use the following import statement:

```
import org.operatorfoundation.dandelionlibrary.Dandelion
```

(For an example of how to use the library, there is a demo application included with this library.) 

## Conclusion

Dandelion is a new Pluggable Transport that meets evolving challenges in the censorship circumvention space by defending against attacks where servers are blocklisted when the network connections to them accumulate too much uptime. It also demonstrates the power of the Pluggable Transport ecosystem by composing with other existing Pluggable Transports. Dandelion adds Turbo Tunnel support to any existing transport, while relying on the capabilities of existing transports for features such as encryption with perfect forward secrecy and probing resistance. The Dandelion transport strengthens the Pluggable Transport ecosystem by providing another modular piece that can be used to improvise responses to incidents of increased blocking, as well as defend against known emerging attacks on the most aggressive networks.
