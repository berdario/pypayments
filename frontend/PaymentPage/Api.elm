module PaymentPage.Api exposing (..)

import Http
import Json.Decode as Json
import Task
import Result

import Common exposing (..)
import PaymentPage.Model exposing (..)

responseOutcome : Result x a -> Action
responseOutcome r =
    Result.map (\_ -> Success) r
    |> Result.withDefault Fail
    |> LastTransactionOutcome

pay {source, recipient, amount} =
    Http.post (payUrl source recipient amount) Http.emptyBody Json.value
    |> Http.send responseOutcome