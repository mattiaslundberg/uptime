module App exposing (..)

import Json.Encode
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Form.Input as Input
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Json.Decode exposing (field)
import Html exposing (Html, li, text, div, ul, form, label, input, button, span)
import Html.Attributes exposing (value, for, type_)
import Html.Events exposing (onSubmit, onInput, onClick)
import List
import List.Extra exposing (find)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


type alias Id =
    { id : Int }


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
    | SubmitForm
    | PhxAddCheck Json.Encode.Value
    | PhxDeleteCheck Json.Encode.Value
    | PhxUpdateCheck Json.Encode.Value
    | SetNewUrl String
    | SetNewNumber String
    | SetNewResponse String
    | DeleteCheck Int
    | EditCheck Int


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
                |> Phoenix.Socket.on "remove_check" "checks:ad" PhxDeleteCheck
                |> Phoenix.Socket.on "update_check" "checks:ad" PhxUpdateCheck
                |> Phoenix.Socket.join channel

        model =
            { socket = initSocket
            , checks = []
            , next_check = new_next_check
            }
    in
        ( model, Cmd.map PhoenixMsg cmd )


idDecoder : Json.Decode.Decoder Id
idDecoder =
    Json.Decode.map Id
        (field "id" Json.Decode.int)


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

        PhxDeleteCheck raw ->
            case Json.Decode.decodeValue idDecoder raw of
                Ok data ->
                    ( { checks | checks = List.filter (\c -> c.id == data.id) checks.checks }, Cmd.none )

                Err error ->
                    Debug.log (error) ( checks, Cmd.none )

        PhxUpdateCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { checks
                        | checks =
                            List.map
                                (\c ->
                                    if c.id == check.id then
                                        check
                                    else
                                        c
                                )
                                checks.checks
                      }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log (error) ( checks, Cmd.none )

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

        SubmitForm ->
            let
                payload =
                    (Json.Encode.object [ ( "url", Json.Encode.string checks.next_check.url ), ( "notify_number", Json.Encode.string checks.next_check.notify_number ), ( "expected_code", Json.Encode.int checks.next_check.expected_code ) ])

                cmd =
                    Phoenix.Push.init "create_check" "checks:ad" |> Phoenix.Push.withPayload payload

                ( socket, phxCmd ) =
                    Phoenix.Socket.push cmd checks.socket
            in
                ( { checks | socket = socket, next_check = new_next_check }, Cmd.map PhoenixMsg phxCmd )

        DeleteCheck checkId ->
            let
                payload =
                    (Json.Encode.object [ ( "id", Json.Encode.int checkId ) ])

                cmd =
                    Phoenix.Push.init "remove_check" "checks:ad" |> Phoenix.Push.withPayload payload

                ( socket, phxCmd ) =
                    Phoenix.Socket.push cmd checks.socket
            in
                ( { checks | socket = socket }, Cmd.map PhoenixMsg phxCmd )

        EditCheck checkId ->
            let
                check =
                    find (\c -> c.id == checkId) checks.checks
            in
                case check of
                    Just check ->
                        ( { checks | next_check = check }, Cmd.none )

                    Nothing ->
                        ( checks, Cmd.none )


drawCheck : Check -> Html Msg
drawCheck check =
    Grid.row []
        [ Grid.col [] [ text check.url ]
        , Grid.col [] [ text check.notify_number ]
        , Grid.col [] [ text (toString check.expected_code) ]
        , Grid.col []
            [ Button.button [ Button.attrs [ onClick (EditCheck check.id) ] ]
                [ text "Edit" ]
            , Button.button
                [ Button.attrs [ onClick (DeleteCheck check.id) ] ]
                [ text "Delete" ]
            ]
        ]


drawChecks : List Check -> List (Html Msg)
drawChecks checks =
    checks |> List.map drawCheck


drawForm : Check -> List (Html Msg)
drawForm check =
    [ Form.form [ onSubmit SubmitForm ]
        [ Form.group []
            [ Form.label [ for "url" ] [ text "Url" ]
            , Input.text [ Input.id "url", Input.attrs [ value check.url, onInput SetNewUrl ] ]
            ]
        , Form.group []
            [ Form.label [ for "notify_no" ] [ text "Notify number" ]
            , Input.text [ Input.id "notify_no", Input.attrs [ value check.notify_number, onInput SetNewNumber ] ]
            ]
        , Form.group []
            [ Form.label [ for "expected_code" ] [ text "Expected response code" ]
            , Input.text [ Input.id "expected_code", Input.attrs [ value (toString check.expected_code), onInput SetNewResponse ] ]
            ]
        , Button.button [ Button.attrs [ type_ "submit" ] ] [ text "Save" ]
        ]
    ]


view : Checks -> Html Msg
view checks =
    div []
        ([ Grid.container []
            [ CDN.stylesheet
            , Grid.container [] (drawChecks checks.checks)
            ]
         ]
            ++ drawForm checks.next_check
        )


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
