module Update exposing (..)

import Platform.Cmd as Cmd exposing (Cmd)
import Task

import Model exposing (..)

import AccountsPage.Api exposing (accounts)
import AccountsPage.Update as Accounts
import PaymentPage.Update as Payment

import PaymentPage.Model


updatePage : Page -> Model -> (Model, Cmd Action)
updatePage page model = if model.currentPage == page
    then (model, Cmd.none)
    else case page of
        Accounts -> ( {model | currentPage=page}
                    , (Cmd.map AccountsAction accounts))
        Pay -> ( {model | currentPage=page, payment=PaymentPage.Model.init}
               , Cmd.none)

update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    (SetActivePage page) -> updatePage page model
    (AccountsAction action) -> let (acctsModel, fx) = Accounts.update action model.accounts
                               in ({model | accounts=acctsModel}, Cmd.map AccountsAction fx)
    (PaymentAction action) -> let (paymentModel, fx) = Payment.update action model.payment
                              in ({model | payment=paymentModel}, Cmd.map PaymentAction fx)

