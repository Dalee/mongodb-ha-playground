# Minimal MongDB 3.x High Availability setup

Setup cluster
```
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ ./setup.sh
```

Check current `primary` node:
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

Ensure test collection is exists and accessible:
```
$ mongo --quiet --port 27016 --eval "db.hello.find()" test-db
{ "_id" : ObjectId("59b0305101c76adf9a0cb8ee"), "name" : "world" }
```


Kill current `primary` node

```bash
$ kill -9 $(mongo --quiet --port 27017 --eval "JSON.stringify(db.serverStatus())" | jq '.pid.floatApprox')
```

Wait for few seconds...

Check current `primary` node:
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

Ensure test collection is exists and accessible:
```
$ mongo --quiet --port 27016 --eval "db.hello.find()" test-db
{ "_id" : ObjectId("59b0305101c76adf9a0cb8ee"), "name" : "world" }
```
