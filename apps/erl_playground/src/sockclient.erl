-module(sockclient).
-behaviour(gen_server).

-include("erl_playground_pb.hrl").

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]). -ignore_xref([{start_link, 4}]).
-export([connect/0, disconnect/0]).
-export([send_create_session/0, send_create_session/1]).
-export([send_menu_choice/1]).

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

%% Send the user choice from options menu
send_menu_choice(Choice) ->
    MenuChoice = #menu_choice {
	choice = #'options_list.single_option'{
            key = Choice
        }
    },
    gen_server:cast(whereis(?SERVER), {menu_choice, MenuChoice}).

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

handle_cast({menu_choice, MenuChoice}, #state{socket = Socket} = State)
    when Socket =/= undefined ->
    Req = #req {
        type = menu_choice,
        menu_choice_data = MenuChoice
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
    %%PID =  spawn(fun() -> handle_user_interaction() end),
    %%register(menuhandler, PID);
    %%io:fwrite("~p~n",[registered()]);

    %% ----------------------
    %% Message type Options List  *******************
    %% ----------------------
    options_list ->
    #req{
        options_list_data = #options_list{
            options = Options
        }
    } = Req,
    
    %% XXX find spawned process. 
    %%io:fwrite("~p~n",[whereis(menuhandler)]),
    %%whereis(menuhandler) ! {optionlist, Options}

    %% print Options Menu
    choose_menu(Options)
    %%io:format("Choosen Option: ~d", Choice)
    end,
    State.

%% TODO should probably handle user choice but it's not working for now
%% send_menu_choice should be called from user
choose_menu(Opts) ->
    lists:foldl(fun(X, Index) -> 
	#'options_list.single_option'{
            key = Key,
            value = Value
        } = X,
        io:format("~p. ~s~n", [Key, Value]),
        %%io:format("~p to ~p~n", [Index, X]),
        Index+1 
        end, 
        1, Opts).
    %% XXX fread not working if is called inside another function?
    %%{ok, [Choice]}= io:fread("Choose an Option: ", "~d"),
    %%io:format("Choosen Option: ~d", Choice),
    %%Choice.

%% XXX Handles messages on a spawned process. 
%% avoid callback locking?
%% fread is not working if this function is called inside another function?
%%handle_user_interaction() ->
%%    receive
%%        {optionlist, OptionList} ->
%%            lists:foldl(fun(X, Index) -> io:format(" Press ~p to ~s~n", [Index, X]), Index+1 end, 1, OptionList),
%%            case io:fread("Choose an Option: ", "~d") of
%%                {ok, [Choice]} ->
%%                    io:format("Choosen Option: ~d", Choice),
%%                    Choice
%%            end
%%    end.
    
