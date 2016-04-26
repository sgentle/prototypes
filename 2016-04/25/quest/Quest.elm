import Html exposing (div, span, button, text, textarea, input, br, Html)
import Html.Events exposing (onClick, onBlur, on, onWithOptions, targetValue)
import Html.Attributes exposing (type', checked, autofocus, style)
import StartApp as StartApp
import Json.Decode as Json

import Effects exposing (Effects)
import Date
import String exposing (padLeft, split, join)
import List exposing (head, tail)
import Maybe exposing (withDefault)

import Result

import Task

import Debug

app =
  StartApp.start { init = init
  , view = view
  , update = update
  , inputs = []
  }


main = app.html

type alias Model =
  { things: List String
  , editing: Bool
  }

init: (Model, Effects Action)
init = ({ things = ["Do a thing", "Do another thing"], editing = False }, Effects.none)

onWithoutDefault: String -> Signal.Address a -> a -> Html.Attribute
onWithoutDefault str address val =
  onWithOptions
    str
    { stopPropagation = False, preventDefault = True }
    Json.value
    (\_ -> Signal.message address val)


view: Signal.Address Action -> Model -> Html
view address model =
  div []
    [ if model.editing then
        div []
          [ textarea
            [ on "input" targetValue (\str -> Signal.message address (SetThings (split "\n" str)))
            ]
            [ text (join "\n" model.things) ]
          , br [] []
          , button [ onClick address (SetEditing False) ] [ text "Done" ]
          ]
      else
        div []
        [ input
          [ type' "checkbox"
          , checked False
          , onWithoutDefault "click" address (DoneThing)
          ]
          [ ]
        , span
          [ onClick address (SetEditing True) ]
          [ text (withDefault "Nothing to do!" (head model.things)) ]
        ]
    ]

type Action = SetThings (List String) | SetEditing Bool | DoneThing

update: Action -> Model -> (Model, Effects Action)
update action model =
  (case action of
    SetThings things -> { model | things = things }
    SetEditing editing -> { model | editing = editing }
    DoneThing -> { model | things = withDefault [] (tail model.things) }
  , Effects.none
  )


port tasks : Signal (Task.Task Effects.Never ())
port tasks =
    app.tasks