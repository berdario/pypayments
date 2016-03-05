module PaymentPage.Api where

import Effects exposing (Effects)
import Http
import Json.Decode as Json
import Task

import Common exposing (..)
import PaymentPage.Model exposing (..)


pay {source, recipient, amount} =
    Http.post Json.value (payUrl source recipient amount) Http.empty
    |> Task.map (\_ -> LastTransactionOutcome Success)
    |> flip Task.onError (\_ -> Task.succeed (LastTransactionOutcome Fail))
    |> Effects.task