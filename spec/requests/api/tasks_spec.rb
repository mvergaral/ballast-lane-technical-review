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
        post "/api/tasks",
             params: { task: valid_attributes },
             headers: { 'Accept' => 'application/json' },
             as: :json
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Test Task')
        expect(json_response['user_id']).to eq(user.id)
        expect(Task.count).to eq(1)
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity status" do
        post "/api/tasks",
             params: { task: { title: "" } },
             headers: { 'Accept' => 'application/json' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
  end
end
