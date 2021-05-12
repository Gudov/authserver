%%%-------------------------------------------------------------------
%% @doc authserver public API
%% @end
%%%-------------------------------------------------------------------

-module(authserver_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    {ok, SqlPid} = mysql:start_link([
        {host, application:get_env(authserver, sql_ip, "127.0.0.1")}, 
        {user, application:get_env(authserver, sql_user, "root")},
        {password, application:get_env(authserver, sql_password, "root")}, 
        {database, application:get_env(authserver, sql_db, "db")}
    ]),

    {ok, Pid} = authserver_sup:start_link(),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", test_handler, []},
            {"/launcher_auth", lauth_handle, [SqlPid]},
            {"/CheckServer", checkserver_handle, [SqlPid]},
            {"/skin", skin_handle, []},
            {"/cloak", cloak_handle, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(
        http_lisener,
        [{port, 10280}],
        #{env => #{dispatch => Dispatch}}
    ),
    {ok, Pid}.

stop(_State) ->
    ok.

%% internal functions
