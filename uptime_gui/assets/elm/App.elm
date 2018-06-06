module App exposing (..)

import Json.Encode
import Json.Decode exposing (field)
import Html exposing (..)
import Html.Events exposing (onSubmit, onInput)
import List
import Phoenix.Socket
import Phoenix.Channel


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
            , next_check = Check 0 "" "" 200
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

        CreateCheck ->
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
        , form [ onSubmit CreateCheck ]
            [ label []
                [ text "Url"
                , input [ onInput SetNewUrl ]
                    []
                ]
            , label []
                [ text "Notify number"
                , input [ onInput SetNewNumber ]
                    []
                ]
            , label []
                [ text "Expected response code"
                , input []
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
