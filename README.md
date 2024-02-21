#Voto: 28

## Premesse
Tutte le azioni non permesse come:
 - ridefinizione di classi già esistenti;
 - definizione di field con valori non accettati dal suo tipo;
 - chiamate fatte in modo errato,
 - dichiarare un field che ha come tipo la classe che si sta dichiarando al
 momento
 - dichiarare un field che ha un tipo incompatibile con quello del field 
 della superclasse

 ritorneranno `false`.

Il programma rispetta i concetti base del **polimorfismo** e accetta come
parametro nella maggiorparte dei predicati sia il nome dell'istanza sia 
l'oggetto stesso che la rappresenta

- E' possibile ridefinire le istanze;
- E' possibile avere più classi padre;
- E' possibile specificare o omettere il tipo nei fields;
- Il tipo `string` accetta stringhe sia denotate da `'` che da `"`;
- Il tipo `float` accetta anche valori interi (`42` e `3.14`);
- Il tipo `any` accetta qualsiasi tipo di valore;
- Il valore `nil` è accettato da tutti i tipi;
- I tipi dei fields possono essere nomi di classi definite;
- E' possibile passare più argomenti nei metodi creati.

Quando si definisce una nuova classe e si dichiara un field con nome già
esistente, il nuovo field è accettato in questi casi:
- Se il tipo del field della superclasse non è specificato o è `any`
- Se il tipo del field della superclasse e il nuovo tipo corrispondono
- Se il tipo del field della superclasse è un `float` e il nuovo tipo è un
`integer`
- Se il tipo del field della superclasse è una classe `X` e il nuovo tipo è
una sottoclasse di `X`

## Come utilizzare i predicati definiti nel programma

### Definizione di una classe:
- Per definire una classe si può utilizzare `def_class/2` o `def_class/3`
Definiamo una classe di nome `persona`, senza parents, fields e metodi:
    ```
    ?- def_class(persona, []).
    ```

- Definiamo una classe di nome `studente` con `persona` come superclasse 
e con dei fields e dei metodi:
    ```
    ?- def_class(studente, [persona], 
        [field(name, 'Francesco', string),
         field(university, 'Bicocca'),
         field(container, nil, studente),
         method(talk, [],
            (write('il mio nome è'),
            field(this, name, N),
            writeln(N),
            write('la mia università è'),
            field(this, university, U),
            writeln(U))
            )
        ]
    ).
    ```

- E' possibile richiamare il metodo `talk` appena creato in questo modo:
    ```
    ?- talk(oggettoistanza).
    ```
  In questo caso non abbiamo specificato alcun argomento da passare al metodo.


### Creazione di un'istanza:
- Per definire una nuova istanza si può utilizzare `make/2` o `make/3`.
Definiamo un'istanza di tipo `studente` di nome `mario`.
    ```
    ?- make(mario, studente).
    ```

- Per specificare dei field all'istanza si può usare `make/3`.
    ```
    ?- make(giulia, studente, [university = 'UNIMI']).
    ```

- Come richiesto da consegna, è possibile anche passare come primo parametro a 
`make/3` una variabile che unifica con l'istanza creata, ma questa istanza non
 verrà aggiunta alla base di conoscenza.
    ```
    ?- make(X, studente, []).
    X = stored_instance(X, studente. []).
    ```

 - Come richiesto da consegna, è possibile anche passare come primo parametro 
 a `make/3` un termine che rappresenta l'istanza, anche questa non verrà 
 aggiunta alla base di conoscenza.
    ```
    ?- make(stored_instance(francesco, studente, []), studente, []).
    ```

### Controlli:
 - Recupera un’istanza dato il nome con cui è stata creata:
    ```
    ?- inst(mario, X).
    X = stored_instance(mario, studente, []).
    ```

 - Verifica che `studente` sia una classe.
    ```
    ?- is_class(studente).
    ```

 - Verifica che l'oggetto passato sia un'istanza (accetta anche direttamente 
 il nome dell'istanza):
    ```
    ?- inst(mario, X), is_instance(X).
    X = stored_instance(mario, studente, [])
    ```
    ```
    ?- is_instance(mario).
    true.
    ```

- Verifica che l'istanza `mario` sia classe o sottoclasse di `persona` 
(accetta anche direttamente il nome dell'istanza)
    ```
    ?- inst(mario, X), is_instance(X, persona).
    X = stored_instance(mario, studente, []).
    ```
    ```
    ?- is_instance(mario, persona).
    true.
    ```

### Accesso ai fields e ai metodi:
 - Per accedere ai fields di un'istanza si può utilizzare `field/3`.
Ricaviamo il valore del field `university` dell'istanza `giulia`. 
    ```
    ?- inst(giulia, X), field(X, university, Result).
    Result = 'UNIMI'
    ```
- Si può anche passare direttamente il nome di un'istanza già esistente:
    ```
    ?- field(giulia, university, Result).
    Result = 'UNIMI'
    ```
 - E' possibile anche percorrere una serie di field contenenti istanze:
    ```
    ?- inst(giulia, X), make(pippo, studente, [container = X]).
    ?- inst(pippo, X), make(pippo2, studente, [container = X]).
    ?- inst(pippo2, X), fieldx(X, [container, container], Result).
    Result = stored_instance(giulia, studente, [university='UNIMI'])
    ```


### Predicati aggiuntivi
- `get_method_instance/3` Utilizzato in ogni metodo creato con `def_class` 
 serve a distinguere i metodi con stesso nome e stessa arietà appartenenti a 
 classi diverse in modo che, avendo l'istanza in input, venga richiamato il 
 metodo corretto. Ho deciso di utilizzare `asserta` nella registrazione del 
 metodo nella base di conoscenza in modo da eseguire la ricerca depth-first 
 partendo dalla classe "più figlia".
    ```
    ?- inst(mario, X), get_method_instance(X, studente, talk).
    true.
    ```

- `superclass/2` Ottieni tutte le superclassi in modo ricorsivo partendo dal 
 nome della classe.
    ```
    ?- superclass(studente, X).
    X = studente ;
    X = persona.
    ```

 - `verify_parts_make/2` e `verify_parts/2` verificano che le componenti 
 passate siano metodi o field validi. 
   - Nel caso di `verify_parts_make/2` viene controllato che il field esista 
   in una delle superclassi e che abbia un tipo compatibile. Questo consente 
   alla `make` di controllare che i nuovi field assegnati esistano nella 
   classe/superclasse e che abbiano tipo corretto.
   - Nel caso di `verify_parts/2` vengono fatti gli stessi controlli ma si 
   accetta anche il caso in cui il field non è mai stato dichiarato.
 Questo consente alla `def_class` di controllare che le superclassi non 
 abbiano il field da ereditare o che lo ereditino col tipo corretto.

 - `add_parts_make/2` e `add_parts/2` aggiungono alla base di conoscenza 
 le componenti passate.

## Test effettuati:

```
?- def_class(umano, [], [
    field(eta, 42, float), 
    method(talk, [], writeln('sono umano'))
]).
true.

?- def_class(mammifero, []).
true.

?- make(capo, umano).
true.

?- inst(capo, X), def_class(persona, [umano, mammifero], [
    field(nome, 'Persona', string), 
    field(genitore, X, umano), 
    method(talk, [], write('sono una persona')), 
    method(talk, [Input], (
        field(this, eta, E),
        field(this, nome, N),
        write('io sono: '),
        write(N),
        write(' ho '),
        write(E),
        write(' anni.'),
        write(' Ciao '),
        writeln(Input))
    )
]).
X = stored_instance(capo, umano, []).

?- def_class(studente, [persona], [
    method(talk, [], write('sono studente')),
    method(to_string, [ResultingString], (
        with_output_to(string(ResultingString),
        (field(this, eta, N),
        field(this, nome, U),
        format('#<~w Student ~w>', [U, N])
        ))
    ))
]).
true.

?- def_class(studente_bicocca, [studente], [
    field(eta, 20, integer),
    method(talk, [], write('studente bicocca!'))
]).
true.

?- make(scimmia, mammifero).
true.

?- make(alessandro, umano).
true.

?- inst(alessandro, X), make(francesco, persona, 
[nome = "Francesco", genitore = X]).
X = stored_instance(alessandro, umano, [])

?- inst(francesco, X), make(luigi, studente, [nome = "Luigi", genitore = X]).
X = stored_instance(francesco, persona, [nome="Francesco", 
genitore=stored_instance(alessandro, umano, [])]).

?- inst(luigi, X), make(collega, studente_bicocca, [genitore = X]).
X = stored_instance(luigi, studente, [nome="Luigi", 
genitore=stored_instance(francesco, 
persona, 
[nome="Francesco", genitore=stored_instance(alessandro, umano, [])])]).

?- stored_instance(collega, X), field(X, nome, Y).
X = inst(collega, studente_bicocca, [
    genitore=stored_instance(luigi, studente, 
[nome="Luigi", 
genitore=stored_instance(francesco, persona, [... = ...|...])])]),
Y = 'Persona'.

?- inst(luigi, X), field(X, nome, Y).
X = stored_instance(luigi, studente, [nome="Luigi", 
genitore=stored_instance(francesco, persona, 
[nome="Francesco", genitore=stored_instance(alessandro, umano, [])])]),
Y = "Luigi".

?- fieldx(collega, [genitore, genitore, genitore], X).
X = stored_instance(alessandro, umano, []).

?- talk(scimmia).
false.

?- talk(alessandro).
sono umano.
true.

?- inst(alessandro, X), talk(X).
sono umano.

?- inst(francesco, X), talk(X).
sono una persona.

?- inst(francesco, X), talk(X, 'Giovanni').
io sono: Francesco ho 42 anni. Ciao Giovanni

?- talk(luigi).
sono studente
true.

?- talk(collega).
studente bicocca!
true.

?- talk(collega, 'Collega').
io sono: Persona ho 20 anni. Ciao Collega
true.

?- to_string(collega, X).
X = "#<Persona Student 20>".

?- to_string(luigi, X).
X = "#<Luigi Student 42>".

%% possibilità di ridefinire istanze esistenti
?- make(alessandro, umano).
true.
```