%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%%  Copyright (c) 2015-2021 Erlang Solutions, Ltd. or its affiliates.
%%  All rights reserved.
%%

-module(rabbit_deprecate_classic_queues_interceptor).

-include_lib("rabbit_common/include/rabbit.hrl").
-include_lib("rabbit_common/include/rabbit_framing.hrl").
-include_lib("rabbit_deprecate_classic_queues.hrl").

-import(rabbit_basic, [header/2]).

-behaviour(rabbit_channel_interceptor).

-export([description/0, intercept/3, applies_to/0, init/1]).

-rabbit_boot_step({?MODULE,
                   [{description, "deprecate classic queues interceptor"},
                    {mfa, {rabbit_registry, register,
                           [channel_interceptor,
                            <<"deprecate classic queues interceptor">>, ?MODULE]}},
                    {cleanup, {rabbit_registry, unregister,
                               [channel_interceptor,
                                <<"deprecate classic queues interceptor">>]}},
                    {requires, rabbit_registry},
                    {enables, recovery}]}).

init(_Ch) ->
    undefined.

description() ->
    [{description,
      <<"Depreccates classic queues in RabbitMQ on queue declaration">>}].

intercept(#'queue.declare'{arguments = Args} = Method, Content, _IState) ->
    case rabbit_misc:table_lookup(Args, ?QUEUE_TYPE_HEADER) of
        {_Type, <<"classic">>} ->
            rabbit_misc:amqp_error(
                'precondition_failed', "classic queues are not allowed", [],
                'queue.declare');
        _ ->
            {Method, Content}
    end;

intercept(Method, Content, _VHost) ->
    {Method, Content}.

applies_to() ->
    ['queue.declare'].
