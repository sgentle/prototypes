import Html exposing (div, button, text, Html)
import Html.Events exposing (onClick)
import StartApp as StartApp

import Time exposing (Time, every, second, hour)
-- fucking seriously
import TaskTutorial exposing (getCurrentTime)
import Effects exposing (Effects)
import Date
import String exposing (padLeft)
import List

import Result

import History
import Location

import Task

import Debug

app =
  StartApp.start { init = init
  , view = view
  , update = update
  , inputs =
    [ Signal.map Tick (every second)
    , History.hash
      |> Signal.dropRepeats
      |> Signal.map (Target << hashToTarget)
    ]
  }


main = app.html

type alias Model =
  { time: Time
  , target: Maybe Time
  }

init: (Model, Effects Action)
init = ({ time = 0, target = Nothing }, Effects.batch
  [ Effects.task (Task.map (Target << hashToTarget << .hash) Location.location)
  , Effects.task (Task.map Tick getCurrentTime)
  ])

hashToTarget: String -> Maybe Time
hashToTarget hash = hash
  |> String.dropLeft 1
  |> Date.fromString
  |> Result.map Date.toTime
  |> Result.toMaybe

--locationAction: { a | hash: String } -> Action
--locationAction {hash} = HashChange (String.dropLeft 1 hash)

view: Signal.Address Action -> Model -> Html
view address model =
  div []
    [ div [] [ text ("Countdown") ]
    , div [] [ text ("Target time: " ++
        (case model.target of
          Nothing -> "None"
          Just t -> formatTime t
        )
      )]
    , div [] [ text ("Current time: " ++ formatTime model.time) ]
    , div [] [ text (case model.target of
          Nothing -> ""
          Just t -> "T-" ++ formatTimeDiff (t - model.time)
        )
      ]
    ]

formatTimeDiff: Time -> String
formatTimeDiff time =
  let t = round time
  in
    [t // 3600000 % 24, t // 60000 % 60, t // 1000 % 60]
      |> List.map ((padLeft 2 '0') << toString)
      |> String.join ":"


formatTime: Time -> String
formatTime time =
  let
    date = Date.fromTime time
  in
    [Date.hour date, Date.minute date, Date.second date]
      |> List.map ((padLeft 2 '0') << toString)
      |> String.join ":"


type Action = Tick Time | Target (Maybe Time)

update: Action -> Model -> (Model, Effects Action)
update action model =
  (case action of
    Tick time -> { model | time = time }
    Target target -> { model | target = target }

  , Effects.none
  )


port tasks : Signal (Task.Task Effects.Never ())
port tasks =
    app.tasks