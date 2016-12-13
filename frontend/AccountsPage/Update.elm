module AccountsPage.Update exposing (..)

import Platform.Cmd as Cmd exposing (Cmd)
import Task

import Common exposing (..)
import AccountsPage.Model exposing (..)
import AccountsPage.Api exposing (accounts, accountTransactions)


toggleInspection : AccountId -> Model -> (Model, Cmd Action)
toggleInspection id model =
    case (Just id == model.inspectedAccount, model.inspectedAccount) of
        (True, _) -> ({model | inspectedAccount=Nothing}, Cmd.none)
        (False, Nothing) -> ({model | inspectedAccount=Just id}, accountTransactions id)
        (False, Just _) -> ({model | inspectedAccount=Just id, accountTransactions=Nothing},
                            accountTransactions id)

update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    (ToggleShowTransactions id) -> toggleInspection id model
    (FetchedAccounts Nothing) -> (model, Cmd.none)
    (FetchedTransactions Nothing) -> (model, Cmd.none)
    (FetchedAccounts (Just accts)) -> ({model | accounts=accts}, Cmd.none)
    (FetchedTransactions (Just trans)) -> ({model | accountTransactions=Just trans}, Cmd.none)

