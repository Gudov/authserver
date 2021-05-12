-module(lauth_handle).
-behaviour(cowboy_handler).

-export([init/2, terminate/3]).

init(Req0, [SqlPid]) ->
    {ok, Data, Req} = cowboy_req:read_body(Req0),
    {[{<<"login">>,Login},
      {<<"password">>,NominalPassword},
      {<<"ip">>, _Ip}]} = jiffy:decode(Data),
    case mysql:query(SqlPid, <<"SELECT password FROM users WHERE login = ?">>, [Login]) of
        {ok, _ColumnNames, [[Password]]} -> FixedPassword = binary_to_list(binary:replace(Password, <<"$2y$">>, <<"$2a$">>)),
            case {ok, FixedPassword} =:= bcrypt:hashpw(binary_to_list(NominalPassword), FixedPassword) of
		true ->
			RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{login, Login}]}), Req),
		    {ok, RespReq, [SqlPid]};
		false ->
		    RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{error, <<"Wrong password">>}]}), Req),
		    {ok, RespReq, [SqlPid]}
	    end;
	_ ->
	    RespReq = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, jiffy:encode({[{error, <<"Wrong login">>}]}), Req),
	    {ok, RespReq, [SqlPid]}
    end.

terminate(_Reason, _Req, _State) ->
    ok.
