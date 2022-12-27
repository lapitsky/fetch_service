Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :user, only: [] do
    resources :transactions, only: [:index, :create]
    resources :spends, only: [:create] do
      collection do
        get :balances
      end
    end
  end
end
