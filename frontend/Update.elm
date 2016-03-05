module Update where

import Effects exposing (Effects)
import Task

import Model exposing (..)

import AccountsPage.Api exposing (accounts)
import AccountsPage.Update as Accounts
import PaymentPage.Update as Payment

import PaymentPage.Model

    
updatePage : Page -> Model -> (Model, Effects Action)
updatePage page model = if model.currentPage == page
    then (model, Effects.none)
    else case page of
        Accounts -> ( {model | currentPage=page}
                    , (Effects.map AccountsAction accounts))
        Pay -> ( {model | currentPage=page, payment=PaymentPage.Model.init}
               , Effects.none)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    (SetActivePage page) -> updatePage page model
    (AccountsAction action) -> let (acctsModel, fx) = Accounts.update action model.accounts
                               in ({model | accounts=acctsModel}, Effects.map AccountsAction fx)
    (PaymentAction action) -> let (paymentModel, fx) = Payment.update action model.payment
                              in ({model | payment=paymentModel}, Effects.map PaymentAction fx)
    
