module State exposing (..)


type State s a
    = State (s -> ( a, s ))


runState : s -> State s a -> ( a, s )
runState s (State processor) =
    processor s


state : (s -> ( a, s )) -> State s a
state =
    State


put : s -> State s ()
put s =
    state <| always ( (), s )


get : State s s
get =
    state <| \s -> ( s, s )


evalState : s -> State s a -> a
evalState s processor =
    Tuple.first (runState s processor)


execState : s -> State s a -> s
execState s processor =
    Tuple.second (runState s processor)



-- MONAD #############################################################


return : a -> State s a
return =
    state << (,)


join : State s (State s a) -> State s a
join proprocessor =
    state
        (\s0 ->
            let
                ( processor, s1 ) =
                    runState s0 (proprocessor)
            in
                runState s1 processor
        )



-- join = andThen identity
-- andThen k processor = join (fmap k processor)


andThen : (a -> State s b) -> State s a -> State s b
andThen k processor =
    state
        (\s0 ->
            let
                ( a, s1 ) =
                    runState s0 processor
            in
                runState s1 (k a)
        )



-- myThen : (s -> State s a) -> State s a -> State s a


(|=>) =
    thenDo


thenDo : State s a -> State s b -> State s a
thenDo k =
    andThen (always k)



-- FUNCTOR ###########################################################


fmap : (a -> b) -> State s a -> State s b
fmap k processor =
    state
        (\s0 ->
            let
                ( a, s1 ) =
                    runState s0 processor
            in
                ( k a, s1 )
        )
