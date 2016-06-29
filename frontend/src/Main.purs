module Main where

import Prelude

import Control.Monad.Aff (Aff)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception as Exc
import Control.Monad.Aff.Console (logShow)
import Control.Monad.Except (Except, except, withExcept, catchError, runExcept)
import Data.Array (zipWith)
import Data.Either (Either(..))
import Data.Foreign (Foreign, ForeignError(..))
import Data.Foreign.Class (class IsForeign, readProp, readJSON)
import Data.Foreign.Keys (keys)
import Data.Int (fromString)
import Data.Map as Map
import Data.Maybe (Maybe(..), maybe)
import Data.Functor.Coproduct (Coproduct, left)
import Data.Tuple (Tuple(..))
import Data.Traversable (traverse)

import Halogen
import Halogen.Component.ChildPath (ChildPath, cpL, cpR)
import Halogen.Util (awaitBody, runHalogenAff)
import Halogen.HTML.Indexed as H
import Halogen.HTML.Events.Indexed as E
import Network.HTTP.Affjax (AJAX, get)

import Common
import Accounts as Accounts
import Pay as Pay


data Page = Accounts | Pay

data Query a
    = SetActivePage Page a

type State = { page :: Page
             , accounts :: Map.Map AccountId Account
             }

initialState :: State
initialState = { page: Accounts, accounts: Map.empty }

type ChildState = Either Accounts.State Pay.State
type ChildQuery = Coproduct Accounts.Query Pay.Query
type ChildSlot = Either Accounts.Slot Pay.Slot

pathAccounts :: ChildPath Accounts.State ChildState Accounts.Query ChildQuery Accounts.Slot ChildSlot
pathAccounts = cpL

pathPay :: ChildPath Pay.State ChildState Pay.Query ChildQuery Pay.Slot ChildSlot
pathPay = cpR

type StateP g = ParentState State ChildState Query ChildQuery g ChildSlot
type QueryP = Coproduct Query (ChildF ChildSlot ChildQuery)

navbar :: forall g. ParentHTML ChildState Query ChildQuery g ChildSlot
navbar =
    H.nav_
            [ H.ul_ [
                H.li [E.onClick (E.input_ (SetActivePage Accounts))] [H.text "Transactions"],
                H.li [E.onClick (E.input_ (SetActivePage Pay))] [H.text "Make a payment"]
            ]
        ]


ui :: forall eff. Component (StateP (Aff (AppEffects eff))) QueryP (Aff (AppEffects eff))
ui = parentComponent {render, eval, peek: Nothing}
    where

    render :: State -> ParentHTML ChildState Query ChildQuery (Aff (AppEffects eff)) ChildSlot
    render {page} = H.div_
        [ navbar
        , case page of
              Accounts -> H.slot' pathAccounts Accounts.Slot \_ -> {component: Accounts.accountsComponent, initialState: Accounts.init}
              Pay -> H.slot' pathPay Pay.Slot \_ -> {component: Pay.payComponent, initialState: Pay.init}
        ]

    eval :: forall a. Query a -> (ParentDSL State ChildState Query ChildQuery (Aff (AppEffects eff)) ChildSlot) a
    eval (SetActivePage Pay next) = do
        modify (\state -> state{page=Pay})
        accounts <- gets $ _.accounts >>> Map.keys
        query' pathPay Pay.Slot $ action $ Pay.SetAccounts accounts
        pure next
    eval (SetActivePage Accounts next) = do
        modify _{page=Accounts}
        accounts <- fromAff $ getAccounts `catchError` (fromEither FromAjax <<< Left)
        case runExcept accounts of
            Right (ForeignAccounts accounts) -> modify _{accounts=accounts}
            Left e -> fromAff $ logShow e
        accounts <- gets _.accounts
        query' pathAccounts Accounts.Slot $ action $ Accounts.SetAccounts accounts
        pure next


data Error = FromForeign ForeignError | FromAjax Exc.Error

instance showError :: Show Error where
    show (FromForeign e) = show e
    show (FromAjax e) = show e

fromEither :: forall a b c f. (Applicative f) => (a -> b) -> Either a c -> f (Except b c)
fromEither conv e = pure $ withExcept conv $ except e

getAccounts :: forall eff. Aff (ajax :: AJAX | eff) (Except Error ForeignAccounts)
getAccounts = do
    {response} <- get accountsUrl
    fromEither FromForeign $ readJSON response

toInt :: String -> Either ForeignError Int
toInt x = maybe (Left $ JSONError "String is not a number") Right (fromString x)

foreignToNative :: forall v. (IsForeign v) => Foreign -> Either ForeignError (Map.Map Int v)
foreignToNative foreignMap = keys foreignMap >>= (traverse toInt) >>= changeForeignKeys foreignMap

changeForeignKeys :: forall v. (IsForeign v) => Foreign -> Array Int -> Either ForeignError (Map.Map Int v)
changeForeignKeys foreignMap indexes = (traverse (flip readProp foreignMap) indexes) <#> (zipWith Tuple indexes) <#> Map.fromFoldable

newtype ForeignAccounts = ForeignAccounts (Map.Map Int Account)

instance foreignMap :: IsForeign ForeignAccounts where
    read = map ForeignAccounts <<< foreignToNative

main :: Eff (AppEffects ()) Unit
main = runHalogenAff do
    body <- awaitBody
    driver <- runUI ui (parentState initialState) body
    driver $ left $ action $ SetActivePage Accounts