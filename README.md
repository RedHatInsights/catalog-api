# Catalog API

[![Build Status](https://api.travis-ci.org/ManageIQ/catalog-api.svg)](https://travis-ci.org/ManageIQ/catalog-api)
[![Maintainability](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/maintainability)](https://codeclimate.com/github/ManageIQ/catalog-api/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/test_coverage)](https://codeclimate.com/github/ManageIQ/catalog-api/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/catalog-api/master.svg)](https://hakiri.io/github/ManageIQ/catalog-api/master)

## Swagger for Rails 5

This is a project to provide Swagger support inside the [Ruby on Rails](http://rubyonrails.org/) framework.

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

This sample was generated with the [swagger-codegen](https://github.com/swagger-api/swagger-codegen) project.

```
bin/rake db:create db:migrate
bin/rails s
```

## Viewable API url

https://domain-or-ip-running-the-catalog-api.test/api

The `swagger-2.yaml` file is located at `public/doc` which
is rendered by the `/api` endpoint.


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

## swagger-codegen example

Definitions of the flags used in the below example

1. -l type of generator to use
2. -i input file
3. -o output directory
4. -t templates location ( directories only )

```
swagger-codegen generate -l rails5 -i public/doc/swagger-2.yaml -o /tmp/sp -t swagger-codegen-templates/'
```

## Testing with Dev Insights UI

If you want to run the catalog locally on your dev machine but access the UI on the dev cluster you would need to do the following

Install Docker in your machine

Clone the following repo to your dev machine

[Insights Proxy](https://github.com/RedHatInsights/insights-proxy)

Follow the setup instructions in [README.md](https://github.com/RedHatInsights/insights-proxy/blob/master/README.md#setup)


In the catalog-api repository the config/spandx directory contains 2 JavaScript files which can be used with Insights Proxy to route the catalog requests to your dev machine

1. linux.js

2. mac.js

The Insights Proxy runs a docker container and it can be tailored using config files

You would need 2 terminals for this setup

1. **Running your catalog app**

      export APP_NAME=catalog
      
      export PATH_PREFIX=/api
      
      bin/rails s -p 5000
      
2. **Run the insights proxy based on Linux or Mac**
```
   SPANDX_CONFIG=/path/to/catalog-api/config/spandx/mac.js bash /path/to/insights-proxy/scripts/run.sh
```
   
3. **Login to the Dev cluster to access the UI**

   Using this URL which connects to the insights proxy running in the docker container
   https://ci.foo.redhat.com:1337/insights/platform/catalog/portfolios


## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
