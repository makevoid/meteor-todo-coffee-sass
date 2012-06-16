### Meteor todo example with coffeescript and sass

Install meteor:

    curl install.meteor.com | /bin/sh

Download/clone this repo and run:

    meteor


### develop:

sass npm package seem to not integrate well with meteor yet
see this issue: <https://github.com/meteor/meteor/issues/143>

meanwhile I solved the sass problem with sass ruby gem

    gem i sass

to install it, then run the watcher with:

    ./watch_sass


### changes:

- converted js to coffee and css to sass
- added ruby sass watch script