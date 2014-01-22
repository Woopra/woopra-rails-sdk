Track customers directly in the Ruby on Rails Web Framework using Woopra's Rails SDK

The purpose of this SDK is to allow our customers who have servers running the Ruby On Rails Framework to track their users by writing only Ruby code. Tracking directly in Rails will allow you to decide whether you want to track your users:
- through the front-end: after configuring the tracker, identifying the user, and tracking page views and events in Ruby, the SDK will generate the corresponding JavaScript code, and by passing this code to your view (examples will be shown below), you will be able to print that code in your view's header.
- through the back-end: after configuring the tracker & identifying the user, add the optional parameter true to the methods <code>track</code> or <code>push</code>, and the Rails tracker will handle sending the data to Woopra by making HTTP Requests. By doing that, the client is never involved in the tracking process.

The first step is to add the woopra_tracker gem to your Gemfile:
``` ruby
gem 'woopra_tracker', '1.0'
```

You can then configure the tracker SDK in your controller. For example, if you want to set up tracking with Woopra on your homepage, the controller should look like:
``` ruby
# import the SDK
require_relative '../../lib/woopra-rails-sdk/woopra_tracker'
include WoopraRailsSDK

class StaticPagesController < ApplicationController
   def home
      woopra = WoopraTracker.new(request)
      woopra.config({domain: "mybusiness.com"})

      # Your code here...

```
You can also customize all the properties of the woopra during that step by adding them to the config_hash. For example, to also update your idle timeout (default: 30 seconds):
``` ruby
# instead of:
woopra.config({domain: 'mybusiness.com'})
# directly write:
woopra.config({
   domain: 'mybusiness.com', 
   idle_timeout: 15000
})
```
To add custom visitor properties, you should use the identify(user_hash) function:
``` ruby
woopra.identify({
   email: 'johndoe@mybusiness.com',
   name: 'John Doe',
   company: 'My Business'
})
```
If you wish to identify a user without any tracking event, don't forget to push() the update to Woopra:
``` ruby
woopra.identify(user).push()
# or, to push through back-end:
woopra.identify(user).push(true)
```
If you wish to track page views, just call track():
``` ruby
woopra.track()
# Or, for back-end tracking:
woopra.track(true)
```
You can also track custom events through the front-end or the back-end. With all the previous steps done at once, your controller should look like:
``` ruby
include WoopraRailsSDK

class StaticPagesController < ApplicationController
   def home
      woopra = WoopraTracker.new(request)
      woopra.config(config_dict).identify(user_dict).track()
      # Track a custom event through the front end...
      woopra.track("play", {
         artist: 'Dave Brubeck',
         song: 'Take Five',
         genre: 'Jazz'
      })
      # ... and through the back end by passing the optional param True
      woopra.track("signup", {
         company: 'My Business',
         username: 'johndoe',
         plan: 'Gold'
      }, true)

      # Your code here...
      
      # When you're done setting up your WoopraTracker object, send a variable containing the value of
      # woopra.js_code() among all the other variables you are passing to the template.
      @woopra_code = woopra.js_code

```
and add the code in your template's header (here <code>home.html.erb</code>)
``` erb
<!DOCTYPE html>
<html>
   <head>
      <!-- Your header here... -->
      <%= @woopra_code %>
   </head>
   <body>
      <!-- Your body here... -->

   </body>
</html>
```
Finally, if you wish to track your users only through the back-end, you should set the cookie on your user's browser. However, if you are planning to also use front-end tracking, don't even bother with that step, the JavaScript tracker will handle it for you.
``` ruby
...
woopra.set_woopra_cookie(cookies)
```
