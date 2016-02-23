import Html exposing (div, button, text, Html)
import Html.Events exposing (onClick)
import StartApp as StartApp
import Time exposing (Time, every, second, hour)
import Effects exposing (Effects)
import Date as Date
import String exposing (padLeft)
import List

app =
  StartApp.start { init = init
  , view = view
  , update = update
  , inputs = [Signal.map Tick (every second)]
  }


main = app.html

type alias Model =
  { timezone: Float
  , time: Time
  }

init: (Model, Effects Action)
init = ({ timezone = 0.0, time = 0 }, Effects.none)

view: Signal.Address Action -> Model -> Html
view address model =
  div []
    [ div [] [ text ("TZ offset: " ++ toString model.timezone) ]
    , button [ onClick address Increment ] [ text "+" ]
    , button [ onClick address Decrement ] [ text "-" ]
    , div [] [ text ("current time: " ++ formatTime (withTimezone model.timezone model.time)) ]
    ]

withTimezone: Float -> Time -> Time
withTimezone offset time = time + offset * hour

formatTime: Time -> String
formatTime time =
  let
    date = Date.fromTime time
  in
    [Date.hour date, Date.minute date, Date.second date]
      |> List.map ((padLeft 2 '0') << toString)
      |> String.join ":"


type Action = Increment | Decrement | Tick Time

update: Action -> Model -> (Model, Effects Action)
update action model =
  (case action of
    Increment -> { model | timezone = model.timezone + 1 }
    Decrement -> { model | timezone = model.timezone - 1 }
    Tick time -> { model | time = time }

  , Effects.none
  )