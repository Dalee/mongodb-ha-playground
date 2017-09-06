# Minimal MongoDB 3.2 High Availability setup

Vagrant based playground for setting up two MongoDB instances with
replication, failover and correct load balancing.

## setting up

```
$ vagrant up
$ vagrant ssh
$ /vagrant/setup.sh
```

Initial configuration:
* domains `db1.example.com`, `db2.example.com` and `arbiter1.example.com` are aliases for `127.0.0.1`
* mongodb on `db1.example.com:27017` is `primary`
* mongodb on `db2.example.com:27018` is `secondary`
* mongodb on `arbiter1.example.com:47017` is `arbiter`
* haproxy on port `27016` is mongodb balancer
* `replSetName` is `rs0` (it's just name for mongo-ha replication instances)
* `electionTimeoutMillis` is set to 2s

> Each run of setup.sh script, reverts state to initial configuration.

## checking setup

check current `primary` node:
```
$ mongo --quiet --port 27016 --eval "db.isMaster()"
{
	"hosts" : [
		"db1.example.com:27017",
		"db2.example.com:27018"
	],
	"arbiters" : [
		"arbiter1.example.com:47017"
	],
	"setName" : "rs0",
	"setVersion" : 1,
	"ismaster" : true,
	"secondary" : false,
	"primary" : "db1.example.com:27017",
	"me" : "db1.example.com:27017",
	"electionId" : ObjectId("7fffffff0000000000000001"),
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"maxWriteBatchSize" : 1000,
	"localTime" : ISODate("2017-09-06T17:22:16.887Z"),
	"maxWireVersion" : 4,
	"minWireVersion" : 0,
	"ok" : 1
}
```

create sample database and collection via `haproxy`:
```
$ mongo --quiet --port 27016 --eval 'db.hello.insert({"name":"world"});' test-db
switched to db test-db
WriteResult({ "nInserted" : 1 })
```

ensure test collection is exists and accessible via `haproxy`:
```
$ mongo --quiet --port 27016 --eval "db.hello.find()" test-db
{ "_id" : ObjectId("59b04b541e80cc01f7d66afd"), "name" : "world" }
```

## testing failover

kill current `primary` node:
```bash
$ kill -9 $(mongo --quiet --port 27017 --eval "JSON.stringify(db.serverStatus())" | jq '.pid.floatApprox')
```

wait for few seconds (should happen within `electionTimeoutMillis`)...

ensure current `primary` node is on port `27018` and accessible via `haproxy`:
```
$ mongo --quiet --port 27016 --eval "db.isMaster()"
{
	"hosts" : [
		"db1.example.com:27017",
		"db2.example.com:27018"
	],
	"arbiters" : [
		"arbiter1.example.com:47017"
	],
	"setName" : "rs0",
	"setVersion" : 1,
	"ismaster" : true,
	"secondary" : false,
	"primary" : "db2.example.com:27018",
	"me" : "db2.example.com:27018",
	"electionId" : ObjectId("7fffffff0000000000000002"),
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"maxWriteBatchSize" : 1000,
	"localTime" : ISODate("2017-09-06T17:23:38.045Z"),
	"maxWireVersion" : 4,
	"minWireVersion" : 0,
	"ok" : 1
}
```

ensure test collection and database exists and accessible via `haproxy`:
```
$ mongo --quiet --port 27016 --eval "db.hello.find()" test-db
{ "_id" : ObjectId("59b0305101c76adf9a0cb8ee"), "name" : "world" }
```

## return failed mongodb node back

start killed node:
```
$ sudo systemctl start mongodb-27017
```

ensure mongodb node on port `27017` is `secondary`:
```
$ mongo --quiet --port 27017 --eval "db.isMaster()"
{
	"hosts" : [
		"db1.example.com:27017",
		"db2.example.com:27018"
	],
	"arbiters" : [
		"arbiter1.example.com:47017"
	],
	"setName" : "rs0",
	"setVersion" : 1,
	"ismaster" : false,
	"secondary" : true,
	"primary" : "db2.example.com:27018",
	"me" : "db1.example.com:27017",
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"maxWriteBatchSize" : 1000,
	"localTime" : ISODate("2017-09-06T19:29:12.940Z"),
	"maxWireVersion" : 4,
	"minWireVersion" : 0,
	"ok" : 1
}
```
