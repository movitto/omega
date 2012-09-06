## Public Omega JSON-RPC API:

### cosmos:

* cosmos::get\_entity              |*args|
* cosmos::get\_resource\_sources    |entity\_id|

### manufactured:

* manufactured::construct\_entity  |manufacturer\_id, entity\_type, *args|
* manufactured::get\_entity        |id|
* manufactured::subscribe\_to      |entity\_id, event|
* manufactured::remove\_callbacks  |entity\_id|
* manufactured::move\_entity       |id, new\_location|
* manufactured::follow\_entity     |id, target\_id, distance|
* manufactured::attack\_entity     |attacker\_entity\_id, defender\_entity\_id|
* manufactured::dock              |ship\_id, station\_id|
* manufactured::undock            |ship\_id|
* manufactured::start\_mining      |ship\_id, resource\_source\_id|
* manufactured::transfer\_resource |from\_entity\_id, to\_entity\_id, resource\_id, quantity|

### motel:

* motel::get\_location             |*args|
* motel::track\_movement           |location\_id, min\_distance|
* motel::track\_proximity          |location1\_id, location2\_id, event, max\_distance|
* motel::remove\_callbacks         |*args|

### users:

* users::get\_entity               |*args|
* users::send\_message             |user\_id, message|
* users::subscribe\_to\_messages    |user\_id|
* users::login                    |user|
* users::logout                   |session\_id|
* users::register                 |user|
* users::confirm\_register         |registration\_code|
* users::update\_user              |user|


## Private Omega JSON-RPC API:

### cosmos:

* cosmos::create\_entity           |entity, parent\_name|
* cosmos::set\_resource            |entity\_id, resource, quantity|
* cosmos::save\_state              |output|
* cosmos::restore\_state           |input|

### manufactured:

* manufactured::create\_entity     |entity|
* manufactured::save\_state        |output|
* manufactured::restore\_state     |input|

### motel:

* motel::create\_location          |*args|
* motel::update\_location          |location|
* motel::save\_state               |output|
* motel::restore\_state            |input|

### users:

* users::create\_entity            |entity|
* users::add\_privilege            |*args|
* users::save\_state               |output|
* users::restore\_state            |input|
