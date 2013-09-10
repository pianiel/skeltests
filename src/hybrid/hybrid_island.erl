%% @author jstypka <jasieek@student.agh.edu.pl>
%% @version 1.0
%% @doc Modul odpowiedzialny za logike pojedynczej wyspy.

-module(hybrid_island).
-export([start/3, close/1, sendAgent/2]).

-type agent() :: {Solution::genetic:solution(), Fitness::float(), Energy::pos_integer()}.

%% ====================================================================
%% API functions
%% ====================================================================

-spec start(Path::string(), N::integer(), ProblemSize::integer()) -> ok.
%% @doc Funkcja generujaca dane poczatkowe, ktora pod koniec uruchamia
%% petle, w ktorej porusza sie proces.
start(Path,N,ProblemSize) ->
  random:seed(erlang:now()),
  IslandPath = filename:join([Path,"isl" ++ integer_to_list(N)]),
  FDs = io_util:prepareWriting(IslandPath),
  Solutions = [genetic:solution(ProblemSize) || _ <- lists:seq(1, config:populationSize())],
  Agents = [ {S, genetic:evaluation(S), config:initialEnergy()} || S <- Solutions],
  timer:send_after(config:writeInterval(),write),
  loop(Agents,FDs).

-spec close(pid()) -> {finish,pid()}.
close(Pid) ->
  Pid ! {finish,self()}.

-spec sendAgent(pid(),agent()) -> {agent,pid(),agent()}.
sendAgent(Pid,Agent) ->
   Pid ! {agent,self(),Agent}.

%% ====================================================================
%% Internal functions
%% ====================================================================

-spec loop([agent()],dict()) -> ok.
%% @doc Glowna petla procesu. Kazda iteracja powoduje obliczenie
%% kolejnego wyniku i opcjonalnie wyslanie go do supervisora.
loop(Agents,FDs) ->
  receive
    write ->
      io_util:write(dict:fetch(fitness,FDs),misc_util:result(Agents)),
      io_util:write(dict:fetch(population,FDs),length(Agents)),
      io:format("Island ~p Fitness ~p Population ~p~n",[self(),misc_util:result(Agents),length(Agents)]),
      timer:send_after(config:writeInterval(),write),
      loop(Agents,FDs);
    {agent,_Pid,A} ->
      loop([A|Agents],FDs);
    {finish,_Pid} ->
      io_util:closeFiles(FDs),
      ok
  after 0 ->
    Groups = misc_util:groupBy(fun misc_util:behavior/1, Agents),
    NewGroups = [evolution:sendToWork(G) || G <- Groups],
    NewAgents = misc_util:shuffle(lists:flatten(NewGroups)),
    loop(NewAgents,FDs)
  end.