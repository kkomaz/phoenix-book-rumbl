port module AnnotPane exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Time


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


initModel : ( Model, Cmd Msg )
initModel =
    ( Model [] "", Cmd.none )



-- update


type Msg
    = Received Annot
    | Post String
    | Timeout Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Received annot ->
            ( model, Cmd.none )

        Post text ->
            ( model, Cmd.none )

        Timeout time ->
            Debug.log "Timeout" ( model, rewind (round time) )



-- subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every Time.second Timeout



-- port


port rewind : Int -> Cmd msg



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
    App.program
        { init = initModel
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
