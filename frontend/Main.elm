module Main where

import Effects exposing (Effects, Never)
import StartApp
import Task

import Model exposing (..)
import View exposing (view)
import Update exposing (update)

import AccountsPage.Model as Accounts
import PaymentPage.Model as Payment
import AccountsPage.Api exposing (accounts)


app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }


init : (Model, Effects Action)
init =
  ( Model Accounts Payment.init Accounts.init
  , Effects.map AccountsAction accounts)


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


