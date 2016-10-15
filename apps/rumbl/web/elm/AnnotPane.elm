module AnnotPane exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App


-- model


type alias Model =
    { annots : List Annot
    , inputMessage : String
    }


type alias Annot =
    { at : Int
    , name : String
    , text : String
    }


initModel : Model
initModel =
    Model [] ""



-- update


type Msg
    = Received Annot
    | Post String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Received annot ->
            model

        Post text ->
            model



-- view


view : Model -> Html Msg
view model =
    div [ class "panel panel-default" ]
        [ div [ class "panel-heading" ]
            [ h3 [ class "panel-title" ]
                [ text "Annotations" ]
            ]
        , div [ class "panel-body annotations", id "msg-container" ]
            []
        , div [ class "panel-footer" ]
            [ textarea [ class "form-control", id "msg-input", placeholder "Comment...", attribute "rows" "3" ]
                []
            , button [ class "btn btn-primary form-control", id "msg-submit", type' "submit" ]
                [ text "Post" ]
            ]
        ]


main : Program Never
main =
    App.beginnerProgram
        { model = initModel
        , update = update
        , view = view
        }
