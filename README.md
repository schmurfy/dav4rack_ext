
# Continuous integration ([![Build Status](https://secure.travis-ci.org/schmurfy/dav4rack_ext.png)](http://travis-ci.org/schmurfy/dav4rack_ext))

This gem is tested against these ruby by travis-ci.org:

- mri 1.9.3
- mri 2.0.0

# What is this gem ?
This gem extends dav4rack to provide a CardDAV extension, CalDAV is not currently available but will eventually be available too.


# Usage

Have a look at the examle folder, this is a standard Rack application and should run with any compliant server.

You can run the example with thin like this:

```bash
$ cd example
$ bundle exec thin start
```

Once the server is started you can connect to it using http://127.0.0.1:3000/u/cards with any login/password
(the example has no authentication set up)

# Supported clients
- Mac OS X: recently tested on 10.11 (El Capitan)
- iOS: recently tested on 8 and 9

# Setting up development environment

```bash
# clone the repository and:
$ bundle
$ bundle exec guard
```

the tests will run when a file changed, if only want to run all tests once:

```bash
$ bundle exec rake
```
