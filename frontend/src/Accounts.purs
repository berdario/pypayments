module Accounts where

import Prelude

import Control.Monad.Aff (Aff)
import Data.Foldable (fold)
import Data.Maybe (Maybe(..))
import Data.Map as Map
import Data.List (List, toUnfoldable)
import Data.Tuple (Tuple(..))

import Data.Foreign.Class (readJSON)
import Halogen
import Halogen.HTML.Indexed as H
import Halogen.HTML.Events.Indexed as E
import Network.HTTP.Affjax as HTTP

import Common


type State =
    { accounts :: Map.Map AccountId Account
    , accountTransactions :: Maybe (Array Transaction)
    , inspectedAccount :: Maybe AccountId
    }

data Query a
    = ToggleShowTransactions AccountId a
    | SetAccounts (Map.Map AccountId Account) a

data Slot = Slot
derive instance eqSlot :: Eq Slot
derive instance ordSlot :: Ord Slot

init :: State
init = {accounts: Map.empty, accountTransactions: Nothing, inspectedAccount: Nothing}

transactionToDiv (Transaction t) = H.div_
    [H.text (fold
        ["source: ", show t.source_id
        ," recipient: ", show t.recipient_id
        ," amount: ", show t.amount])]

accountToText id {name, email, balance} =
    H.text (fold
        ["id: ", show id
        ," name: ", name
        ," email: ", email
        ," balance: ", show balance])

transactionDetail :: Array Transaction -> ComponentHTML Query
transactionDetail trans = H.div_ $ map transactionToDiv trans

accountDiv id = H.div [E.onClick  (E.input_ (ToggleShowTransactions id))]

accountDataToHtml :: Maybe AccountId -> Maybe (Array Transaction) -> Tuple AccountId Account -> ComponentHTML Query
accountDataToHtml mAccount mTransactions (Tuple id (Account acct)) =
    let accountText = accountToText id acct
    in case Tuple (mAccount == Just id) mTransactions of
    Tuple true (Just trans) -> accountDiv id [accountText, transactionDetail trans]
    _ -> accountDiv id [accountText]

accountsComponent :: forall eff. Component State Query (Aff (AppEffects eff))
accountsComponent = component { render, eval }
    where

    render :: State -> ComponentHTML Query
    render {inspectedAccount, accountTransactions, accounts} = H.div_ $ map (accountDataToHtml inspectedAccount accountTransactions) $ toUnfoldable (Map.toList accounts)

    eval :: forall a. Query a -> (ComponentDSL State Query (Aff (AppEffects eff))) a
    eval (ToggleShowTransactions id next) = do
        {inspectedAccount, accountTransactions} <- get
        case Just id /= inspectedAccount of
            false -> modify _{inspectedAccount=Nothing}
            true -> do
                transactions <- fromAff $ getTransactions id
                modify $ (_{inspectedAccount=Just id, accountTransactions=transactions})
        pure next
    eval (SetAccounts accounts next) = do
        modify _{accounts=accounts}
        pure next

getTransactions :: forall eff. AccountId -> Aff (ajax :: HTTP.AJAX | eff) (Maybe (Array Transaction))
getTransactions id = do
    {response} <- HTTP.get (transactionsUrl id)
    let foreignTransactions = readJSON response
    -- TODO report ForeignError?
    pure $ toMaybe foreignTransactions

