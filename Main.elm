module Main where
import Effects exposing (Effects, Never)
import Dict exposing (Dict)
import Http
import Html
import Html.Events
import Html.Attributes

import StartApp
import String
import Task

import Model exposing (..)
import View exposing (view)
import Update exposing (Action(..), update, accounts)


app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }


init : (Model, Effects Action)
init =
  ( Model Dict.empty Nothing Nothing {source=0, recipient=0, amount=0} Transactions Nothing
  , accounts)


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


