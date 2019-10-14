Apidae::Engine.routes.draw do

  resources :objects, only: [:index, :show, :new, :create], path: 'objets' do
    post 'refresh', on: :member
  end

  resources :selections, only: [:index] do
    resources :objects, only: [:index], path: 'objets' do
      post 'refresh', on: :member
    end
  end
  resources :references, only: [:index]
  resources :projects, only: [:index, :new, :create, :edit, :update, :destroy], path: 'projets'

  match 'import/callback', via: :post, to: 'import#callback'
  match 'import/run', via: :post, to: 'import#run'

  root to: 'dashboard#index'
end
