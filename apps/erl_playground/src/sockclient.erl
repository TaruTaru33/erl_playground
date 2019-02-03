-module(sockclient).
-behaviour(gen_server).

-include("erl_playground_pb.hrl").

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]). -ignore_xref([{start_link, 4}]).
-export([connect/0, disconnect/0]).
-export([send_create_session/0, send_create_session/1]).
%%-export([send_menu_choice/1]).
-export([user_menu/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, terminate/2, code_change/3]).
-export([handle_call/3, handle_cast/2, handle_info/2]).

%% ------------------------------------------------------------------
%% Record Definitions
%% ------------------------------------------------------------------

-record(state, {
    socket :: any()
}).
-type state() :: #state{}.

%% ------------------------------------------------------------------
%% Macro Definitions
%% ------------------------------------------------------------------

-define(SERVER, ?MODULE).
-define(CB_MODULE, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

start_link() ->
    lager:info("CLIENT START LINK"),
    {ok, _} = gen_server:start_link({local, ?SERVER}, ?CB_MODULE, [], []).

-spec connect() -> ok.
connect() ->
    gen_server:call(whereis(?SERVER), connect),
    ok.

-spec disconnect() -> ok.
disconnect() ->
    gen_server:call(whereis(?SERVER), disconnect),
    ok.

-spec send_create_session() -> ok.

%% handles different usernames
send_create_session(User) ->
    Usr = if User == "" -> "TestUser";
	  true -> User
	  end, 

    CreateSession = #create_session {
        username = Usr
    },
    gen_server:cast(whereis(?SERVER), {create_session, CreateSession}).

%% Send a default username
send_create_session() ->
    sockclient:send_create_session(<<"TestUser">>).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

%% This function is never called. We only define it so that
%% we can use the -behaviour(gen_server) attribute.
init(_ARgs) ->
    lager:info("sockclient init'ed"),
    {ok, #state{}}.

handle_cast({create_session, CreateSession}, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    Req = #req {
        type = create_session,
        create_session_data = CreateSession
    },
    Data = utils:add_envelope(Req),

    gen_tcp:send(Socket, Data),

    {noreply, State};

handle_cast({weather, Weather}, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    Req = #req {
        type = weather,
        weather_data = Weather
    },
    Data = utils:add_envelope(Req),

    gen_tcp:send(Socket, Data),

    {noreply, State};

handle_cast({question, Question}, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    Req = #req {
        type = question,
        question_data = Question
    },
    Data = utils:add_envelope(Req),

    gen_tcp:send(Socket, Data),

    {noreply, State};

handle_cast({echo, Echo}, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    Req = #req {
        type = echo,
        echo_data = Echo
    },
    Data = utils:add_envelope(Req),

    gen_tcp:send(Socket, Data),

    {noreply, State};

handle_cast(Message, State) ->
    _ = lager:warning("No handle_cast for ~p", [Message]),
    {noreply, State}.

handle_info({tcp_closed, _Port}, State) ->
    {noreply, State#state{socket = undefined}};
handle_info({tcp, _Port, Packet}, State) ->
    Req = utils:open_envelope(Packet),
    State = process_packet(Req, State, utils:unix_timestamp()),
    {noreply, State};
handle_info(Message, State) ->
    _ = lager:warning("No handle_info for~p", [Message]),
    {noreply, State}.

handle_call(connect, _From, State) ->
    {ok, Host} = application:get_env(erl_playground, tcp_host),
    {ok, Port} = application:get_env(erl_playground, tcp_port),

    {ok, Socket} = gen_tcp:connect(Host, Port, [binary, {packet, 2}]),

    {reply, normal, State#state{socket = Socket}};
handle_call(disconnect, _From, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    
    gen_tcp:shutdown(Socket, read_write),

    {reply, normal, State};
handle_call(Message, _From, State) ->
    _ = lager:warning("No handle_call for ~p", [Message]),
    {reply, normal, State}.

terminate(Reason, _State) ->
    _ = lager:notice("terminate ~p", [Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

-spec process_packet(Req :: #req{}, State :: state(), Now :: integer()) -> NewState :: state().
process_packet(undefined, State, _Now) ->
    lager:notice("server sent invalid packet, ignoring"),
    State;
process_packet(#req{ type = Type } = Req, State, _Now) ->
    %% Switch message type
    case Type of
    %% ----------------------
    %% Message type Server Message  ******************
    %% ----------------------
    server_message ->
    #req{
        server_message_data = #server_message{
            message = Message
        }
    } = Req,
    %% Message contains Username
    _ = lager:info("server_message received: ~s", [Message]),
    io:format("Welcome ~s!\n", [Message]);
    
    %% XXX will spawn another process to avoid callback locking?
    %%PID =  spawn(fun() -> user_menu() end),
    %%register(menuhandler, PID);
    %%io:fwrite("~p~n",[registered()]);

    %% ----------------------
    %% Message type Weather Message  ******************
    %% ----------------------
    weather -> 
    #req{
        weather_data = #weather{
            msg = Msg
        }
    } = Req,
    io:format("Weather ~s!\n", [Msg]);
    %% XXX call user_menu here?
    %%user_menu();

    %% ----------------------
    %% Message type Question Message  ******************
    %% ----------------------
    question -> 
    #req{
        question_data = #question{
            msg = Msg
        }
    } = Req,
    io:format("~s!\n", [Msg]);
    %% XXX call user_menu here?
    %%user_menu();

    %% ----------------------
    %% Message type Question Message  ******************
    %% ----------------------
    echo ->
    #req{
        echo_data = #echo{
            msg = Msg
        }
    } = Req,
    io:format("~s!\n", [Msg]),
    %% connect to echo server
    {ok, Host} = application:get_env(erl_playground, tcp_host),
    {ok, Port} = application:get_env(erl_playground, tcp_port),
    {ok, Sock} = gen_tcp:connect(Host, Port+1, 
                                 [binary, {packet, 0}]),
    %%_ = rand:seed(exs1024),
    handle_echo_connection(Sock)	
    %% XXX call user_menu here?
    %%user_menu();
    end,
    State.

%% XXX should be internal but fread not working when called by another function (process?)
user_menu() ->
    io:format("1. Press 1 to receive the Weather forecast.~n"),
    io:format("2. Press 2 to receive the Answer to the Ultimate Question of Life, the Universe and Everything.~n"),
    io:format("3. Press 3 to speak with an operator.~n"),
    {ok, [Choice]} = io:fread("Choose an Option: ", "~d"),
    case Choice of
    1 -> 
    send_weather_request();
    2 -> 
    send_question_request();
    3 ->
    send_echo_request();
    _ -> 
    _ = lager:info("Invalid Choice")
    end,
    Choice.

send_weather_request() ->
    Weather = #weather {
    },
    gen_server:cast(whereis(?SERVER), {weather, Weather}).

send_question_request() ->
    Question = #question {
    },
    gen_server:cast(whereis(?SERVER), {question, Question}).

send_echo_request() ->
    Echo = #echo {
    },
    gen_server:cast(whereis(?SERVER), {echo, Echo}).


%% Echo server message handling
handle_echo_connection(Socket) ->

     receive

         {tcp, Socket, Data} ->

             ok = io:format("~p: Client Received ~p~n", [self(), Data]),

             %% XXX check. not working. use a random sleep and send a message automatically
             %%{ok, [Val]}= io:fread("Send to server: ", "~d"),
             Val = rand:uniform(5),
             _ = lager:info("Sleep for ~p.~n", [Val]),
             timer:sleep(timer:seconds(Val)),
             Ret = gen_tcp:send(Socket, [Val]),
             case Ret of
             ok -> 
                 handle_echo_connection(Socket);
             _ -> 
                 _ = lager:info("Socket Closed. exit."),
                 exit(normal)
             end;
             

         {tcp_closed, Socket} ->

             ok = io:format("~p: Connection closed.~n", [self()]),

             exit(normal);

         _ ->

             ok = io:format("Error. Closing.~n"),

             exit(normal)

     end.
