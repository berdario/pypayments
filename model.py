from decimal import Decimal

from faker import Faker
import sqlalchemy as sql

@sql.event.listens_for(sql.engine.Engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

sqlite = sql.create_engine('sqlite:///:memory:')

meta = sql.MetaData()
accounts = sql.Table('account', meta,
    sql.Column('id', sql.Integer, primary_key=True),
    sql.Column('name', sql.String),
    sql.Column('email', sql.String),
    sql.Column('balance', sql.Numeric, sql.CheckConstraint('balance>=0'), nullable=False),
)

transactions = sql.Table('transactions', meta,
    sql.Column('id', sql.Integer, primary_key=True),
    sql.Column('source_id', sql.Integer, sql.ForeignKey(accounts.c.id), index=True, nullable=False),
    sql.Column('recipient_id', sql.Integer, sql.ForeignKey(accounts.c.id), index=True, nullable=False),
    sql.Column('amount', sql.Numeric, sql.CheckConstraint('amount>=0')),
)


meta.create_all(sqlite)
meta.bind = sqlite

fake = Faker()
accounts.insert().execute([{'balance': 200,
                            'name': fake.user_name(),
                            'email': fake.email()} for _ in range(25)])

    
def update_balance(account_id: int, delta: int):
    new_balance = sql.select([accounts.c.balance + delta]).where(accounts.c.id == account_id)
    return accounts.update().where(accounts.c.id == account_id).values(balance=new_balance)

def get_all_accounts(connection=None):
    connection = connection or sqlite.connect()
    return connection.execute(accounts.select())


def get_account_transactions(account_id: int, connection=None):
    connection = connection or sqlite.connect()
    acct_transactions = transactions.select().where((transactions.c.source_id == account_id) | 
                                                    (transactions.c.recipient_id == account_id))
    return connection.execute(acct_transactions)

def record_payment_transaction(source: int, recipient: int, amount: Decimal, connection=None):
    connection = connection or sqlite.connect()
    with connection.begin():
        connection.execute(update_balance(source, -amount))
        connection.execute(update_balance(recipient, +amount))
        # inserting into transactions is not only needed for /account
        # but it also checks the id validity and for the amount to be positive
        connection.execute(transactions.insert().values(source_id=source,
                                                        recipient_id=recipient,
                                                        amount=amount))
