-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module StateMonad exposing (..)


type alias State s a =
    s -> ( s, a )



-- RETRIEVE RESULTS ##################################################


run : s -> State s a -> ( s, a )
run s processor =
    processor s



-- CONSTRUCT STATE ###################################################


return : a -> State s a
return a s =
    ( s, a )


embed : (s -> a) -> State s a
embed f s =
    ( s, f s )


set : s -> a -> State s a
set s a _ =
    ( s, a )


get : State s s
get s =
    ( s, s )


put : s -> State s ()
put s _ =
    ( s, () )


modify : (s -> s) -> State s ()
modify f s =
    ( f s, () )


modifyAndGet : (s -> s) -> State s s
modifyAndGet f s =
    ( f s, f s )


condition : (s -> Bool) -> State s a -> State s a -> State s a
condition predicate processor1 processor2 s =
    if predicate s then
        processor1 s
    else
        processor2 s



-- MODIFYING STATE ###################################################


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


mapState : (s -> s) -> State s a -> State s a
mapState f processor s0 =
    let
        ( s1, a ) =
            run s0 processor
    in
        ( f s1, a )


when : (s -> Bool) -> (State s a -> State s a) -> State s a -> State s a
when predicate modifier processor s =
    if predicate s then
        modifier processor s
    else
        processor s
