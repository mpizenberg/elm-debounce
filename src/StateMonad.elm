module StateMonad
    exposing
        ( Return
        , State
        , run
        , get
        , andThen
        , map
        , filter
        , condition
        )


type alias Return s a =
    ( s, a )


type alias State s a =
    s -> Return s a


run : s -> State s a -> Return s a
run s processor =
    processor s


get : State s s
get s =
    ( s, s )


andThen : (a -> State s b) -> State s a -> State s b
andThen k processor s0 =
    let
        ( s1, a ) =
            run s0 processor
    in
        run s1 (k a)


map : (a -> b) -> State s a -> State s b
map k processor s0 =
    let
        ( s1, a ) =
            run s0 processor
    in
        ( s1, k a )


filter : (s -> Bool) -> (State s a -> State s a) -> State s a -> State s a
filter predicate modifier processor s =
    if predicate s then
        modifier processor s
    else
        processor s


condition :
    (s -> Bool)
    -> (State s a -> State s b)
    -> (State s a -> State s b)
    -> State s a
    -> State s b
condition predicate modif1 modif2 processor s =
    if predicate s then
        modif1 processor s
    else
        modif2 processor s
