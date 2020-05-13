if ENV['RAILS_RELATIVE_URL_ROOT']
  Rails.application.routes.default_scope = ENV['RAILS_RELATIVE_URL_ROOT']
end

Rails.application.routes.draw do
  # ------------------------------------------------------------ Authentication
  # These routes allow users to set the shared password
  get  '/setup' => 'sessions#init'
  post '/setup' => 'sessions#setup'

  # Sign in / sign out
  get '/login'  => 'sessions#new'
  get '/logout' => 'sessions#destroy'
  resource :session

  # ------------------------------------------------------------ Project routes
  concern :multiple_destroy do
    collection do
      delete :multiple_destroy
    end
  end

  concern :revisable do
    resources :revisions, only: [:destroy, :index, :show]
  end

  resources :projects, only: [:show] do
    resources :activities, only: [] do
      collection do
        get :poll, constraints: { format: /js/ }
      end
    end

    resources :boards do
      resources :lists, except: [:index] do
        member { post :move }
        resources :cards, except: [:index], concerns: :revisable do
          member { post :move }
        end
      end
    end

    resources :comments

    constraints id: %r{[(0-z)\/]+} do
      resources :configurations, only: [:index, :update]
    end

    post :create_multiple_evidence, to: 'evidence#create_multiple'

    resources :issues, concerns: %i[multiple_destroy revisable] do
      collection do
        post :import
        resources :merge, only: [:new, :create], controller: 'issues/merge'
      end

      resources :nodes, only: [:show], controller: 'issues/nodes'
    end

    resources :methodologies do
      collection { post :preview }
      member do
        get :add
        put :update_task
      end
    end

    resources :nodes do
      collection do
        post :sort
        post :create_multiple
      end

      member do
        get :tree
      end

      resource :merge, only: [:create], controller: 'nodes/merge'

      resources :notes, concerns: %i[multiple_destroy revisable]

      resources :evidence, except: :index, concerns: %i[multiple_destroy revisable]

      constraints(filename: /.*/) do
        resources :attachments, param: :filename
      end
    end

    resources :notifications, only: [:index, :update]

    resources :revisions, only: [] do
      member { post :recover }
    end

    resources :subscriptions, only: [:create, :destroy]

    get 'search' => 'search#index'
    get 'trash' => 'revisions#trash'

    # ------------------------------------------------------- Export Manager
    get  '/export'                   => 'export#index',             as: :export_manager
    post '/export'                   => 'export#create'
    get  '/export/validate'          => 'export#validate',          as: :validate_export
    get  '/export/validation_status' => 'export#validation_status', as: :validation_status

    # ------------------------------------------------------- Upload Manager
    get  '/upload'        => 'upload#index',  as: :upload_manager
    post '/upload'        => 'upload#create'
    post '/upload/parse'  => 'upload#parse'

    if Rails.env.development?
      get '/styles'          => 'styles_tylium#index'
    end
  end

  resources :console, only: [] do
    collection { get :status }
  end

  # -------------------------------------------------------------- Static pages
  # jQuery Textile URLs
  resource :textile, controller: :textile, only: [] do
    get :field, as: :field
    post :form, as: :form
    get :'markup-help', as: :markup_help
    post :textilize, as: :textilize
    post :source, as: :source
  end

  root to: 'projects#index'

  mount ActionCable.server => '/cable'
end
