module PaymentPage.Api exposing (..)

import Http
import Json.Decode as Json
import Task

import Common exposing (..)
import PaymentPage.Model exposing (..)


pay {source, recipient, amount} =
    Http.post Json.value (payUrl source recipient amount) Http.empty
    |> Task.perform (\_ -> Fail) (\_ -> Success)
    |> Cmd.map LastTransactionOutcome