# Catalog API

[![Build Status](https://api.travis-ci.org/ManageIQ/catalog-api.svg)](https://travis-ci.org/ManageIQ/catalog-api)
[![Maintainability](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/maintainability)](https://codeclimate.com/github/ManageIQ/catalog-api/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/test_coverage)](https://codeclimate.com/github/ManageIQ/catalog-api/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/catalog-api/master.svg)](https://hakiri.io/github/ManageIQ/catalog-api/master)

## OpenAPI for Rails 5

This is a project to provide OpenAPI support inside the [Ruby on Rails](http://rubyonrails.org/) framework.

## Prerequisites
You need to install ruby >= 2.2.2 and run:

```
bundle install
```

## Getting started

## Environmental variables
```
export CATALOG_DATABASE_USERNAME=<<database_user>>
export CATALOG_DATABASE_PASSSWORD=<<database_password>>
or
export DATABASE_URL=postgres://pguser:pgpass@localhost/somedatabase
export MANAGEIQ_USER=admin
export MANAGEIQ_PASSWORD=smartvm
export MANAGEIQ_HOST=localhost
export MANAGEIQ_PORT=3000
```

If the topology inventory requires authentication (ie in dev), basic authentication is supported via these variables. They won't be read in unless :
```
export DEV_USERNAME=myuser
export DEV_PASSWORD=password
```

```
bin/rake db:create db:migrate
bin/rails s
```


## Force Puma to use another port

Puma ignores the `-p` flag with `bin/rails s`

```
env PORT=4000 rails s
```

## Rails server with SSL

Example uses port 3000

```
bin/rails s -b 'ssl://localhost:3000?key=config/ssl/localhost.key&cert=config/ssl/localhost.crt'
```

## Routes

To list all your routes, use:

```
bin/rake routes
```

## Testing with Dev Insights UI

If you want to run the catalog locally on your dev machine but access the UI on the dev cluster you would need to do the following

Install Docker in your machine

Clone the following repo to your dev machine

[Insights Proxy](https://github.com/RedHatInsights/insights-proxy)

Follow the setup instructions in [README.md](https://github.com/RedHatInsights/insights-proxy/blob/master/README.md#setup)


In the catalog-api repository the config directory contains a JavaScript file (spandx.config.js) which can be used with Insights Proxy to route the catalog requests to your dev machine

The Insights Proxy runs a docker container and it can be tailored using config files

You would need 2 terminals for this setup

1. **Running your catalog app**

_Includes the `RBAC_URL` and `APPROVAL_URL environment variables to be able to use RBAC_

_You can also remove the `RBAC_URL` environment variable and pass in the `BYPASS_RBAC` environment variable instead if you want to test without RBAC_

```
APP_NAME=catalog PATH_PREFIX=/api RBAC_URL=https://<url>/api/rbac/v1/ APPROVAL_URL=https://<url>/api/approval/v1/ TOPOLOGICAL_INVENTORY_URL=https://<url>/api/topological-inventory/v1/ SOURCES_URL=https://<url>/api/sources/v1/ DEV_USERNAME=<username> DEV_PASSWORD=<password> bin/rails s -p 5000
```

2. **Run the insights proxy based on Linux or Mac**
```
SPANDX_CONFIG=/path/to/catalog-api/config/spandx.config.js bash /path/to/insights-proxy/scripts/run.sh
```

3. **Login to the Dev cluster to access the UI**

   Using this URL which connects to the insights proxy running in the docker container
   https://ci.foo.redhat.com:1337/ansible/catalog


## Order Debugging
### Rake command

**rake order:list**

List Orders and asscoiated objects (order_items and progress messages)

Optional parameters:

```
- LIMIT  - Orders listed in reverse order.  (Default = 1)
- TENANT - External Tenant Reference.
- OWNER  - (Owner name
- ID(S)  - Comma separated list of Order ID(s)
  (Note: ID list overrides limit field.)
```

Examples:

```
rake order:list TENANT=12345
rake order:list OWNER=testuser
rake order:list IDS=1,2,3
rake order:list TENANT=12345 OWNER=testuser LIMIT=10
```

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
