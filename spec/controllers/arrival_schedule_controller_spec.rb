require "rails_helper"

RSpec.describe ArrivalScheduleController, :type => :controller do
  describe "Authenticated user" do
    let (:user) {FactoryGirl.create(:user)}

    before do
      sign_in :user, user
    end

    describe "Get #index" do
      it "responds with success" do
        get :index

        expect(response).to have_http_status(200)
      end
    end

    describe "Get check_location_check" do
      it "responds with success" do
        get :check_location_test

        expect(response).to have_http_status(200)
      end
    end

    describe "Get locations" do
      it "returns locations for user" do
        FactoryGirl.create_list(:arrival_schedule, 3, user_id: user.id)
        other_user = FactoryGirl.create(:user, email: 'otherpomuser@example.com')
        FactoryGirl.create(:arrival_schedule, user_id: other_user.id)
        get :locations

        result = JSON.parse(response.body)
        expect(result.length).to be(3)
        expect(response).to have_http_status(200)
      end
    end

    describe "Remove location" do
      describe "with no saved locations" do
        it "returns unsuccessful status" do
          post :remove_schedule

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end
      end

      describe "with saved locations" do
        it "returns unsuccessful status when id doesn't match" do
          a = FactoryGirl.create(:arrival_schedule, user_id: user.id)
          post :remove_schedule, {id: a.id + 1}

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end

        it "returns unsuccessful status when id doesn't match one for user" do
          other_user = FactoryGirl.create(:user, email: 'otherpomuser@example.com')
          a = FactoryGirl.create(:arrival_schedule, user_id: other_user.id)

          expect(ArrivalSchedule.first.id).to eq(a.id)

          post :remove_schedule, {id: a.id}

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
          expect(ArrivalSchedule.first.id).to eq(a.id)
        end

        it "returns successful status when id does match" do
          a = FactoryGirl.create(:arrival_schedule, user_id: user.id)

          expect(ArrivalSchedule.first.id).to eq(a.id)

          post :remove_schedule, {id: a.id}

          expect(JSON.parse(response.body)['result']).to be(true)
          expect(response).to have_http_status(200)
          expect(ArrivalSchedule.count).to eq(0)
        end
      end
    end

    describe "Create location" do
      describe "Unsuccessful save" do
        it "returns unsuccessful status with invalid params" do
          expect{ post(:schedule, {}) }.to raise_error ActionController::ParameterMissing
        end

        it "returns unsuccessful status when new location matches saved name" do
          params = {
            arrival_schedule: {
              name: 'My Location',
              longitude: 0,
              latitude: 0,
              range: 50,
              active: true,
              recipients: [
                email_address: 'pomtest@example.com',
                notification_method: 'email'
              ]
            }
          }
          FactoryGirl.create(:arrival_schedule, user_id: user.id)
          post :schedule, params

          expect(JSON.parse(response.body)['result']).to be(false)
          expect(response).to have_http_status(200)
        end
      end

      describe "Successful save" do
        before do
          @params = {
            arrival_schedule: {
              name: 'Test Location',
              longitude: 0,
              latitude: 0,
              range: 50,
              active: true,
              recipients: [
                email_address: 'pomtest@example.com',
                notification_method: 'email'
              ]
            }
          }
        end

        it "returns successful status when new location does not match saved name" do
          FactoryGirl.create(:arrival_schedule, user_id: user.id)
          post :schedule, @params

          result = JSON.parse(response.body)
          expect(result['name']).to eq('Test Location')
          expect(JSON.parse(response.body)['result']).to be(true)
          expect(response).to have_http_status(200)
        end

        it "enforces range's upper bound" do
          @params[:arrival_schedule][:range] = 5000
          post :schedule, @params

          result = JSON.parse(response.body)
          expect(result['result']).to be(true)
          expect(result['range']).to eq(1000)
          expect(response).to have_http_status(200)
        end

        it "enforces range's lower bound" do
          @params[:arrival_schedule][:range] = 5
          post :schedule, @params

          result = JSON.parse(response.body)
          expect(result['result']).to be(true)
          expect(result['name']).to eq('Test Location')
          expect(result['range']).to eq(50)
          expect(response).to have_http_status(200)
        end
      end
    end

    describe "Check location" do
      let (:arrival_schedule) {FactoryGirl.create(:arrival_schedule, user_id: user.id)}

      before do
        FactoryGirl.create(:arrival_recipient, arrival_schedule_id: arrival_schedule.id)
      end

      describe "Invalid params" do
        it "returns no matches" do
          post :check_location

          expect(JSON.parse(response.body).length).to be(0)
          expect(response).to have_http_status(200)
        end
      end

      describe "Valid params" do
        it "returns no matches when none in range" do
          post :check_location, { longitude: 10, latitude: 20 }

          expect(JSON.parse(response.body).length).to be(0)
          expect(response).to have_http_status(200)
        end

        it "does not match inactive locations" do
          arrival_schedule.active = false

          post :check_location, { longitude: 50.000001, latitude: 50.000002 }

          expect(JSON.parse(response.body).length).to be(1)
          expect(response).to have_http_status(200)
        end

        it "returns a match when in range" do
          post :check_location, { longitude: 50.000001, latitude: 50.000002 }

          result = JSON.parse(response.body)
          expect(result.length).to be(1)
          expect(response).to have_http_status(200)
          expect(result.first["email_addresses"]).to eq(["pomrecipient@example.com"])
          expect(result.first["method"]).to eq("pomrecipient@example.com")
        end

        it "returns a match when in range, with multiple recipients" do
          FactoryGirl.create(:arrival_recipient, arrival_schedule_id: arrival_schedule.id, email_address: 'test@example.com')
          post :check_location, { longitude: 50.000001, latitude: 50.000002 }

          result = JSON.parse(response.body)
          expect(result.length).to be(1)
          expect(response).to have_http_status(200)
          expect(result.first["email_addresses"]).to eq(["pomrecipient@example.com", "test@example.com"])
          expect(result.first["method"]).to eq("pomrecipient@example.com, test@example.com")
        end
      end
    end
  end
end
