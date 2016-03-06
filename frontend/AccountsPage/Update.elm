module AccountsPage.Update where

import Effects exposing (Effects)
import Task

import Common exposing (..)
import AccountsPage.Model exposing (..)
import AccountsPage.Api exposing (accounts, accountTransactions)

    
toggleInspection : AccountId -> Model -> (Model, Effects Action)
toggleInspection id model =
    case (Just id == model.inspectedAccount, model.inspectedAccount) of
        (True, _) -> ({model | inspectedAccount=Nothing}, Effects.none)
        (False, Nothing) -> ({model | inspectedAccount=Just id}, accountTransactions id)
        (False, Just _) -> ({model | inspectedAccount=Just id, accountTransactions=Nothing},
                            accountTransactions id)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    (ToggleShowTransactions id) -> toggleInspection id model
    (FetchedAccounts Nothing) -> (model, Effects.none)
    (FetchedTransactions Nothing) -> (model, Effects.none)
    (FetchedAccounts (Just accts)) -> ({model | accounts=accts}, Effects.none)
    (FetchedTransactions (Just trans)) -> ({model | accountTransactions=Just trans}, Effects.none)

