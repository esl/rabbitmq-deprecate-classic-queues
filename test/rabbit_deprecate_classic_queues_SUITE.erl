%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%%  Copyright (c) 2015-2021 Erlang Solutions, Ltd. or its affiliates.
%%  All rights reserved.
%%

-module(rabbit_deprecate_classic_queues_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").
-include_lib("rabbit_deprecate_classic_queues.hrl").

-define(SEND_DELAY, 1000).

all() ->
    [
        {group, non_parallel_tests}
    ].
groups() ->
    [
      {non_parallel_tests, [], [
                                deprecate_classic_queues_test
                               ]}
    ].

%% -------------------------------------------------------------------
%% Testsuite setup/teardown.
%% -------------------------------------------------------------------

init_per_suite(Config) ->
    rabbit_ct_helpers:log_environment(),
    Config1 = rabbit_ct_helpers:set_config(Config, [
        {rmq_nodename_suffix, ?MODULE}
      ]),
    rabbit_ct_helpers:run_setup_steps(Config1,
      rabbit_ct_broker_helpers:setup_steps() ++
      rabbit_ct_client_helpers:setup_steps()).

end_per_suite(Config) ->
    rabbit_ct_helpers:run_teardown_steps(Config,
      rabbit_ct_client_helpers:teardown_steps() ++
      rabbit_ct_broker_helpers:teardown_steps()).

init_per_group(_Testcase, Config) ->
    Config.

end_per_group(_Group, Config) ->
    rabbit_ct_helpers:run_steps(Config,
      rabbit_ct_client_helpers:teardown_steps() ++
      rabbit_ct_broker_helpers:teardown_steps()).

init_per_testcase(Testcase, Config) ->
    rabbit_ct_helpers:testcase_started(Config, Testcase),
    Config.

end_per_testcase(Testcase, Config) ->
    rabbit_ct_helpers:testcase_finished(Config, Testcase).

%% -------------------------------------------------------------------
%% Testcases.
%% -------------------------------------------------------------------

deprecate_classic_queues_test(Config) ->
    Conn1 = rabbit_ct_client_helpers:open_connection(Config, 0),
    {ok, Chan1} = amqp_connection:open_channel(Conn1),

    CQ = <<"q">>,
    QQ = <<"qq">>,

    ClassicQ = make_classic_queue(CQ),
    Result1 =
      try
          declare_queue(Chan1, ClassicQ)
      catch _:Reason ->
          ct:pal("failed to declare queue: ~p", [Reason]),
          error
      end,

    ?assertMatch(error, Result1),
    ?assertNot(erlang:is_process_alive(Chan1)),
    rabbit_ct_client_helpers:close_channel(Chan1),
    rabbit_ct_client_helpers:close_connection(Conn1),
    timer:sleep(1000),
    Conn2 = rabbit_ct_client_helpers:open_connection(Config, 0),
    {ok, Chan2} = amqp_connection:open_channel(Conn2),
    Result2 = declare_queue(Chan2, make_quorum_queue(QQ)),
    ?assertMatch(#'queue.declare_ok'{queue = QQ}, Result2),
    ?assert(erlang:is_process_alive(Chan2)),
    rabbit_ct_client_helpers:close_channel(Chan2),

    rabbit_ct_broker_helpers:disable_plugin(Config, 0, rabbitmq_deprecate_classic_queues),

    Conn3 = rabbit_ct_client_helpers:open_connection(Config, 0),
    {ok, Chan3} = amqp_connection:open_channel(Conn3),
    Result3 = declare_queue(Chan3, make_classic_queue(CQ)),

    ?assertMatch(#'queue.declare_ok'{queue = CQ}, Result3),
    ?assert(erlang:is_process_alive(Chan3)),

    delete_queue(Chan3, QQ),
    delete_queue(Chan3, CQ),

    [rabbit_ct_client_helpers:close_connection(C) || C <- [Conn1, Conn2, Conn3]],
    rabbit_ct_client_helpers:close_channel(Chan3),

    passed.


%% -------------------------------------------------------------------
%% Implementation.
%% -------------------------------------------------------------------
declare_queue(Chan, QDeclare) ->
    #'queue.declare_ok'{} = amqp_channel:call(Chan, QDeclare).

delete_queue(Chan, Q) ->
    #'queue.delete_ok'{} = amqp_channel:call(Chan, #'queue.delete' {queue = Q}).

make_classic_queue(Q) ->
    make_queue(Q, [{?QUEUE_TYPE_HEADER, longstr, <<"classic">>}]).

make_quorum_queue(Q) ->
    make_queue(Q, [{?QUEUE_TYPE_HEADER, longstr, <<"quorum">>}], true).

make_queue(Q, Args) ->
    make_queue(Q, Args, false).
make_queue(Q, Args, IsDurable) ->
    #'queue.declare' {
       queue       = Q,
       durable     = IsDurable,
       arguments   = Args
      }.
