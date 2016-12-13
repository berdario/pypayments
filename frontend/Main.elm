module Main exposing (..)

import Platform.Cmd as Cmd exposing (Cmd)
import Platform.Sub as Sub
import Html

import Model exposing (..)
import View exposing (view)
import Update exposing (update)

import AccountsPage.Model as Accounts
import PaymentPage.Model as Payment
import AccountsPage.Api exposing (accounts)


app =
  Html.program
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }


init : (Model, Cmd Action)
init =
  ( Model Accounts Payment.init Accounts.init
  , Cmd.map AccountsAction accounts)
