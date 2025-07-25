# Task Resource Scaffold

## Prompt

```plain
<system>
You are a senior Ruby on Rails engineer known for concise, idiomatic contributions.
</system>

<user>
### Context
You are working inside an existing Rails  API‑only project that already has:
• A User model, JWT authentication, Pundit set‑up, RSpec, and Postgres.  
Everything else is fully functional.  
Your task is **only** to scaffold the *Task* resource.

### Requirements
1. **Model & DB**
   • `Task` belongs_to User.  
   • Columns: title:string, description:text, status:integer (enum: pending | in_progress | done, default :pending), due_date:date, timestamps.  
2. **Validations**
   • Presence: title, status, due_date.  
   • title, description.  
   • due_date ≥ today.
3. **Routes & Controller**
   • resources :tasks (JSON only).  
   • Actions: index, show, create, update, destroy.  
   • Scope index to current_user.tasks (assume already defined in user model).  
   • Strong params; authorize with TaskPolicy (assume base Pundit helpers).
4. **Testing**
   • Provide a single RSpec request spec demonstrating happy path for create & index.
5. **Output format**
   • Emit everything as **one Markdown file called CODE.md**.  
   • Organise with headings and fenced code blocks labelled by filename, in this order:  
     1. db/migrate/xxxx_create_tasks.rb  
     2. app/models/task.rb  
     3. app/policies/task_policy.rb  
     4. config/routes.rb  
     5. app/controllers/api/tasks_controller.rb  
     6. spec/requests/tasks_spec.rb  
   • Do **not** include any explanations outside the code blocks.
</user>
```


## db/migrate/20250725104517_create_tasks.rb

```ruby
class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.date :due_date, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
```

## app/models/task.rb

```ruby
class Task < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, in_progress: 1, done: 2 }, default: :pending

  validates :title, presence: true
  validates :status, presence: true
  validates :due_date, presence: true
  validate :due_date_cannot_be_in_the_past

  private

  def due_date_cannot_be_in_the_past
    if due_date.present? && due_date < Date.current
      errors.add(:due_date, "can't be in the past")
    end
  end
end
```

## app/policies/task_policy.rb

```ruby
class TaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.user == user
  end

  def create?
    true
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
```

## config/routes.rb

```ruby
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

    resources :tasks

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
```

## app/controllers/api/tasks_controller.rb

```ruby
class Api::TasksController < Api::ApplicationController
  before_action :set_task, only: [:show, :update, :destroy]

  def index
    @tasks = current_user.tasks
    authorize @tasks

    render json: @tasks
  end

  def show
    authorize @task
    render json: @task
  end

  def create
    @task = current_user.tasks.build(task_params)
    authorize @task

    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @task

    if @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    @task.destroy
    head :no_content
  end

  private

  def set_task
    @task = current_user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :due_date)
  end
end
```

## spec/requests/api/tasks_spec.rb

```ruby
require 'rails_helper'

RSpec.describe "Api::Tasks", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:valid_attributes) do
    {
      title: "Test Task",
      description: "This is a test task",
      status: "pending",
      due_date: Date.current + 1.week
    }
  end

  before do
    sign_in user
  end

  describe "GET /api/tasks" do
    let!(:user_task) { create(:task, user: user) }
    let!(:other_task) { create(:task, user: other_user) }

    it "returns only current user's tasks" do
      get "/api/tasks", headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(user_task.id)
    end
  end

  describe "POST /api/tasks" do
    context "with valid parameters" do
      it "creates a new task" do
        expect {
          post "/api/tasks", 
               params: { task: valid_attributes }, 
               headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Test Task')
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity status" do
        post "/api/tasks",
             params: { task: { title: "" } },
             headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
  end
end
```

## Prompt Summary and Manual Fixes

The following prompt was written according to Claude 4 best practices. The output was mostly correct and functional. Only minor manual adjustments were needed in the specs:

### 1. Task creation test (`spec/requests/api/tasks_spec.rb:40`)

**Issue:**  
The test was sending improperly structured JSON parameters, triggering an `ActionDispatch::Http::Parameters::ParseError`.

**Fix:**  
- Replaced manual `Content-Type` header configuration with `as: :json` helper in RSpec.  
- Ensured parameters followed the expected structure: `{ task: valid_attributes }`.  
- Removed manually set headers and relied on `as: :json` to format the request properly.

---

### 2. Task validation error test (`spec/requests/api/tasks_spec.rb:55`)

**Issue:**  
- The test expected a `:unprocessable_entity` (422) status but received `:bad_request` (400) due to malformed JSON.  
- It was asserting on a `details` key that did not exist; the controller returns errors under `errors`.

**Fix:**
- Corrected the parameter structure (same issue as above).
- Updated the expectation to use `json_response['errors']` instead of `json_response['details']` to match the actual response format.

you can see the fixed test in the `spec/requests/api/tasks_spec.rb` file.
