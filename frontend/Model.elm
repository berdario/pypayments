module Model exposing (..)

import Common exposing (..)
import AccountsPage.Model as Accounts exposing (..)
import PaymentPage.Model as Payment exposing (..)

type Page = Accounts | Pay

type alias Model =
    { currentPage : Page
    , payment : Payment.Model
    , accounts : Accounts.Model
    }

type Action
    = SetActivePage Page
    | AccountsAction Accounts.Action
    | PaymentAction Payment.Action