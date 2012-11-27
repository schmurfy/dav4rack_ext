
# Continuous integration ([![Build Status](https://secure.travis-ci.org/schmurfy/dav4rack_ext.png)](http://travis-ci.org/schmurfy/dav4rack_ext))

This gem is tested against these ruby by travis-ci.org:

- mri 1.9.3

# What is this gem ?
This gem extends dav4rack to provide a CardDAV extension, CalDAV is not currently available but will eventually be available too.


# Usage

Have a look at the examle folder, this is a standard Rack application and should run with any compliant server.


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

