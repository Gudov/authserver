-module(checkserver_handle).
-behaviour(cowboy_handler).

-export([init/2, terminate/3]).

get_random_string(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
                        [lists:nth(random:uniform(length(AllowedChars)),
                                   AllowedChars)]
                            ++ Acc
                end, [], lists:seq(1, Length)).

init(Req0, [SqlPid]) ->
    {ok, Data, Req} = cowboy_req:read_body(Req0),
    {JsonData} = jiffy:decode(Data),
    Login = proplists:get_value(<<"login">>, JsonData, empty),
    ServerID = proplists:get_value(<<"serverID">>, JsonData, empty),
    UUID = proplists:get_value(<<"uuid">>, JsonData, empty),
    AccessToken = proplists:get_value(<<"accessToken">>, JsonData, empty),
    io:format("~p ~p ~p ~p ~n", [Login, ServerID, UUID, AccessToken]),
    case {Login, ServerID, UUID, AccessToken} of
        {Login, empty, empty, empty} ->
            {ok, _ColumnNames, [[UUIDFetch, ServerIDFetch]]} = mysql:query(SqlPid, <<"SELECT uuid, serverID FROM users WHERE login = ?">>, [Login]),
            AccessTokenGen = list_to_binary(get_random_string(32, "0123456789abcdef")),
            %mysql:query(SqlPid, <<"UPDATE users SET accessToken = ? WHERE login = ?">>, [AccessTokenGen, Login]),
            JsonResp = case ServerIDFetch of
                null -> jiffy:encode({[{uuid, UUIDFetch}, {serverID, <<"-0">>}, {accessToken, AccessTokenGen}]});
                _ -> jiffy:encode({[{uuid, UUIDFetch}, {serverID, ServerIDFetch}, {accessToken, AccessTokenGen}]})
            end,
            io:format("    ~p~n", [JsonResp]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, JsonResp, Req),
            {ok, RespReq, [SqlPid]};
        {Login, ServerID, empty, empty} ->
            {ok, _ColumnNames, [[UUIDFetch]]} = mysql:query(SqlPid, <<"SELECT uuid FROM users WHERE login = ?">>, [Login]),
            mysql:query(SqlPid, <<"UPDATE users SET serverID = ? WHERE login = ?">>, [ServerID, Login]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{uuid, UUIDFetch}]}), Req),
            {ok, RespReq, [SqlPid]};
        {empty, empty, UUID, empty} ->
            {ok, _ColumnNames, [[LoginFetch, ServerIDFetch, AccessTokenFetch]]} = mysql:query(SqlPid, <<"SELECT login, serverID, accessToken FROM users WHERE uuid = ?">>, [UUID]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{login, LoginFetch}, {serverID, ServerIDFetch}, {accessToken, AccessTokenFetch}]}), Req),
            {ok, RespReq, [SqlPid]};
        {Login, empty, UUID, AccessToken} ->
            mysql:query(SqlPid, <<"UPDATE users SET accessToken = ? WHERE login = ?">>, [AccessToken, Login]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, <<"{}">>, Req),
            {ok, RespReq, [SqlPid]};
        {empty, ServerID, UUID, empty} ->
            mysql:query(SqlPid, <<"UPDATE users SET serverID = ? WHERE uuid = ?">>, [ServerID, UUID]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, <<"{}">>, Req),
            {ok, RespReq, [SqlPid]};
        {Login, ServerID, empty, AccessToken} ->
            mysql:query(SqlPid, <<"UPDATE users SET serverID = ? WHERE login = ? and accessToken = ?">>, [ServerID, Login, AccessToken]),
            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, <<"{}">>, Req),
            {ok, RespReq, [SqlPid]}
    end.

%    case mysql:query(SqlPid, <<"SELECT password FROM users WHERE login = ?">>, [Login]) of
%        {ok, _ColumnNames, [[Password]]} -> FixedPassword = binary_to_list(binary:replace(Password, <<"$2y$">>, <<"$2a$">>)),
%            case {ok, FixedPassword} =:= bcrypt:hashpw(binary_to_list(NominalPassword), FixedPassword) of
%		true ->
%	            RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{login, Login}]}), Req),
%		    {ok, RespReq, [SqlPid]};
%		false ->
%		    RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{error, <<"Wrong password">>}]}), Req),
%		    {ok, RespReq, [SqlPid]}
%	    end;
%	_ ->
%	    RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{error, <<"Wrong login">>}]}), Req),
%	    {ok, RespReq, [SqlPid]}
%    end.

terminate(Reason, Req, State) ->
    ok.
