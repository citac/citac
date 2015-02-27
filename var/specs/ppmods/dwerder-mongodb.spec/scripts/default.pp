# https://forge.puppetlabs.com/dwerder/mongodb

include mongodb
mongodb::mongod {
  'my_mongod_instanceX':
    mongod_instance    => 'mongodb1',
    mongod_replSet     => 'mongoShard1',
    mongod_add_options => ['slowms = 50']
}