
1.0.0 / 2016-02-09
==================

[Changed]
 * upgrade `aws-sdk` to 2.x.x and restrict its dependency version

[Added]
 * add `cookies` to payload

[Fixed]
 * `rewind` body before read in payload


0.0.4 / 2014-09-23
==================
 * add `controller_action` to payload, if `env['action_dispatch.request.parameter']` exists

0.0.3 / 2014-09-04
==================

 * accomondate the case when `Rack::Request#body` not readable, fallback to env['RAW_POST_BODY'] if any
