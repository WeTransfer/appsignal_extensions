# appsignal_extensions

When you want to do something more to Appsignal than the gem provides out of the box.

## The Rack middleware

The gem provides a customized Appsignal middleware, which makes a number of extra things
possible. Simplest use is just like the standard Rack listener in Appsignal:

    use AppsignalExtensions::Middleware

Just make sure Appsignal is configured and started at some point in the code. That means
that for information to come in `Appsignal.active?` should be true.

The transaction is going to be kept open as long as the iteraion over the Rack body
object continues. Therefore, you can use this middleware for long-polling too (long bodies
which `yield` chunked content and so on).

If you need more specific long response support, you can output a special header with your
response called 'appsignal.suspend'. If you set that header to a truthy value, the transaction
is not going to be closed for you. You can then close the transaction with your Thin `errback`
proc or similar, or close it explicitly in the `close` handler of your response body.

The transaction is also going to be placed in the `appsignal.transaction` Rack env variable,
and you can do things to the transaction manually. For instance:
  
    ->(env) {
      env['appsignal.transaction'].set_action('MyHandler#perform')
      ...
    }

If Appsignal is not enabled or not configured, the middleware is going to supply you with a
special `NullTransaction` object instead which responds to all the same methods as a real
`Appsignal::Transaction`, so that you can avoid redundant nil checks.

## Contributing to appsignal_extensions
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2016 WeTransfer. See LICENSE.txt for further details.
