module Update where

import Effects exposing (Effects)
import Task

import Model exposing (..)
import Api exposing (accounts, accountTransactions, pay)

    
updatePage : Page -> Model -> (Model, Effects Action)
updatePage page model = if model.currentPage == page
    then (model, Effects.none)
    else ({model | currentPage=page}, accounts) 

toggleInspection : AccountId -> Model -> (Model, Effects Action)
toggleInspection id model =
    case (Just id == model.inspectedAccount, model.inspectedAccount) of
        (True, _) -> ({model | inspectedAccount=Nothing}, Effects.none)
        (False, Nothing) -> ({model | inspectedAccount=Just id}, accountTransactions id)
        (False, Just _) -> ({model | inspectedAccount=Just id, accountTransactions=Nothing},
                            accountTransactions id)

delayedClear : Effects Action
delayedClear =
    Task.sleep 3000 `Task.andThen` (\_ -> Task.succeed ClearLastTransactionOutcome)
    |> Effects.task

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    (SetActivePage page) -> updatePage page model
    (SetSource id) -> let trans = model.newTransaction
                      in ({model | newTransaction={trans|source=id}}, Effects.none)
    (SetRecipient id) -> let trans = model.newTransaction
                         in ({model | newTransaction={trans|recipient=id}}, Effects.none)
    (SetAmount amount) -> let trans = model.newTransaction
                          in ({model | newTransaction={trans|amount=amount}}, Effects.none)
    DoPayment -> (model, pay model.newTransaction)
    (ToggleShowTransactions id) -> toggleInspection id model
    (LastTransactionOutcome outcome) -> ({model| lastTransaction=Just outcome}, delayedClear)
    ClearLastTransactionOutcome -> ({model| lastTransaction=Nothing}, Effects.none)
    (FetchedAccounts Nothing) -> (model, Effects.none)
    (FetchedTransactions Nothing) -> (model, Effects.none)
    (FetchedAccounts (Just accts)) -> ({model|accounts=accts}, Effects.none)
    (FetchedTransactions (Just trans)) -> ({model|accountTransactions=Just trans}, Effects.none)

