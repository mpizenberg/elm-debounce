# elm-debounce [![][badge-doc]][doc]  [![][badge-license]][license]

[badge-doc]: https://img.shields.io/badge/documentation-latest-yellow.svg?style=flat-square
[doc]: http://package.elm-lang.org/packages/mpizenberg/elm-debounce/latest
[badge-license]: https://img.shields.io/badge/license-MPL%202.0-blue.svg?style=flat-square
[license]: https://www.mozilla.org/en-US/MPL/2.0/

This package enables debouncing and throttling of messages
with as few modifications as possible of the original code.

Debouncing and throttling consist in limiting the number of time
an emitted message is actually processed.
For exemple with debouncing, we can detect when someone stop
writing in a textarea.
Let's say we debounce the change event of the area with a delay of 1s.
It means that it won't emit anything until we make a pause
of at least 1s.

![](http://i.giphy.com/l0HlE4nupAppwlwRO.gif)

I detail in the usage section how to do that.

For more details about debouncing and throttling,
please refer to [this very good article][article]

[article]: https://css-tricks.com/debouncing-throttling-explained-examples/

Internally, it is coded using the State Monad concepts.
Don't hesitate to peak at the code and give me feedback
through issues or messages in the elm slack. (user mattpiz).

## Installation

```bash
elm-package install mpizenberg/elm-debounce
```

## Usage

Let's say you have a writable input field.
The model is updated each time your write something.
```elm
type alias Model = { text : String }
initialModel = { text = "" }
init = ( initialModel, Cmd.none )

type Msg = Text String
update msg model =
    case msg of
        Text text -> ( {model | text = text }, Cmd.none )

view model = input [onInput Text] []
```

This updates the model everytime we press a key.
Now we want to change the model only when we stop writing in the input.
We will use debouncing in 3 simple steps:

1. We modify the model to hold the debounced state of the message.
2. We add a new update message that do the debouncing job.
3. We mark the message we want to debounce in the view.

That's it.

### Modification of the model

The modification of the model is trivial.
It only consists in adding a state.
In functional programming, we want to be in control of the states,
and not hide them where they could be source of bugs.

```elm
type alias Model = { text : String, state : Control.State Msg }
initialModel = { text = "", state = Control.initialState }
```

### Modification of the update

Then we add the necessary stuff for the work to be done in Msg and update:
Since it needs to update the state, you have to pass a function to do that.

```elm
type Msg = Text String | Deb (Control Msg)
update msg model =
    case msg of
        Text text -> ( {model | text = text }, Cmd.none )
        Deb debMsg -> Control.update (\s -> { model | state = s }) model.state debMsg
```

### Modification of the view

Finally, we need a slight modification of the view (the `map debounce`).
For our usecase we will be using debouncing on trailing edge ("later").
For other purposes, you could be using leading edge ("immediate) or both edges.

```elm
view model = input [map debounce <| onInput Text] []
debounce = Control.Debounce.trailing Deb (1 * Time.second)
```

## Examples

The complete code of this very example is available in the `examples` folder,
along with other minimalist examples using debouncing and throttling.
To run the examples, simply use `elm-reactor`:

```shell
$ cd examples/
$ elm-reactor
Listening on http://localhost:8000
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

The early days of this work have been greatly inspired by the works of:
- [bcardiff/elm-debounce](https://github.com/bcardiff/elm-debounce).
- [jinjor/elm-debounce](https://github.com/jinjor/elm-debounce).

In case this package does not suit your needs,
don't forget to look at their work and star it if you like it.
