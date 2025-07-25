Rails.application.routes.draw do
  devise_for :users, skip: [:sessions, :registrations, :passwords, :confirmations, :unlocks]
  
  # API routes - only respond to JSON
  namespace :api, defaults: { format: :json } do
    post "auth/login"
    post "auth/register"
    delete "auth/logout"
    get "health/index"
    get "dashboard", to: "dashboard#index"
    
    resources :users, only: [:index, :show, :create]
    
    resources :books do
      collection do
        get :search
        get 'search/suggestions', action: :search_suggestions
        get 'search/advanced', action: :advanced_search
      end
    end
    
    resources :borrowings do
      member do
        post :return_book
      end
    end
  end

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Catch all other routes and return 404
  root to: proc { [404, {}, ["Not Found"]] }
  get "*path", to: proc { [404, {}, ["Not Found"]] }
end
