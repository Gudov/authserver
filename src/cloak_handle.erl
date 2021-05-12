-module(cloak_handle).
-behaviour(cowboy_handler).

-export([init/2, terminate/3]).

% 20456ae6-8fe4-3271-9887-41e62ea71008
% 8        4    4    4    12

init(Req0, []) ->
    #{uuid:=UUID} = cowboy_req:match_qs([uuid], Req0),
    UUIDList = binary_to_list(UUID),
    io:format("~p ~p~n", [UUIDList, "/home/sites/mc.unisono.pro/public/cloaks/" ++ UUIDList ++ ".png"]),
    FileName = "/home/sites/mc.unisono.pro/public/cloaks/" ++ UUIDList ++ ".png",
    Req = cowboy_req:reply(200, #{
        <<"content-type">> => "image/png"
        }, {sendfile, 0, filelib:file_size(FileName), FileName}, Req0),
    {ok, Req, []}.

terminate(_Reason, _Req, _State) ->
    ok.
