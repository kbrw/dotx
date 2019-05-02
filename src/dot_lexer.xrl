
Definitions.

A = [Aa]
B = [Bb]
C = [Cc]
D = [Dd]
E = [Ee]
G = [Gg]
H = [Hh]
I = [Ii]
N = [Nn]
O = [Oo]
P = [Pp]
R = [Rr]
S = [Ss]
T = [Tt]
U = [Uu]

DoubleSlashComment = (//[^\r\n]*\r?\n)+
SharpComment       = (#[^\r\n]*\r?\n)+
Blank = [\000-\040]

HTML    = (\x1e[^\x1e]*\x1e)
AlNum   = ([a-zA-Z\200-\377_][a-zA-Z\200-\377_0-9]*)
Numeral = (-?(\.[0-9]+|[0-9]+(\.[0-9]*)?))
Quoted  = ("(\\([^\\]|\\)|[^\\""])+")

% edgeops
DiOp   = (->)
UnDiOp = (--)

Rules.
%% Note: rule order matters.

{S}{T}{R}{I}{C}{T}      : {token,{'strict',TokenLine}}.
{G}{R}{A}{P}{H}         : {token,{'graph',TokenLine}}.
{D}{I}{G}{R}{A}{P}{H}   : {token,{'digraph',TokenLine}}.

{N}{O}{D}{E}   : {token,{'node',TokenLine}}.
{E}{D}{G}{E}   : {token,{'edge',TokenLine}}.

{S}{U}{B}{G}{R}{A}{P}{H}    : {token,{'subgraph',TokenLine}}.

{DiOp}    : {token,{'->',TokenLine}}.
{UnDiOp}  : {token,{'--',TokenLine}}.

\;          : {token,{';',TokenLine}}.
\,          : {token,{',',TokenLine}}.
\:          : {token,{':',TokenLine}}.
\=          : {token,{'=',TokenLine}}.

\{          : {token,{'{',TokenLine}}.
\[          : {token,{'[',TokenLine}}.
\]          : {token,{']',TokenLine}}.
\}          : {token,{'}',TokenLine}}.

{AlNum}         : {token,{id,TokenLine,list_to_binary(TokenChars)}}.
{Numeral}       : {token,{id,TokenLine,list_to_binary(TokenChars)}}.
{Quoted}        : {token,{id,TokenLine,unquote(list_to_binary(TokenChars))}}.
{HTML}          : {token,{id,TokenLine,unhtml(list_to_binary(TokenChars))}}.

% Declared after ids to enable embedded comments there.
{DoubleSlashComment}    : skip_token.
{SharpComment}          : skip_token.
{Blank} : skip_token.

Erlang code.

unquote (<<"\"\"">>) ->
    <<"">>;
unquote (Quoted) ->
    Size = size(Quoted) - 2,
    <<$", Unquoted:Size/binary, $">> = Quoted,
    binary:replace(Unquoted, <<"\\\"">>, <<"\"">>, [global]).

unhtml (Html) ->
    Size = size(Html) - 2,
    <<30,UnHtml:Size/binary,30>> = Html,
    'Elixir.Dotx.HTML':trim('Elixir.Dotx.HTML':'__struct__'([{html,UnHtml}])).

%% End of Lexer.
