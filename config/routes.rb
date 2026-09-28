Rails.application.routes.draw do
  root to: redirect("/admin")

  namespace :admin do
    root "dashboard#show"
    resource :session, only: %i[new create destroy]
    resources :services
    resources :staff_members
    resources :service_offerings
    resources :availabilities
    resources :customers
    resources :appointments, except: :destroy do
      member do
        patch :cancel
        patch :complete
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resource :registration, only: :create
      resource :session, only: %i[create destroy]
      resource :profile, only: %i[show update]
      resources :services, only: %i[index show] do
        resources :staff_members, only: :index, module: :services
      end
      resources :service_offerings, only: [] do
        get :available_slots, on: :member
      end
      resources :appointments, only: %i[index show create] do
        patch :cancel, on: :member
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
