module Accounts where

import Prelude

import Control.Monad (when)
import Control.Monad.Aff (Aff)
import Data.Foldable (intercalate, mconcat)
import Data.Maybe (Maybe(..))
import Data.Map as Map
import Data.List (List, toUnfoldable)
import Data.Tuple (Tuple(..))

import Data.Foreign.Class (readJSON)
import Halogen
import Halogen.HTML.Indexed as H
import Halogen.HTML.Events.Indexed as E
import Network.HTTP.Affjax (AJAX, get)

import Common


type State =
    { accounts :: Map.Map AccountId Account
    , accountTransactions :: Maybe (Array Transaction)
    , inspectedAccount :: Maybe AccountId
    }

data Query a
    = ToggleShowTransactions AccountId a
    | GetAccounts (List AccountId -> a)
    | SetAccounts (Map.Map AccountId Account) a

data Slot = Slot
derive instance eqSlot :: Eq Slot
derive instance ordSlot :: Ord Slot

init :: State
init = {accounts: Map.empty, accountTransactions: Nothing, inspectedAccount: Nothing}

transactionToDiv (Transaction t) = H.div_
    [H.text (mconcat
        ["source: ", show t.source
        ," recipient: ", show t.recipient
        ," amount: ", show t.amount])]

accountToText id {name, email, balance} =
    H.text (mconcat
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

    eval :: Natural Query (ComponentDSL State Query (Aff (AppEffects eff)))
    eval (ToggleShowTransactions id next) = do
        {inspectedAccount, accountTransactions} <- gets (\x -> x) -- TODO no compile error over shadowing Halogen.get ?
        when (Just id /= inspectedAccount) do
            transactions <- fromAff $ toggleInspection id accountTransactions
            modify $ (_{inspectedAccount=Just id, accountTransactions=transactions})
        pure next
    eval (GetAccounts continue) = do
        accounts <- gets $ _.accounts >>> Map.keys
        pure $ continue $ accounts
    eval (SetAccounts accounts next) = do
        modify _{accounts=accounts}
        pure next

toggleInspection :: forall eff a. AccountId -> Maybe a -> Aff (ajax :: AJAX | eff) (Maybe (Array Transaction))
toggleInspection _ (Just _) = return Nothing
toggleInspection id Nothing = do
    {response} <- get (transactionsUrl id)
    let foreignTransactions = readJSON response
    -- TODO report ForeignError?
    return $ toMaybe foreignTransactions

