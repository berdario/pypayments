module PaymentPage.Update exposing (..)

import Platform.Cmd as Cmd exposing (Cmd)
import Task
import Process

import PaymentPage.Model as Payment exposing (..)
import PaymentPage.Api exposing (pay)


delayedClear : Cmd Payment.Action
delayedClear =
    (Process.sleep 3000) |> Task.perform (\_ -> ClearLastTransactionOutcome)

update : Action -> Model -> (Model, Cmd Payment.Action)
update action model =
  case action of
    (SetSource id) -> let trans = model.newTransaction
                      in ({model | newTransaction={trans|source=id}}, Cmd.none)
    (SetRecipient id) -> let trans = model.newTransaction
                         in ({model | newTransaction={trans|recipient=id}}, Cmd.none)
    (SetAmount amount) -> let trans = model.newTransaction
                          in ({model | newTransaction={trans|amount=amount}}, Cmd.none)
    DoPayment -> (model, pay model.newTransaction)
    (LastTransactionOutcome outcome) -> ({model| lastTransaction=Just outcome}, delayedClear)
    ClearLastTransactionOutcome -> ({model| lastTransaction=Nothing}, Cmd.none)


