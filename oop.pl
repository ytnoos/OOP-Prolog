%%%% -*- Mode: Prolog -*-
%%%% oop.pl --

%% -- BASI DINAMICHE --

%% Rappresentazione della classe con le sue super classi
%% class(ClassName, Parents)
:- dynamic class/2.

%% Rappresentazione dei field della classe
%% class_field(ClassName, FieldName, FieldValue, FieldType)
:- dynamic class_field/4.

%% Rappresentazione dei metodi della classe
%% class_method(ClassName, MethodName, MethodArgs)
:- dynamic class_method/3.

%% Rappresentazione dell'istanza dato il nome dell'istanza
%% stored_instance(InstanceName, ClassName, Fields)
:- dynamic stored_instance/3.

%% -- BASI STATICHE --

%% - DEFINIZIONE CLASSI

%% Crea la classe senza fields/metodi
def_class(ClassName, Parents) :-
    def_class(ClassName, Parents, []).

%% Crea la classe e la inserisce nella base dinamica insieme ai fields/metodi
def_class(ClassName, Parents, Parts) :-
    %% Verifico il tipo degli argomenti
    atom(ClassName),
    is_list(Parents),
    is_list(Parts),
    %% Verifico che non esista una classe con lo stesso nome
    findall(_, class(ClassName, _), []),
    %% Verifico l'esistenza delle superclassi
    forall(member(Parent, Parents), is_class(Parent)),
    %% Verifico la validità dei fields e dei metodi
    verify_parts(Parents, Parts),
    assertz(class(ClassName, Parents)),
    add_parts(ClassName, Parts),
    !.


%% - VERIFICA FIELDS E METODI

%% PER IL MAKE
verify_parts_make(_ClassName, []).
verify_parts_make(ClassName, [Part | Parts]) :-
    verify_part_make(ClassName, Part),
    verify_parts_make(ClassName, Parts).
verify_part_make(ClassName, Name = Value) :-
    atom(Name),
    %% Controllo che il field esiste nella definizione della classe o super
    has_field_class_r(ClassName, Name, _Result, Type),
    check_type(Type, Value).

%% PER IL DEF_CLASS
verify_parts(_Parents, []).
verify_parts(Parents, [Part | Parts]) :-
    verify_part(Parents, Part),
    verify_parts(Parents, Parts).
verify_part(Parents, field(Name, Value)) :-
    verify_part(Parents, field(Name, Value, any)).
verify_part(Parents, field(Name, Value, Type)) :-
    atom(Name),
    %% Controllo del tipo
    check_type(Type, Value),
    %% Il field o esiste nei super e ha lo stesso type, o non esiste
    check_super_fields(Parents, Name, Type).
verify_part(_Parents, method(Name, Args, Body)) :-
    atom(Name),
    is_list(Args),
    compound(Body).

%% Controllo dei tipi
check_type(_Type, Value) :-
    Value = nil,
    !.
check_type(Type, Value) :-
    %% Sfrutto i tipi di Prolog
    is_of_type(Type, Value),
    !.
check_type(Type, Value) :-
    %% Compatibilità degli integer con i float
    Type = float,
    integer(Value),
    !.
check_type(Type, Value) :-
    %% Compatibilità con le stringhe
    Type = string,
    is_of_type(text, Value),
    !.
check_type(Type, Value) :-
    %% Compatibilità delle classi come Type e Value come istanza
    is_class(Type),
    is_instance(Value, Type),
    !.

%% Controllo la validità dei fields
check_super_fields(Parents, Name, Type) :-
    %% Se il field non è nelle superclassi, lo accetto sempre
    check_fields_existence(Parents, Name, Type),
    !.
check_super_fields(Parents, Name, Type) :-
    %% Il field non è nelle superclassi, controlliamo che il type sia ok
    check_fields_validity(Parents, Name, Type),
    !.

check_fields_existence([Parent | Parents], Name, Type) :-
    has_no_field(Parent, Name),
    check_fields_existence(Parents, Name, Type),
    !.
check_fields_existence([], _, _).

check_fields_validity([Parent | _], Name, Type) :-
    %% Ricerco il field
    has_field_class_r(Parent, Name, _Result, TypeFound),
    type_valid(TypeFound, Type),
    !.
check_fields_validity([_ | Parents], Name, Type) :-
    %% Ricerco in altre classi
    check_fields_validity(Parents, Name, Type),
    !.

%% Il tipo è valido solo se esiste un tipo identico o se è una superclasse
%% del tipo esistente
type_valid(TypeFound, Type) :-
    TypeFound = Type,
    !.
type_valid(TypeFound, _Type) :-
    TypeFound = any,
    !.
type_valid(TypeFound, Type) :-
    TypeFound = float,
    Type = integer,
    !.
type_valid(TypeFound, Type) :-
    is_class(TypeFound),
    is_class(Type),
    superclass(Type, TypeFound),
    !.

%% - AGGIUNTA FIELDS E METODI ALLA BASE DI CONOSCENZA

%% PER IL DEF_CLASS
add_parts(_, []).
add_parts(ClassName, [Part | Parts]) :-
    add_part(ClassName, Part),
    add_parts(ClassName, Parts).
add_part(ClassName, field(Name, Value, Type)) :-
    assertz(class_field(ClassName, Name, Value, Type)),
    !.
add_part(ClassName, field(Name, Value)) :-
    add_part(ClassName, field(Name, Value, any)),
    !.
add_part(ClassName, method(Name, Args, Body)) :-
    %% Creo la testa del metodo mettendo this come primo argomento
    Head =.. [Name, this | Args],
    %% Creo il corpo del metodo mettendo il controllo dell'istanza
    %% e la chiamata del corpo passato
    AllBody = (get_method_instance(this, ClassName, Name), call(Body)),
    %% Conversioni
    term_to_atom(Head, AtomHead),
    term_to_atom(AllBody, AtomBody),
    %% Compongo l'intero predicato
    atom_concat(AtomHead, ' :- ', AtomHead2),
    atom_concat(AtomHead2, AtomBody, AtomHead3),
    atom_concat(AtomHead3, ', !.', AtomHead4),
    %% Rimpiazzo la parole this con una variabile
    replace_word(AtomHead4, this, "Instance", AtomHeadReplaced),
    term_to_atom(TermMethod, AtomHeadReplaced),
    %% Metto tutto nella base di conoscenza
    asserta(TermMethod),
    assertz(class_method(ClassName, Name, Args)),
    !.

%% - CREAZIONE ISTANZE

make(Instance, ClassName) :-
    make(Instance, ClassName, []).

%% > CASO 1 - DATO IL NOME
make(InstanceName, ClassName, Fields) :-
    atom(InstanceName),
    %% Verifico la validità dei fields
    verify_parts_make(ClassName, Fields),
    %% Elimino dalla base di conoscenza la vecchia istanza
    clean_instance(InstanceName),
    %% Aggiungo l'istanza alla base di conoscenza
    assertz(stored_instance(InstanceName, ClassName, Fields)),
    !.

%% > CASO 2 - DATA LA VARIABILE
make(Instance, ClassName, Fields) :-
    var(Instance),
    Instance = stored_instance(Instance, ClassName, Fields),
    !.

%% > CASO 3 - DATO UN TERM
%% Esempio di term: inst(alessandro, studente, [s1 = v1, s2 = v2])
make(InstanceTerm, ClassName, Fields) :-
    InstanceTerm =.. [_TWord, TermInstanceName, _TClassName, _TFields],
    InstanceTerm = stored_instance(TermInstanceName, ClassName, Fields),
    !.

%% Rimuove dalla base di conoscenza la vecchia istanza e i suoi fields
clean_instance(InstanceName) :-
    retract(stored_instance(InstanceName, _, _)).
clean_instance(_) :- true.

%% - UTILITY

%% [PROF] Verifica che ClassName sia il nome di una classe
is_class(ClassName) :-
    class(ClassName, _),
    !.

%% [PROF] Verifica che Instance sia il nome di un'istanza registrata
is_instance(InstanceName) :-
    stored_instance(InstanceName, _, _),
    !.

%% [PROF] Verifica che Instance sia un'istanza creata
is_instance(Instance) :-
    %% Verifico sia un'istanza
    Instance = stored_instance(_, _, _),
    !.

%% [PROF] Dal nome dell'istanza ricava il nome della classe o le super
is_instance(InstanceName, Super) :-
    stored_instance(InstanceName, ClassName, _),
    Instance = stored_instance(InstanceName, ClassName, _),
    is_instance_all(Instance, Super),
    !.

%% [PROF] Dall'istanza ricava il nome della classe o verifica le super
is_instance(Instance, Super) :-
    is_instance_all(Instance, Super),
    !.

%% Verifica che Instance sia un'istanza delle superclassi di ClassName
is_instance_all(Instance, Super) :-
    Instance = stored_instance(_, ClassName, _),
    superclass(ClassName, Super).

%% [PROF] Ritorna l'oggetto istanza dato il nome dell'istanza
inst(InstanceName, Instance) :-
    %% Mi assicuro sia un'istanza esistente
    stored_instance(InstanceName, ClassName, Properties),
    %% Unifico la variabile con l'istanza
    Instance = stored_instance(InstanceName, ClassName, Properties).

%% Stabilisce se ClassSuper è superclasse di ClassName
superclass(ClassName, ClassSuper) :-
    is_class(ClassName),
    %% Ricerca ricorsivamente le superclassi di ClassName
    findall(X, superclass_all(ClassName, X), Parents),
    member(ClassSuper, Parents).

%% Caso base, verifica che ClassName è una classe e corrisponde a ClassSuper
superclass_all(ClassName, ClassSuper) :-
    ClassName = ClassSuper.

%% Ricorsivo, verifica se un parent di ClassName corrisponde a ClassSuper
superclass_all(ClassName, ClassSuper) :-
    class(ClassName, Parents),
    member(Parent, Parents),
    superclass_all(Parent, ClassSuper).

%% - UTILITY METODI

%% Ricerca un metodo nella classe o nelle sue superclassi
get_method_instance(Instance, ClassName, MethodName) :-
    is_instance(Instance, ClassName),
    class_method(ClassName, MethodName, _),
    !.

%% - UTILITY FIELDS

%% [PROF] Ricerca il field nell'istanza avendo il nome
field(InstanceName, FieldName, Result) :-
    inst(InstanceName, Instance),
    field(Instance, FieldName, Result),
    !.

%% [PROF] Ricerca il field nell'istanza
field(Instance, FieldName, Result) :-
    get_instance_field(Instance, FieldName, Result),
    !.

%% [PROF] Ricerca il field default nella classe o nelle sue superclassi 
field(Instance, FieldName, Result) :-
    is_instance_all(Instance, ClassName),
    class_field(ClassName, FieldName, Result, _),
    !.

%% [PROF] Ricerca i field contenenti istanze nell'istanza
fieldx(Instance, [FieldName], Result) :-
    field(Instance, FieldName, Result),
    !.

%% [PROF] Ricerca i field contenenti istanze nell'istanza
fieldx(Instance, [FieldName | RestFields], Result) :-
    field(Instance, FieldName, IntermediateResult),
    fieldx(IntermediateResult, RestFields, Result),
    !.

%% Controlla l'esistenza del field tra classi/superclassi
has_field_class_r(ClassName, FieldName, Value, Type) :-
    superclass(ClassName, SuperClass),
    class_field(SuperClass, FieldName, Value, Type),
    !.

%% Ritorna true solo se ClassName e le sue superclassi non abbiano FieldName
has_no_field(ClassName, FieldName) :-
    %% Ottengo tutti i parents in un'array
    findall(X, superclass_all(ClassName, X), Parents),
    %% Ricerco il field in tutti i parents
    lookup_field(Parents, FieldName).

lookup_field([Class | Classes], FieldName) :-
    %% Mi assicuro che non esista il field
    findall(_, class_field(Class, FieldName, _, _), []),
    %% Rifaccio il controllo per tutte le altre classi
    lookup_field(Classes, FieldName).
lookup_field([], _).

get_instance_field(Instance, FieldName, Result) :-
    %% E' stata passata un'istanza 
    Instance = stored_instance(_, _, Fields),
    get_field(FieldName, Fields, Result),
    !.

get_field(FieldName, [Field = Value | _], Result) :-
    FieldName = Field,
    Value = Result,
    !.
get_field(FieldName, [_ | Fields], Result) :-
    get_field(FieldName, Fields, Result),
    !.

%% - UTILS 

replace_word(Word, ToReplace, ReplaceWith, X) :-
    replace_nth_word(Word, 1, ToReplace, ReplaceWith, Result),
    replace_word(Result, ToReplace, ReplaceWith, X), 
    !.
replace_word(Word, _, _, Word).
replace_nth_word(Word, NthOcurrence, ToReplace, ReplaceWith, Result) :-
    call_nth(sub_atom(Word, Before, _Len, After, ToReplace), NthOcurrence),
    sub_atom(Word, 0, Before, _, Left),
    sub_atom(Word, _, After, 0, Right),
    atomic_list_concat([Left, ReplaceWith, Right], Result).

%%%% end of file -- oop.pl --
