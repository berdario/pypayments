module PaymentPage.Update where

import Effects exposing (Effects)
import Task

import PaymentPage.Model as Payment exposing (..)
import PaymentPage.Api exposing (pay)


delayedClear : Effects Payment.Action
delayedClear =
    Task.sleep 3000 `Task.andThen` (\_ -> Task.succeed ClearLastTransactionOutcome)
    |> Effects.task

update : Action -> Model -> (Model, Effects Payment.Action)
update action model =
  case action of
    (SetSource id) -> let trans = model.newTransaction
                      in ({model | newTransaction={trans|source=id}}, Effects.none)
    (SetRecipient id) -> let trans = model.newTransaction
                         in ({model | newTransaction={trans|recipient=id}}, Effects.none)
    (SetAmount amount) -> let trans = model.newTransaction
                          in ({model | newTransaction={trans|amount=amount}}, Effects.none)
    DoPayment -> (model, pay model.newTransaction)
    (LastTransactionOutcome outcome) -> ({model| lastTransaction=Just outcome}, delayedClear)
    ClearLastTransactionOutcome -> ({model| lastTransaction=Nothing}, Effects.none)


