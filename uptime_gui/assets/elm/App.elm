module App exposing (..)

import Json.Encode
import Bootstrap.Table as Table
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Form.Input as Input
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Json.Decode exposing (field)
import Html exposing (Html, li, text, div, ul, form, label, input, button, span, h1, h2)
import Html.Attributes exposing (value, for, type_, class)
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
    , notifyNumber : String
    , expectedCode : Int
    }


type alias Model =
    { connection : Connection
    , checks : List Check
    , nextCheck : Check
    }


type alias Connection =
    { socket : Phoenix.Socket.Socket Msg
    , token : String
    , userId : Int
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


newNextCheck : Check
newNextCheck =
    Check 0 "" "" 200


init : ( Model, Cmd Msg )
init =
    let
        -- FIXME: Get token and userId from localstorage
        token =
            "4SlMa4K%2FsJdt4810c8%2FbJhU0z7Ur0fqC4eNQR1nwDnujMa64Qvhibbs1HMACETwatZXHT0cjW%2FTNfBj06c5g2g%3D%3D"

        userId =
            1

        channel =
            Phoenix.Channel.init (channelName userId)
                |> Phoenix.Channel.withPayload (Json.Encode.object [ ( "token", Json.Encode.string token ) ])

        ( initSocket, cmd ) =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                -- FIXME: Get from js?
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "create_check" (channelName userId) PhxAddCheck
                |> Phoenix.Socket.on "remove_check" (channelName userId) PhxDeleteCheck
                |> Phoenix.Socket.on "update_check" (channelName userId) PhxUpdateCheck
                |> Phoenix.Socket.join channel

        connection =
            { socket = initSocket, token = token, userId = userId }

        model =
            { connection = connection
            , checks = []
            , nextCheck = newNextCheck
            }
    in
        ( model, Cmd.map PhoenixMsg cmd )


channelName : Int -> String
channelName userId =
    "checks:" ++ toString userId


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


updateSocket : Phoenix.Socket.Msg Msg -> Model -> ( Model, Cmd Msg )
updateSocket msg model =
    let
        conn =
            model.connection

        ( socket, cmd ) =
            Phoenix.Socket.update msg conn.socket
    in
        ( { model | connection = { conn | socket = socket } }, Cmd.map PhoenixMsg cmd )


push : Phoenix.Push.Push Msg -> Connection -> ( Connection, Cmd Msg )
push cmd conn =
    let
        ( socket, phxCmd ) =
            Phoenix.Socket.push cmd conn.socket
    in
        ( { conn | socket = socket }, Cmd.map PhoenixMsg phxCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            updateSocket msg model

        PhxAddCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { model | checks = check :: model.checks }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log (error)
                        ( model, Cmd.none )

        PhxDeleteCheck raw ->
            case Json.Decode.decodeValue idDecoder raw of
                Ok data ->
                    ( { model | checks = List.filter (\c -> c.id /= data.id) model.checks }, Cmd.none )

                Err error ->
                    Debug.log (error) ( model, Cmd.none )

        PhxUpdateCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { model | checks = updateCheck model.checks check }, Cmd.none )

                Err error ->
                    Debug.log (error) ( model, Cmd.none )

        SetNewUrl str ->
            let
                current =
                    model.nextCheck
            in
                ( { model | nextCheck = { current | url = str } }, Cmd.none )

        SetNewNumber str ->
            let
                current =
                    model.nextCheck
            in
                ( { model | nextCheck = { current | notifyNumber = str } }, Cmd.none )

        SetNewResponse str ->
            let
                current =
                    model.nextCheck

                newValue =
                    Result.withDefault model.nextCheck.expectedCode (String.toInt str)
            in
                ( { model | nextCheck = { current | expectedCode = newValue } }, Cmd.none )

        SubmitForm ->
            let
                ( conn, phxCmds ) =
                    push (generateSubmitFormCommand model.connection.userId model.nextCheck) model.connection
            in
                ( { model | connection = conn, nextCheck = newNextCheck }, phxCmds )

        DeleteCheck checkId ->
            let
                payload =
                    (Json.Encode.object [ ( "id", Json.Encode.int checkId ) ])

                cmd =
                    Phoenix.Push.init "remove_check" (channelName model.connection.userId) |> Phoenix.Push.withPayload payload

                ( conn, phxCmds ) =
                    push cmd model.connection
            in
                ( { model | connection = conn }, phxCmds )

        EditCheck checkId ->
            let
                check =
                    find (\c -> c.id == checkId) model.checks
            in
                case check of
                    Just check ->
                        ( { model | nextCheck = check }, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )


updateCheck : List Check -> Check -> List Check
updateCheck checks check =
    List.map
        (\c ->
            if c.id == check.id then
                check
            else
                c
        )
        checks


generateSubmitFormCommand : Int -> Check -> Phoenix.Push.Push Msg
generateSubmitFormCommand userId check =
    let
        payload =
            Json.Encode.object (generateFormSerializer check)

        command =
            (if check.id == 0 then
                "create_check"
             else
                "update_check"
            )
    in
        Phoenix.Push.init command (channelName userId) |> Phoenix.Push.withPayload payload


generateFormSerializer : Check -> List ( String, Json.Encode.Value )
generateFormSerializer check =
    if check.id == 0 then
        [ ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]
    else
        [ ( "id", Json.Encode.int check.id ), ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]


drawCheck : Check -> Table.Row Msg
drawCheck check =
    Table.tr []
        [ Table.td [] [ text check.url ]
        , Table.td [] [ text check.notifyNumber ]
        , Table.td [] [ text (toString check.expectedCode) ]
        , Table.td []
            [ ButtonGroup.buttonGroup []
                [ ButtonGroup.button [ Button.attrs [ onClick (EditCheck check.id) ] ]
                    [ text "🖋️" ]
                , ButtonGroup.button
                    [ Button.attrs [ onClick (DeleteCheck check.id) ] ]
                    [ text "❌" ]
                ]
            ]
        ]


drawChecks : List Check -> Html Msg
drawChecks model =
    Table.simpleTable
        ( Table.simpleThead
            [ Table.th [] [ text "Url" ]
            , Table.th [] [ text "Notify number" ]
            , Table.th [] [ text "Expected response" ]
            , Table.th [] [ text "Actions" ]
            ]
        , Table.tbody []
            (model
                |> List.map drawCheck
            )
        )


drawEditMessage : Check -> Html Msg
drawEditMessage check =
    let
        t =
            if check.id == 0 then
                "Create new check"
            else
                "Edit check"
    in
        Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text t ] ] ]


drawForm : Check -> List (Html Msg)
drawForm check =
    [ drawEditMessage check
    , Form.form [ onSubmit SubmitForm ]
        [ Form.group []
            [ Form.label [ for "url" ] [ text "Url" ]
            , Input.text [ Input.id "url", Input.attrs [ value check.url, onInput SetNewUrl ] ]
            ]
        , Form.group []
            [ Form.label [ for "notify_no" ] [ text "Notify number" ]
            , Input.text [ Input.id "notify_no", Input.attrs [ value check.notifyNumber, onInput SetNewNumber ] ]
            ]
        , Form.group []
            [ Form.label [ for "expected_code" ] [ text "Expected response code" ]
            , Input.text [ Input.id "expected_code", Input.attrs [ value (toString check.expectedCode), onInput SetNewResponse ] ]
            ]
        , Button.button [ Button.attrs [ type_ "submit", class "float-right" ] ] [ text "Save" ]
        ]
    ]


view : Model -> Html Msg
view model =
    div []
        ([ div []
            [ CDN.stylesheet
            , Grid.container []
                ([ Grid.row [] [ Grid.col [] [ h1 [ class "text-center" ] [ text "Uptime" ] ] ]
                 , Grid.row [] [ Grid.col [] [ div [ class "text-center" ] [ text "Monitors uptime for selected sites and notifies by text in case of problems." ] ] ]
                 , Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text "Active checks" ] ] ]
                 , Grid.row [] [ Grid.col [] [ text " " ] ]
                 ]
                    ++ [ drawChecks model.checks ]
                )
            ]
         ]
            ++ drawForm model.nextCheck
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.connection.socket PhoenixMsg


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
