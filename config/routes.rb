Labrador::Application.routes.draw do

  root to: 'pages#home'

  get '401', to: 'pages#unauthorized', as: 'unauthorized'
  get 'error', to: 'pages#error', as: 'error'
  
  scope "data" do
    ['mongodb', 'postgresql', 'mysql', 'mysql2', 'sqlite', 'sqlite2', 'sqlite3', 'mssql'].each do |adapter|
      resources adapter, controller: 'data', adapter: adapter do
        collection do
          get :collections, action: 'collections'
          get :schema, action: 'schema'
          get :command, action: 'command'
        end
      end
    end 
  end

  resources :sessions
  get '/*path', to: 'pages#home'
end
