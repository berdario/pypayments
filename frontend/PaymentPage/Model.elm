module PaymentPage.Model exposing (..)

import Common exposing (..)

type TransactionOutcome = Success | Fail

type alias Model =
    { newTransaction : Transaction
    , lastTransaction : Maybe TransactionOutcome
    }

type Action
    = SetSource AccountId
    | SetRecipient AccountId
    | SetAmount Float
    | DoPayment
    | LastTransactionOutcome TransactionOutcome
    | ClearLastTransactionOutcome

init : Model
init = Model {source=1, recipient=1, amount=0} Nothing