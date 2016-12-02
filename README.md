# elm-debounce [![][badge-doc]][doc]  [![][badge-license]][license]

[badge-doc]: https://img.shields.io/badge/documentation-latest-yellow.svg?style=flat-square
[doc]: http://package.elm-lang.org/packages/mpizenberg/elm-debounce/latest
[badge-license]: https://img.shields.io/badge/license-MPL%202.0-blue.svg?style=flat-square
[license]: https://www.mozilla.org/en-US/MPL/2.0/

This package aims at easing the control of messages
with debouncing and throttling with as few modifications as possible.

## Installation

```bash
elm-package install mpizenberg/elm-debounce
```

## Usage

Let's say you have a button that do something when clicked:
```elm
type alias Model = { ... }

type Msg = Clicked

update msg model =
    case msg of
        Clicked -> -- update here

view model = ... button [ onClick Clicked ] ...
```

If we want to control the Clicked message by debouncing it,
we process in 3 simple steps:

1. We modify the model to hold the controlled state of the message.
2. We add a new update message that do the controlling job.
3. We mark the message we want to debounce in the view.

That's it.

### Modification of the model

The modification of the model is trivial.
It only consists in adding a state.
In functional programming, we want to be in control of the states,
and not hide them where they could be source of bugs.

```elm
type alias Model = { ... , state : MsgControl.State Msg }
initialModel = { ... , state = MsgControl.init }
```

### Modification of the update

Then we add the necessary stuff for the work to be done in Msg and update:

```elm
type Msg = Clicked | Debounce (MsgControl.Msg Msg)

update msg model =
    case msg of
        Clicked -> -- update here
        Debounce controlMsg ->
            let
                ( newState, cmd ) =
                    MsgControl.update
                        (Debounce)
                        (MsgControl.debouncing <| 1 * Time.second)
                        (controlMsg)
                        (model.state)
            in
                ( { model | state = newState }, cmd )
```

The important part here is:

```elm
( newState, cmd ) =
    MsgControl.update
        (Debounce) -- The message wrapper
        (MsgControl.debouncing <| 1 * Time.second) -- The strategy
        (controlMsg) -- The inner message
        (model.state) -- The current state
```

Sometimes, MsgControl.update will produce a `Clicked` command
(which is of type Cmd Msg).
But most of the time (since the message is debounced),
it will just do internal stuff, but still will need to produce a Cmd Msg
(to respect the return types).
So that's why we need to give it a message wrapper `Debounce`
that it will use to wrap its inner messages.

The strategy is what you want to do.
Here we decide to debounce the message with a timeout of 1 second.

The actual inner message is just an inner message,
like in any other TEA component.

And of course, since we hold the state, we need to give it to the update.

### Modification of the view

Finally, we need a slight modification of the view.
This is to guide the message generated on click to the controls.
For that, we use the `wrap` helper function from the module.

```elm
view model = ... button [ onClick (debounce Clicked) ] ...

debounce : Msg -> Msg
debounce =
    Debounce << MsgControl.wrap
```

## Examples

You can find complete minimalist example files in the `examples` folder.
To run the examples, simply use `elm-reactor`:

```shell
$ cd examples/
$ elm-reactor
open http://localhost:8000/
```

## Documentation

You can find the package documentation on the [elm package website][doc]

## License

This Source Code Form is subject to the terms of the Mozilla Public License,v. 2.0.
If a copy of the MPL was not distributed with this file,
You can obtain one at https://mozilla.org/MPL/2.0/.

## Contact

Feel free to contact me on the elm slack (user mattpiz) for any question
and to star this package if you like it ;).

## References

This work has been greatly inspired by the works of:
- [bcardiff/elm-debounce](https://github.com/bcardiff/elm-debounce).
- [jinjor/elm-debounce](https://github.com/jinjor/elm-debounce).

In case this package does not suit your needs,
don't forget to look at their work and star it if you like it.
