POM Web Server
============================

## Getting Started

### Setup

Note: Examples below are for Mac OS X.

Install the following packages:

* postgresql

For example:

```bash
$ brew install postgresql
```
In the root project directory, install Ruby and required gems:

```bash
$ gem install bundler
$ bundle
```

Setup Postgres user and databases:

Note: You may need to modify the `pg_hba.conf` configuration file to `trust` all
local connections.

Note: Ensure that the locale is `en_US.UTF-8` in the `postgresql.conf` configuration
file.

Run any migrations: `$ rake db:migrate`

Ensure that the following variables are set in your `./.env` file:

_none at this time_

and launch server with:

```bash
$ foreman start web
```

### Running Tests

Launch tests with:

```bash
$ rspec spec
```
