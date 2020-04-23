Rails.application.routes.draw do
  post "/signup", to: "users#signup"
  post "/login", to: "users#login"
  post "/logout", to: "users#logout"
  get "/autologin", to: "users#autologin"
end
