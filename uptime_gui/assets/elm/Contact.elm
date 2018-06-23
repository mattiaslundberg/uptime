module Contact exposing (..)

import Bootstrap.Table as Table
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Json.Decode exposing (field)
import Html exposing (Html, div, text)


type alias Model =
    { id : Int
    , name : String
    , number : String
    }


decoder : Json.Decode.Decoder Model
decoder =
    Json.Decode.map3 Model
        (field "id" Json.Decode.int)
        (field "name" Json.Decode.string)
        (field "number" Json.Decode.string)


viewNames : List Model -> Html ()
viewNames models =
    div []
        (List.map (\m -> viewName m) models)


viewName : Model -> Html ()
viewName model =
    div [] [ text model.name ]


drawListItem : Model -> Table.Row ()
drawListItem model =
    Table.tr []
        [ Table.td [] [ text model.name ]
        , Table.td [] [ text model.number ]
        , Table.td []
            [ ButtonGroup.buttonGroup []
                [ ButtonGroup.button [ Button.attrs [] ]
                    [ text "🖋️" ]
                , ButtonGroup.button
                    [ Button.attrs [] ]
                    [ text "❌" ]
                ]
            ]
        ]


drawList : List Model -> Html ()
drawList model =
    Table.simpleTable
        ( Table.simpleThead
            [ Table.th [] [ text "Name" ]
            , Table.th [] [ text "Number" ]
            , Table.th [] [ text "Actions" ]
            ]
        , Table.tbody []
            (List.map drawListItem model)
        )
