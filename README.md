# erl_playground

An OTP application to start coding without the boring stuff.

## Prerequisites
This project has been written for Mac and Linux environments, theoretically speaking it can run on any environment where a Erlang system is correcty installed, but consider that MS Windows and Erlang are not best buddies. Nowadays it is pretty easy to have Linux systems running in minutes using Virtual Machines, Containers, USB distro or simply double booting your laptop.

In case you use a Mac system, we strongly recommend using [homebrew](https://brew.sh/) to manage all your packages.

**OpenSSL**

Check the correct installation process for you environment.

**Erlang/OTP 19.3**

If you are on Mac, we strongly suggest using [kerl](https://github.com/kerl/kerl) to build and install the proper Erlang version on your system. For other environments you can easily find your installation package on [ErlangSolutions](https://www.erlang-solutions.com/).

## Build & Run

This is a [rebar3](https://www.rebar3.org/) project.
In order to build you can use following commands
* `./rebar3 compile`: compile the project
* `./rebar3 release`: compile the project and create a release
* `_build/default/rel/erl_playground/bin/erl_playground console`: run the project via interactive console

or you can use the **Makefile** included in the project.

## Compile GPB

Google Protocol Buffer is automatically compiled starting from the included proto file.
[Here](https://developers.google.com/protocol-buffers/) you can find all the information about it.

## What you have out of the box
This is a playgrounf application that allows you to focus on the logic of your system, rather than the boring technical stuff. It includes a basic Erlang/OTP application structure with a TCP client and a TCP server.

# Challenge: call-center
The challenge consists of implementing a call-center simulator in **Erlang/OTP19.3**. Client and server will accept **Google Protocol Buffer** messages over **TCP**.

A user will be able to call the call-center and choose among several options. Each option, identified by a numeric id, will trigger different features. **Some of them are mandatory to pass the challenge**.

## Mandatory features
### 1. Automatic responder
By connecting to the call-center, an automatic responder process will be spawned (one per user). It will respond with the list of available options.
Example:
```sh
$ Welcome to the call-center:
Press 1 to receive the weather forecast
Press 2 to receive...
```


### 2. Weather forecast
By requesting the weather forecast you will receive a **random phrase** describing a weather condition.

### 3. Answer to the Ultimate Question of Life, the Universe, and Everything
By requesting this you will get the correct answer, **no need to explain further!** :)

### 4. Operator
By choosing this option the user is connected to an operator (*echo server process*). The Operator will respond on max 3 messages, for a limited time of 10 seconds, than the communication with the operator will be closed and the user will be sent back to the Automatic Responder.

## Optional features
*These features can't be done without completing previous mandatory points*

### Limited operators
Use the [poolboy](https://github.com/devinus/poolboy) library to implement a limited number of Operators. When all Operators are busy, the user wait 5 seconds, if an Operator become available in the time span, the user is automatically connected, otherwise an apology message is sent back.

### Chat
By choosing this option the user is connected with another user that is waiting for the chat service. The chat will last until one of the two users will write **“bye”**.

### Client
Create an additional client for you application using one of the following languages:
* `C#`
* `C++`
* `Java`

### Test
Create a test suite (using Erlang Unit Test tools) to test your code.

## Delivery
To implement the challenge **you must fork this repository branch**.

When you are satisfied with your challenge, tag the commit as **1.0.0** and send us the public link of your GitHub project (*specifing the commit id as additional check*). In case the tag is after the delivery date, we’ll consider the last commit before the delivery date.
Remember to add any relevant information on the README file. If you did the optional **Client** feature remember to add the repository link on the file.

Git usage and organization will be evaluated as part of the challenge.

You have two weeks.
**Good Luck!**

# Candidate comments
- Check and eventually modify server ip address on sys.config
- Modify name in vm.args if you need to run 2 clients on same machine
## Usage
From client console:  
* `sockclient:connect().`  
* `sockclient:send_create_session(<User>).`  
* `sockclient:user_menu().`  
