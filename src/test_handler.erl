-module(test_handler).
-behaviour(cowboy_rest).

-export([init/2, allowed_methods/2, content_types_provided/2]).
-export([test_reply/2]).

init(Req, State) ->
    {cowboy_rest, Req, State}.

allowed_methods(Req, State) ->
    {[<<"GET">>], Req, State}.

content_types_provided(Req, State) ->
    {[
        {{<<"application">>, <<"json">>, []}, test_reply}
    ], Req, State}.

test_reply(Req, State) ->
    {<<"test">>, Req, State}.