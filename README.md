# Installation
## Local
1. Check that you have SQLite installed: `sqlite3 --version`. MacOS X 10.5 and greater already has SQLite preinstalled.
2. Install ruby. There are many ways to do this. On MacOS you can run `brew install ruby`. Make sure that you use v3.1.3.
3. Go to the application root and run `gem install bundler`
4. From the application root install all the dependencies using `bundle install`
4. From the application root build the database `rails db:drop db:setup`
4. From the application root start the application: `rails s`
## Docker
1. Make sure you have Docker installed https://docs.docker.com/get-docker/
2. Go to the root directory of the application
3. `docker build -t fetch-service -f Dockerfile.rails .`
4. Start the application: `docker run -p 3000:3000 -it -v $PWD:/opt/app fetch-service`

# Testing
## Access the web service using cURL
### Create transactions

```
$ curl -X POST -H 'Content-Type: application/json' -d '{"payer":"DANNON","points":300,"timestamp":"2022-10-31T10:00:00Z"}' localhost:3000/user/1/transactions
{"id":1,"user_id":1,"payer_id":1,"points":300,"adjusted_points":300,"ts":"2022-10-31T10:00:00.000Z","is_used":false,"created_at":"2022-12-27T19:39:59.596Z"}
```

```
$ curl -X POST -H 'Content-Type: application/json' -d '{"payer":"UNILEVER","points":200,"timestamp":"2022-10-31T11:00:00Z"}' localhost:3000/user/1/transactions
{"id":2,"user_id":1,"payer_id":2,"points":200,"adjusted_points":200,"ts":"2022-10-31T11:00:00.000Z","is_used":false,"created_at":"2022-12-27T19:41:23.180Z"}
```

```
$ curl -X POST -H 'Content-Type: application/json' -d '{"payer":"DANNON","points":-200,"timestamp":"2022-10-31T15:00:00Z"}' localhost:3000/user/1/transactions
{"id":3,"user_id":1,"payer_id":1,"points":-200,"adjusted_points":0,"ts":"2022-10-31T15:00:00.000Z","is_used":true,"created_at":"2022-12-27T19:43:47.192Z"}
```

```
$ curl -X POST -H 'Content-Type: application/json' -d '{"payer":"MILLER COORS","points":10000,"timestamp":"2022-11-01T14:00:00Z"}' localhost:3000/user/1/transactions
{"id":4,"user_id":1,"payer_id":3,"points":10000,"adjusted_points":10000,"ts":"2022-11-01T14:00:00.000Z","is_used":false,"created_at":"2022-12-27T19:47:57.324Z"}
```

```
$ curl -X POST -H 'Content-Type: application/json' -d '{"payer":"DANNON","points":1000,"timestamp":"2022-11-02T14:00:00Z"}' localhost:3000/user/1/transactions
{"id":5,"user_id":1,"payer_id":1,"points":1000,"adjusted_points":1000,"ts":"2022-11-02T14:00:00.000Z","is_used":false,"created_at":"2022-12-27T19:49:28.921Z"}
```

### Spend points
```
$ curl -X POST -H 'Content-Type: application/json' -d '{"points":5000}' localhost:3000/user/1/spends
[{"payer":"DANNON","points":-100},{"payer":"UNILEVER","points":-200},{"payer":"MILLER COORS","points":-4700}]
```
### Check the balances
```
$ curl http://localhost:3000/user/1/spends/balances
{"DANNON":1000,"MILLER COORS":5300,"UNILEVER":0}
```

## Run unit tests
```
$ rspec -fd

SpendsController
  POST #create
    spends points and returns points breakdown
    returns error response for non existing user
    returns error response when points is not passed
  GET #balances
    returns points breakdown
    returns error response for non existing user

TransactionsController
  POST #create
    creates points transaction
    returns error response for non existing user
    returns error response when points is not passed
  GET #index
    returns transactions
    returns error response for non existing user

RewardPoints
  #save
    when user or timestamp are not provided
      validates presence of user and timestamp
    when points is zero
      disables saving of zero points
    when payer with the given name does not exist
      disables saving with incorrect payer name
    when points is a positive number
      creates point transaction with positive points
    when points is a negative number
      checks for insufficient points
      creates a transaction with negative amount and deduces points from other transactions of the payer

SpendPoints
  #save
    when user is not provided
      validates presence of user and timestamp
    when points is negative
      disables saving of zero points
    when enough of points exist
      creates point transaction with positive points
      when multiple point transactions from different payers exist
        splits spendings between many transactions of different payers if payer is not passed
        splits spendings between transactions of the payer if payer is passed

Payer
  validates presence of name
  validates uniqueness of name

PointTransaction
  validations
    validates presence of payer
    validates presence of user
    validates presence of points
    validates presence of timestamp
    validates presence of adjusted_points
    validates numericality of points
    validates numericality of adjusted points
  .unused
    returns transactions with is_used set and does not include others
  .balances
    returns balances for every payer

User
  validates presence of name
  validates uniqueness of name

Finished in 0.27134 seconds (files took 0.80081 seconds to load)
34 examples, 0 failures
```
# Implementation notes
I chose Ruby on Rails as the most recent web framework I worked with. The data is persisted in SQLite. SQLite is preinstalled on MacOS so the engineer who checks the submission will only need to install ruby and follow the instructions. Alternatively, I've provided a Docker configuration so that no installations would be required. Please refer the the Installation section above.

## DB schema
![DB Diagram](doc/fetch.png?raw=true "Database Diagram")

The tables users and payers are created to have entities with primary keys to be referenced, i.e. normalized schema.
The main table is `point_transactions`.
- `id` is primary key
- `user_id` is a foreign key to users table
- `payer_id` is a foreign key to payers table
- `points` is **initial** point value
- `adjusted_points` initially has the same value as points but the logic subtracts actual spent amount from this field until it becomes zero
- `is_used` - when the full amount of the transaction is spent this field becomes TRUE. It can help with indexing. Alternatively we can use a condition like `adjusted_points = 0`.
- `ts` - timestamp of the transacion

## Application logic
When we create a new transaction we insert it to `point_transactions`. If it has a negative value we also "spend" this amount of points using a "waterfall" logic:
1. Find all not fully spent transactions (NOT is_used), **created for this payer**, ordered by timestamp
2. Iterate on the transactions, reducing `adjusted_points` as we go, until the amount is fully spent or there are no transactions left.
3. If the amount is not fully spent, the we have insufficient points amount, otherwise we can proceed.

The logic for spending points is the same as above with the only difference: we check transactions from all payers.
The logic is encapsulated in app/form_objects/reward_points.rb and app/form_objects/spend_points.rb.

To calculate the balances, we can simply sum up all `adjusted_points`, grouped by payer id.

# Suggestions
I've followed the requirements but I have certain suggestions for improvements:
- Balances are returned as json with payer names as keys and balances as values. A format like the one used for spending would be easier to process: `[{ "payer": "DANNON", "points": -100 }]` and would be more consistent.
- Transactions with negative values in the requests is a use case that is hard to understand. Is this for "manually" correcting the balances?
