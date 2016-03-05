module Main where

import Dict exposing (Dict)
import Effects exposing (Effects, Never)
import StartApp
import Task

import Model exposing (..)
import View exposing (view)
import Api exposing (accounts)
import Update exposing (update)


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


