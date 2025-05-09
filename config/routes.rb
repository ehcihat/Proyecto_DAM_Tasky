Rails.application.routes.draw do
  get "pages/home"
  get "page/controller"
    root to: "pages#home"
    post "/register", to: "users#create"
    post "/login", to: "sessions#create"
    post '/logout', to: 'sessions#destroy'
    get "/profile", to: "users#profile"
    get "/current_user", to: "current_user#show"
    resources :projects do 
        resources :lists, only: [:index, :create, :destroy, :update] do
          resources :tasks, only: [:index, :create, :destroy, :update]
        end
    end
end