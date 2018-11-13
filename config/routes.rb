Apidae::Engine.routes.draw do

  resources :objects, only: [:index, :show], path: 'objets'
  resources :selections, only: [:index] do
    resources :objects, only: [:index], path: 'objets'
  end
  resources :references, only: [:index]
  resources :projects, only: [:index, :edit, :update], path: 'projets'

  match 'import/callback', via: :post, to: 'import#callback'
  match 'import/run', via: :post, to: 'import#run'

  root to: 'dashboard#index'
end
