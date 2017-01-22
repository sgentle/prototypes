import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Random
import WebSocket

main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

type alias Model = Int

init : (Model, Cmd Msg)
init =
  (1, Cmd.none)

type Msg = Increment | Decrement | Random | SetVal Int | NewMessage String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      (model + 1, Cmd.none)

    Decrement ->
      (model - 1, Cmd.none)

    Random ->
      (model, Random.generate SetVal (Random.int 1 6))

    NewMessage str ->
      (Result.withDefault 0 (String.toInt str), Cmd.none)

    SetVal newVal ->
      (newVal, WebSocket.send "ws://localhost:8080" (toString newVal))

view : Model -> Html Msg
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (toString model) ]
    , button [ onClick Increment ] [ text "+" ]
    , button [ onClick Random ] [ text "Random" ]
    ]

subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen "ws://localhost:8080" NewMessage