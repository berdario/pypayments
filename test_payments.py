from unittest.mock import patch, call, MagicMock, ANY

from pytest import yield_fixture, raises

import payments
from payments import main as all_accounts, account_transactions, pay as do_payment
import model
from model import IntegrityError

# in these tests we rely on the builtin 25 fake users created in the payments module

pay = model.record_payment_transaction

@yield_fixture
def connection():
    conn = model.sqlite.connect()
    with conn.begin() as transaction:
        yield conn
        transaction.rollback()

def test_successful_payment(connection):
    pay(source=1, recipient=2, amount=30, connection=connection)
    accts = all_accounts()
    assert accts[1]['balance'] == 170
    assert accts[2]['balance'] == 230

def test_successful_payment2(connection):
    """This test verifies that tests changes are properly rollbacked"""
    accts = all_accounts()
    assert accts[1]['balance'] == 200
    pay(1, 2, 30, connection)
    accts = all_accounts()
    assert accts[1]['balance'] == 170
    assert accts[2]['balance'] == 230
    
def test_balance_can_go_to_zero(connection):
    pay(1, 2, 200, connection)
    assert all_accounts()[1]['balance'] == 0
    
def test_transaction_log(connection):
    pay(1, 2, 30, connection)
    pay(2, 3, 30, connection)
    assert len(account_transactions(2)) == 2
    
def test_give_back_money(connection):
    before = all_accounts()
    pay(1, 2, 30, connection)
    pay(2, 1, 30, connection)
    after = all_accounts()
    assert before == after

def test_negative_balance(connection):
    with raises(IntegrityError):
        pay(1, 2, 200.01, connection)
    
def test_nonexisting_account_id(connection):
    with raises(IntegrityError):
        pay(101, 2, 10, connection)
    
def test_negative_amount(connection):
    with raises(IntegrityError):
        pay(1, 2, -1, connection)
        
        
def test_all_accounts():
    with patch.object(payments, 'get_all_accounts') as mocked_model:
        all_accounts()
    assert mocked_model.call_args == ()
                                       
def test_account_transactions():
    with patch.object(payments, 'get_account_transactions') as mocked_model:
        account_transactions(2)
    assert mocked_model.call_args == call(2)

def test_pay():
    with patch.object(payments, 'record_payment_transaction') as mocked_model:
        do_payment(1, 2, 30)
    assert mocked_model.call_args == call(1, 2, 30)
