require 'spec_helper'

describe Notifiable::Gcm::Spacialdb::Batch do
  
  let(:app_configuration) { {save_notification_statuses: true, gcm: {api_key: 'abc123'}} }
  let(:a) { Notifiable::App.create gcm_api_key: 'abc123', configuration: app_configuration }  
  let(:n1) { Notifiable::Notification.create(app: a, message: 'Test message', parameters: {flag: true} ) }
  let(:d) { Notifiable::DeviceToken.create(:token => "ABC123", :provider => :gcm, :app => a, :locale => 'en') }
  let!(:stubbed_request) { stub_request(:post, "https://gcm-http.googleapis.com/gcm/send").with(body: request_body).to_return(body: response_body) }
  let(:request_body) { }
  let(:response_body) { }
  
  describe '#batch' do
    before(:each) { n1.batch {|n| n.add_device_token(d)} }
    
    context 'single' do
      let(:n1) { Notifiable::Notification.create(app: a, title: 'Test title', message: 'Test message', parameters: {flag: true} ) }      
      let(:request_body) { "{\"registration_ids\":[\"ABC123\"],\"data\":{\"message\":\"Test message\",\"title\":\"Test title\",\"flag\":true,\"n_id\":#{n1.id}}}" }
      let(:response_body) { '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}' }
      it { expect(Notifiable::NotificationStatus.count).to eq 1 }
      it { expect(Notifiable::NotificationStatus.first.status).to eq 0 }
    end
    
    context 'custom attributes' do
      let(:request_body) { "{\"registration_ids\":[\"ABC123\"],\"data\":{\"message\":\"Test message\",\"flag\":true,\"n_id\":#{n1.id}}}" }
      let(:response_body) { '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}' }
      it { expect(Notifiable::NotificationStatus.count).to eq 1 }
      it { expect(Notifiable::NotificationStatus.first.status).to eq 0 }
    end
    
    context 'deletes an unregistered token' do
      let(:request_body) { "{\"registration_ids\":[\"ABC123\"],\"data\":{\"message\":\"Test message\",\"flag\":true,\"n_id\":#{n1.id}}}" }
      let(:response_body) { '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "NotRegistered" }]}' }
      it { expect(Notifiable::NotificationStatus.count).to eq 1 }
      it { expect(Notifiable::DeviceToken.count).to eq 0 }
    end
    
    context 'id change' do
      let(:request_body) { "{\"registration_ids\":[\"ABC123\"],\"data\":{\"message\":\"Test message\",\"flag\":true,\"n_id\":#{n1.id}}}" }
      let(:response_body) { '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 1, "results": [{ "message_id": "1:08", "registration_id": "GHJ12345" }]}' }
      it { expect(Notifiable::NotificationStatus.count).to eq 1 }
      it { expect(Notifiable::DeviceToken.count).to eq 1 }
      it { expect(Notifiable::DeviceToken.first.token).to eq "GHJ12345" }
    end
    
    context 'bad key' do
      let!(:stubbed_request) { stub_request(:post, "https://gcm-http.googleapis.com/gcm/send").to_return(body: '<html>Message</html>', status: 401) }
      it { expect(Notifiable::NotificationStatus.count).to eq 0 }
    end
    
  end
end