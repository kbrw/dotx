Nonterminals
Graph GraphTy Strict
StmtList Stmt NodeStmt EdgeStmt AttrStmt Equality Subgraph
AttrList AList NodeId EdgeRHS EdgeOp
.

Terminals
'strict' 'graph' 'digraph' 'node' 'edge' 'subgraph'
';' ',' ':' '=' '{' '[' ']' '}'
id
'--' '->'
.

Rootsymbol Graph.

Graph -> Strict GraphTy    '{' StmtList '}'    : 'Elixir.Dotx.Graph':childattrs2fields('Elixir.Dotx.Graph':'__struct__'([{strict,'$1'},{type,'$2'},{children,lists:flatten('$4')}])).
Graph -> Strict GraphTy id '{' StmtList '}'    : 'Elixir.Dotx.Graph':childattrs2fields('Elixir.Dotx.Graph':'__struct__'([{strict,'$1'},{type,'$2'},{id,element(3,'$3')},{children,lists:flatten('$5')}])).
GraphTy -> 'graph'      : element(1,'$1').
GraphTy -> 'digraph'    : element(1,'$1').
Strict -> '$empty'    : false.
Strict -> 'strict'    : true.

StmtList -> Stmt                 : ['$1'].
StmtList -> Stmt     StmtList    : ['$1'|'$2'].
StmtList -> Stmt ';'             : ['$1'].
StmtList -> Stmt ';' StmtList    : ['$1'|'$3'].
% not in spec but handled by graphvis : comma separated statements
StmtList -> Stmt ','             : ['$1'].
StmtList -> Stmt ',' StmtList    : ['$1'|'$3'].

Stmt -> NodeStmt    : '$1'.
Stmt -> EdgeStmt    : '$1'.
Stmt -> AttrStmt    : '$1'.
Stmt -> Equality    : '$1'.
Stmt -> Subgraph    : '$1'.

Equality -> id '=' id    : {element(3,'$1'),element(3,'$3')}.

AttrStmt -> 'graph' AttrList    : {element(1,'$1'),'$2'}.
AttrStmt -> 'node'  AttrList    : {element(1,'$1'),'$2'}.
AttrStmt -> 'edge'  AttrList    : {element(1,'$1'),'$2'}.

AttrList -> '['       ']'             : #{}.
AttrList -> '[' AList ']'             : 'Elixir.Map':new('$2').
AttrList -> '['       ']' AttrList    : 'Elixir.Map':new('$3').
AttrList -> '[' AList ']' AttrList    : 'Elixir.Enum':into(['$2'],'Elixir.Map':new('$4')).

AList -> Equality              : ['$1'].
AList -> Equality     AList    : ['$1'|'$2'].
AList -> Equality ','          : ['$1'].
AList -> Equality ',' AList    : ['$1'|'$3'].

EdgeStmt -> NodeId   EdgeOp EdgeRHS             : 'Elixir.Dotx.Edge':flatten('Elixir.Dotx.Edge':'__struct__'([{from,'Elixir.Dotx.Node':'__struct__'([{id,'$1'}])},{bidir,'$2'},{to,'$3'}])).
EdgeStmt -> NodeId   EdgeOp EdgeRHS AttrList    : 'Elixir.Dotx.Edge':flatten('Elixir.Dotx.Edge':'__struct__'([{from,'Elixir.Dotx.Node':'__struct__'([{id,'$1'}])},{bidir,'$2'},{to,'$3'},{attrs,'$4'}])).
EdgeStmt -> Subgraph EdgeOp EdgeRHS             : 'Elixir.Dotx.Edge':flatten('Elixir.Dotx.Edge':'__struct__'([{from,'$1'},{bidir,'$2'},{to,'$3'}])).
EdgeStmt -> Subgraph EdgeOp EdgeRHS AttrList    : 'Elixir.Dotx.Edge':flatten('Elixir.Dotx.Edge':'__struct__'([{from,'$1'},{bidir,'$2'},{to,'$3'},{attrs,'$4'}])).

%% Missing here that EdgeRHS must be another edge RHS handling edgeop direction
EdgeRHS -> NodeId              : 'Elixir.Dotx.Node':'__struct__'([{id,'$1'}]).
EdgeRHS -> NodeId EdgeOp EdgeRHS      : 'Elixir.Dotx.Edge':'__struct__'([{from,'Elixir.Dotx.Node':'__struct__'([{id,'$1'}])},{bidir,'$2'},{to,'$3'}]).
EdgeRHS -> Subgraph            : '$1'.
EdgeRHS -> Subgraph EdgeOp EdgeRHS    : 'Elixir.Dotx.Edge':'__struct__'([{from,'$1'},{bidir,'$2'},{to,'$3'}]).
EdgeOp -> '--'    : true.
EdgeOp -> '->'    : false.

NodeStmt -> NodeId             : 'Elixir.Dotx.Node':'__struct__'([{id,'$1'}]).
NodeStmt -> NodeId AttrList    : 'Elixir.Dotx.Node':'__struct__'([{id,'$1'},{attrs,'$2'}]).



NodeId -> id                  : [element(3,'$1')].
NodeId -> id ':' id           : [element(3,'$1'),element(3,'$3')].
NodeId -> id ':' id ':' id    : [element(3,'$1'),element(3,'$3'),element(3,'$5')].

Subgraph ->               '{' StmtList '}'    : 'Elixir.Dotx.Graph':childattrs2fields('Elixir.Dotx.SubGraph':'__struct__'([{children,lists:flatten('$2')}])).
Subgraph -> 'subgraph' id '{' StmtList '}'    : 'Elixir.Dotx.Graph':childattrs2fields('Elixir.Dotx.SubGraph':'__struct__'([{id,element(3,'$2')},{children,lists:flatten('$4')}])).

%% Number of shift/reduce conflicts
Expect 2.

Erlang code.


%% End of Parser.
