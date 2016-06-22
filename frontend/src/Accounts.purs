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
    { accountTransactions :: Maybe (Array Transaction)
    , inspectedAccount :: Maybe AccountId
    }

data Query a
    = ToggleShowTransactions AccountId a

data Slot = Slot
derive instance eqSlot :: Eq Slot
derive instance ordSlot :: Ord Slot

init :: State
init = {accountTransactions: Nothing, inspectedAccount: Nothing}

transactionToDiv (Transaction t) = H.div_
    [H.text (mconcat
        ["source: ", show t.source_id
        ," recipient: ", show t.recipient_id
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

accountsComponent :: forall eff. Map.Map AccountId Account -> Component State Query (Aff (AppEffects eff))
accountsComponent accounts = component { render, eval }
    where

    render :: State -> ComponentHTML Query
    render {inspectedAccount, accountTransactions} = H.div_ $ map (accountDataToHtml inspectedAccount accountTransactions) $ toUnfoldable (Map.toList accounts)

    eval :: Natural Query (ComponentDSL State Query (Aff (AppEffects eff)))
    eval (ToggleShowTransactions id next) = do
        {inspectedAccount, accountTransactions} <- gets (\x -> x) -- TODO no compile error over shadowing Halogen.get ?
        case Just id /= inspectedAccount of
            false -> modify _{inspectedAccount=Nothing}
            true -> do
                transactions <- fromAff $ getTransactions id
                modify $ (_{inspectedAccount=Just id, accountTransactions=transactions})
        pure next

getTransactions :: forall eff a. AccountId -> Aff (ajax :: AJAX | eff) (Maybe (Array Transaction))
getTransactions id = do
    {response} <- get (transactionsUrl id)
    let foreignTransactions = readJSON response
    -- TODO report ForeignError?
    return $ toMaybe foreignTransactions

