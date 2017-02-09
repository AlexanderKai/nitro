-module(element_dtl).
-author('Maxim Sokhatsky').
-include("nitro.hrl").
-compile(export_all).

render_element(Record=#dtl{}) ->
	M = list_to_atom(nitro:to_list(Record#dtl.file) ++ "_view"),
	Variables = M:variables(),
	
	L = lists:flatten([
	case lists:keyfind(Var, 1, Record#dtl.bindings) of
		false -> Var;
		_ -> []
	end
	||
	Var <- Variables, Var /= javascript, Var /= script
	]),

	L2 = [
	{Bind, lists:sublist(l:a2l(Bind), 6, 100)}
	||
	Bind <- L, lists:prefix("call_",l:a2l(Bind)) == true
	],

	L3 = [
	{Bind, string:tokens(Call, "_")}
	||
	{Bind, Call} <- L2
	],
	
	%File = case code:lib_dir(nitro:to_atom(Record#dtl.app)) of
				%{error,bad_name} -> nitro:to_list(Record#dtl.app);
				%A -> A end ++ "/" ++ nitro:to_list(Record#dtl.folder)
			%++ "/" ++ nitro:to_list(Record#dtl.file) ++ "." ++ nitro:to_list(Record#dtl.ext),
	{ok,R} = render(M, Record#dtl.js_escape, [{K,nitro:render(V)} || {K,V} <- Record#dtl.bindings] ++
		[{Bind, nitro:render(apply(l:l2a(CM),l:l2a(CF),[]))} || {Bind, [CM, CF]} <- L3] ++
		if Record#dtl.bind_script==true -> [{script,nitro:script()}]; true-> [] end),
    case Record#event.events of
        [] -> [];
        Ev -> render_events(Ev)
    end,
	R.

render_events(Events) ->
    render_event(Events).

render_event([H|T]) ->
    nitro:wire(H),
    render_event(T).

render(M, true, Args) ->
	{ok, R} = M:render(Args),
	{ok, nitro:js_escape(R)};
render(M, _, Args) -> M:render(Args).
