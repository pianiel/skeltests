%% @author jstypka <jasieek@student.agh.edu.pl>
%% @version 1.1
%% @doc Glowny modul aplikacji implementujacy logike procesu zarzadzajacego algorytmem.

-module(hybrid).
-behaviour(gen_server).
-export([sendAgent/1, start/4, start/1, start/0,
  init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================

start(ProblemSize,Time,Islands,Path) ->
  {ok, _} = gen_server:start({local,?MODULE}, ?MODULE, [ProblemSize,Time,Islands,Path], []),
  timer:sleep(Time).

start([A,B,C,D]) ->
  start(list_to_integer(A),
    list_to_integer(B),
    list_to_integer(C),D).

start() ->
  file:make_dir("tmp"),
  start(40,5000,3,"tmp").

sendAgent(Agent) ->
  gen_server:cast(whereis(?MODULE), {agent,self(),Agent}).

%% @spec init() -> ok
%% @doc Funkcja wykonujaca wszelkie operacje potrzebne przed uruchomieniem
%% algorytmu.
init([ProblemSize,Time,Islands,Path]) ->
  timer:send_after(Time,theEnd),
  PidsRefs = [spawn_monitor(hybrid_island,start,[Path,X,ProblemSize]) || X <- lists:seq(1,Islands)],
  {Pids,_} = lists:unzip(PidsRefs),
  {ok,Pids,config:supervisorTimeout()}.

handle_call(_,_,State) ->
  {noreply,State}.

handle_cast({agent,_From,Agent},Pids) ->
  Index = random:uniform(length(Pids)),
  hybrid_island:sendAgent(lists:nth(Index, Pids),Agent),
  {noreply,Pids,config:supervisorTimeout()}.

handle_info({'DOWN',_Ref,process,Pid,Reason},Pids) ->
  io:format("Proces ~p zakonczyl sie z powodu ~p~n",[Pid,Reason]),
  {NewPid,_Ref} = spawn_monitor(hybrid_island,proces,[]),
  io:format("Stawiam kolejna wyspe o Pid ~p~n",[NewPid]),
  {noreply,[NewPid|lists:delete(Pid,Pids)],config:supervisorTimeout()};
handle_info(timeout,Pids) ->
  {stop,timeout,Pids};
handle_info(theEnd,Pids) ->
  {stop,normal,Pids}.

terminate(_Reason,Pids) ->
  [hybrid_island:close(Pid) || Pid <- Pids],
  misc_util:checkIfDead(Pids),
  misc_util:clearInbox().

code_change(_OldVsn,State,_Extra) ->
  {ok, State}.
