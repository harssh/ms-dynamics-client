# Microsoft Dynamics API Client
Ruby library for accessing Microsoft Dynamics 365 and 2016 via the Microsoft Web API.

## Installation

Add this line to your application's Gemfile:

    gem 'msdynamics'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install msdynamics

## Usage

#### Access token authentication

To obtain access token you will need to create Dynamics application at portal.azure.com and setup callback urls and secret code. Provide API permissions. This keeps API access under Dynamics control.
Than create Application User in Dynamics and provide Application ID from Azure Portal to this user. Providing all access the APP has to this Application User. Also Update Application User role according to your requirements.

```ruby
client = MSDynamics.new({
    hostname: "https://test.crm3.dynamics.com",
    tenant_id: "djhksjdhu3ye83y",
    client_id: "absjkdh3ewrwr",
    client_secret: "djskdhak82u3kjhk"
})
```
### Arguments
1. hostname  : Host URL for dynamics instance.
2. tenant_id   : tenant_id of the Dynamics App created for S2S API communication
3. client_id   : client_id of the Dynamics App created for S2S API communication
4. client_secret   : client_secret of the Dynamics App created for S2S API communication

To set up API user you will need to create an Application User and assign the Application ID to this user. User Role of Application User decides to what entities this client will have access to.

### Retrieving entity records

Entity types are: `accounts`, `contacts`, `leads` and `opportunities`
```ruby
accounts = client.get_entity_records('accounts', "$top3")
contacts = client.get_entity_records('contacts', "$top3")
leads = client.get_entity_records('leads', "$top3")
opportunities = client.get_entity_records('opportunities', "$top3")
```

### Modifying or creating entity records

Modifying or creating entity records is currently not supported by this library. Pull or feature requests are welcome!

### OAuth Token Refresh

```ruby
new_token_object = client.refresh_token
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
