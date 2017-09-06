// initialize replication
rs.initiate({
    _id: "rs0",
    version: 1,
    protocolVersion: 1,
    members: [
        {_id: 0, host: "db1.example.com:27017"},
        {_id: 1, host: "db2.example.com:27018"},
        {_id: 2, host: "arbiter1.example.com:47017", arbiterOnly: true}
    ],
    settings: {
        electionTimeoutMillis: 2000
    }
});
