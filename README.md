# Insights Service Portal API

[![Build Status](https://api.travis-ci.org/ManageIQ/insights-api-service_portal.svg)](https://travis-ci.org/ManageIQ/insights-api-service_portal)
[![Maintainability](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/maintainability)](https://codeclimate.com/github/ManageIQ/service_portal-api/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a9e6e5c7feb376381c5f/test_coverage)](https://codeclimate.com/github/ManageIQ/service_portal-api/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/service_portal-api/master.svg)](https://hakiri.io/github/ManageIQ/service_portal-api/master)

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
export SERVICE_CATALOG_DATABASE_USERNAME=<<database_user>>
export SERVICE_CATALOG_DATABASE_PASSSWORD=<<database_password>>
or
export DATABASE_URL=postgres://pguser:pgpass@localhost/somedatabase
export MANAGEIQ_USER=admin
export MANAGEIQ_PASSWORD=smartvm
export MANAGEIQ_HOST=localhost
export MANAGEIQ_PORT=3000
```

This sample was generated with the [swagger-codegen](https://github.com/swagger-api/swagger-codegen) project.

```
bin/rake db:create db:migrate
bin/rails s
```

## Viewable API url

https://domain-or-ip-running-the-service-portal-api.test/api

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

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
