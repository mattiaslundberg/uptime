module App exposing (..)

import Json.Encode
import Json.Decode exposing (field)
import Html exposing (..)
import Html.Attributes exposing (value)
import Html.Events exposing (onSubmit, onInput)
import List
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


type alias Check =
    { id : Int
    , url : String
    , notify_number : String
    , expected_code : Int
    }


type alias Checks =
    { socket : Phoenix.Socket.Socket Msg
    , checks : List Check
    , next_check : Check
    }


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | CreateCheck
    | PhxAddCheck Json.Encode.Value
    | SetNewUrl String
    | SetNewNumber String
    | SetNewResponse String


new_next_check : Check
new_next_check =
    Check 0 "" "" 200


init : ( Checks, Cmd Msg )
init =
    let
        channel =
            Phoenix.Channel.init "checks:ad"

        ( initSocket, cmd ) =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "create_check" "checks:ad" PhxAddCheck
                -- |> Phoenix.Socket.on "delete_check" "checks:ad" PhxDeleteCheck
                -- |> Phoenix.Socket.on "update_check" "checks:ad" PhxUpdateCheck
                |> Phoenix.Socket.join channel

        model =
            { socket = initSocket
            , checks = []
            , next_check = new_next_check
            }
    in
        ( model, Cmd.map PhoenixMsg cmd )


checkDecoder : Json.Decode.Decoder Check
checkDecoder =
    Json.Decode.map4 Check
        (field "id" Json.Decode.int)
        (field "url" Json.Decode.string)
        (field "notify_number" Json.Decode.string)
        (field "expected_code" Json.Decode.int)


update : Msg -> Checks -> ( Checks, Cmd Msg )
update msg checks =
    case msg of
        PhoenixMsg msg ->
            let
                ( socket, cmd ) =
                    Phoenix.Socket.update msg checks.socket
            in
                ( { checks | socket = socket }
                , Cmd.map PhoenixMsg cmd
                )

        PhxAddCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { checks | checks = check :: checks.checks }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log (error)
                        ( checks, Cmd.none )

        SetNewUrl str ->
            let
                current =
                    checks.next_check
            in
                ( { checks | next_check = { current | url = str } }, Cmd.none )

        SetNewNumber str ->
            let
                current =
                    checks.next_check
            in
                ( { checks | next_check = { current | notify_number = str } }, Cmd.none )

        SetNewResponse str ->
            let
                current =
                    checks.next_check

                new_value =
                    Result.withDefault checks.next_check.expected_code (String.toInt str)
            in
                ( { checks | next_check = { current | expected_code = new_value } }, Cmd.none )

        CreateCheck ->
            let
                payload =
                    (Json.Encode.object [ ( "url", Json.Encode.string checks.next_check.url ), ( "notify_number", Json.Encode.string checks.next_check.notify_number ), ( "expected_code", Json.Encode.int checks.next_check.expected_code ) ])

                cmd =
                    Phoenix.Push.init "create_check" "checks:ad" |> Phoenix.Push.withPayload payload

                ( socket, phxCmd ) =
                    Phoenix.Socket.push cmd checks.socket
            in
                ( { checks | socket = socket, next_check = new_next_check }, Cmd.map PhoenixMsg phxCmd )


drawCheck : Check -> Html Msg
drawCheck check =
    li [] [ text check.url ]


drawChecks : List Check -> List (Html Msg)
drawChecks checks =
    checks |> List.map drawCheck


view : Checks -> Html Msg
view checks =
    div []
        [ ul [] (checks.checks |> drawChecks)
        , form [ onSubmit CreateCheck ]
            [ label []
                [ text "Url"
                , input [ value checks.next_check.url, onInput SetNewUrl ]
                    []
                ]
            , label []
                [ text "Notify number"
                , input [ value checks.next_check.notify_number, onInput SetNewNumber ]
                    []
                ]
            , label []
                [ text "Expected response code"
                , input [ value (toString checks.next_check.expected_code), onInput SetNewResponse ]
                    []
                ]
            , button []
                [ text "Submit"
                ]
            ]
        ]


subscriptions : Checks -> Sub Msg
subscriptions checks =
    Phoenix.Socket.listen checks.socket PhoenixMsg


main : Program Never Checks Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
