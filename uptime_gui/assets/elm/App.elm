module App exposing (..)

import Json.Encode
import Json.Decode exposing (field)
import Html exposing (..)
import List
import Phoenix.Socket
import Phoenix.Channel


type alias Check =
    { url : String
    , notify_number : String
    , expected_code : Int
    }


type alias Checks =
    { socket : Phoenix.Socket.Socket Msg
    , checks : List Check
    }


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | AddCheck Json.Encode.Value


init : ( Checks, Cmd Msg )
init =
    let
        channel =
            Phoenix.Channel.init "checks:ad"

        ( initSocket, cmd ) =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "create_check" "checks:ad" AddCheck
                -- |> Phoenix.Socket.on "delete_check" "checks:ad" AddCheck
                -- |> Phoenix.Socket.on "update_check" "checks:ad" AddCheck
                |> Phoenix.Socket.join channel

        model =
            { socket = initSocket
            , checks = []
            }
    in
        ( model, Cmd.map PhoenixMsg cmd )


checkDecoder : Json.Decode.Decoder Check
checkDecoder =
    Json.Decode.map3 Check
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

        AddCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { checks | checks = check :: checks.checks }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log (error)
                        ( checks, Cmd.none )


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
        , form []
            [ input []
                []
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
