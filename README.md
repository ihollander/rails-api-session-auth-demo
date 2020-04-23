# API Auth with Cookies

Finished code for this project is in `session-auth-api` (Rails) and `session-auth-client` (React).

To get up and running, from `session-auth-api`, run:

```sh
$ bundle
$ rails db:migrate
$ rails s
```

And from `session-auth-client`:

```sh
$ npm install
$ npm start
```

## Rails

Let's get the backend setup done first. We'll need to configure a couple of things, since the default configuration for Rails with the `--api` flag doesn't enable cookies or sessions.

First, we need to add in middleware for cookies and sessions in our config:

```rb
  # in config/application.rb
module SessionAuthApi
  class Application < Rails::Application
    # keep all the default configuration, which should look like this:
    config.load_defaults 6.0
    config.api_only = true

    # add this at the end
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
  end
end

```

We'll also have to setup your controllers to send cookies, this can be done by updating our ApplicationController:

```rb
class ApplicationController < ActionController::API
  include ActionController::Cookies
end
```

Lastly, we still need to setup CORS. First we'll need to uncomment the `rack-cors` gem in our Gemfile. Then in our `config/initializers/cors.rb` file, we can't use wildcard - we need to specify the origins we're allowing.We also need to include `credentials: true` here:

```rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # origins '*' won't work!
    origins 'localhost:3001'

    resource '*',
      headers: :any,
      credentials: true,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

With that configuration done, let's make a model and a few resources to test our session auth.

First, we need to uncomment the `bcrypt` gem in our Gemfile.

We'll also use `active_model_serializers`:

```sh
$ bundle add active_model_serializers
```

Then, we'll create a User model:

```sh
$ rails g resource User username password_digest
```

Let's make sure our User class is set up to use BCrypt and has some validations:


```rb
class User < ApplicationRecord
  has_secure_password

  validates :username, presence: true, uniqueness: true
end
```

Let's also configure the serializer so it only sends the username:

```rb
class UserSerializer < ActiveModel::Serializer
  attributes :username
end
```

Then let's configure some routes for authentication:

```rb
# config/routes.rb
Rails.application.routes.draw do
  post "/signup", to: "users#signup"
  post "/login", to: "users#login"
  post "/logout", to: "users#logout"
  get "/autologin", to: "users#autologin"
end
```

Now for some controller setup. First, let's setup our ApplicationController to handle some authorization logic:

```rb
class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  before_action :authorized
  
  private 
  
  def current_user
    if session[:user_id]
      @user = User.find_by(id: session[:user_id])
    end
  end
  
  def logged_in?
    !!current_user
  end
  
  def authorized
    render json: { message: 'Please log in' }, status: :unauthorized unless logged_in?
  end
  
end
```

Then let's set up our UsersController to enable our login/logout actions: 

```rb
class UsersController < ApplicationController
  skip_before_action :authorized, only: [:login, :signup, :autologin]

  def login
    user = User.find_by(username: params[:username])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      render json: user
    else
      render json: { errors: "Invalid username or password" }, status: :bad_request
    end
  end

  def signup
    user = User.create(username: params[:username], password: params[:password])

    if user.valid?
      session[:user_id] = user.id
      render json: user
    else
      render json: { errors: user.errors.full_messages }, status: :bad_request
    end
  end

  def autologin
    if @user
      render json: @user
    else
      render json: { message: "Please sign in!" }
    end
  end

  def logout
    session.delete(:user_id)

    render status: :ok
  end

end
```

## React

We're still going to be communicating between our frontend and backend using `fetch`, but now in addition to sending what we've typically been (headers, method, body), we also need to make fetch include our cookies as part of all requests. To do this, all we need to do is use the `credentials: "include"` option in our fetch request:

```js
fetch("http://localhost:3000/autologin/", {
  credentials: "include"
})
```

This will ensure that cookies are encluded as part of the `fetch` request for cross-origin requests - [MDN Request.credentials](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials). Since our frontend and backend are on separate origins, this option is necessary for all requests that need our session cookie.

Play around with the sample app and drop some `byebug`s in your backend when the fetches come through to get a sense of how the auth flow works! Pay close attention in particular to the actions in the ApplicationController.


## Resources

- [Rails API Auth with Session Cookies](https://pragmaticstudio.com/tutorials/rails-session-cookies-for-api-authentication)
  - this also shows how to enable CSRF protection for added security