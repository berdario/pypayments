from unittest.mock import patch, call, MagicMock, ANY

from pytest import yield_fixture, raises
from sqlalchemy.exc import IntegrityError

import payments
from payments import sqlite, main as all_accounts, account_transactions, pay

# in these tests we rely on the builtin 25 fake users created in the payments module

@yield_fixture
def connection():
    conn = sqlite.connect()
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
    with patch.object(payments, 'accounts') as accounts:
        all_accounts()
    assert accounts.mock_calls[:2] == [call.select(),
                                       call.select().execute()]
                                       
def test_account_transactions():
    with patch.object(payments, 'transactions') as transactions:
        account_transactions(2)
    assert transactions.mock_calls[3:5] == [call.select().where(ANY),
                                            call.select().where(ANY).execute()]
                                            
def test_pay():
    m = MagicMock()
    pay(1, 2, 30, connection=m)
    queries = [str(c[1][0]) for c in m.execute.mock_calls]
    assert queries == ['UPDATE account SET balance=(SELECT account.balance + ? AS anon_1 \n'
                       'FROM account \n'
                       'WHERE account.id = ?) WHERE account.id = ?',
                       'UPDATE account SET balance=(SELECT account.balance + ? AS anon_1 \n'
                       'FROM account \n'
                       'WHERE account.id = ?) WHERE account.id = ?',
                       'INSERT INTO transactions (source_id, recipient_id, amount) VALUES (?, ?, ?)']
