require 'spec_helper'

describe Notifiable::Gcm::Spacialdb::Batch do
  
  let(:a) { Notifiable::App.create }  
  let(:n1) { Notifiable::Notification.create(:app => a) }
  let!(:ln) { Notifiable::LocalizedNotification.create(:message => "Test message", :params => {:flag => true}, :notification => n1, :locale => 'en') }
  let(:d) { Notifiable::DeviceToken.create(:token => "ABC123", :provider => :gcm, :app => a, :locale => 'en') }
  
  before(:each) do
    a.gcm_api_key = "abc123"
  end
  
  it "sends a single gcm notification" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}')   
    
    n1.batch {|n| n.add_device_token(d)}
        
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 0
  end
  
  it "sends custom attributes" do        
      stub_request(:post, "https://android.googleapis.com/gcm/send")
               .with(:body => "{\"registration_ids\":[\"ABC123\"],\"data\":{\"message\":\"Test message\",\"flag\":true,\"localized_notification_id\":1}}")
               .to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}') 
    
    n1.batch {|n| n.add_device_token(d)}
   
   
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 0
  end
  
  it "marks a unregistered token as invalid" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "NotRegistered" }]}')  
        
    n1.batch {|n| n.add_device_token(d)}
        
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 4
    d.is_valid.should == false
  end 
  
  it "marks an invalid token as invalid" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "InvalidRegistration" }]}')  
        
    n1.batch {|n| n.add_device_token(d)}
        
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 2
    d.is_valid.should == false
  end 
  
  it "updates a token to the canonical ID if it does not exist" do   
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 1, "results": [{ "message_id": "1:08", "registration_id": "GHJ12345" }]}')  
        
    n1.batch {|n| n.add_device_token(d)}
        
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 0
    Notifiable::DeviceToken.count.should == 1
    d.token.should eql "GHJ12345"
  end 
  
  
#  it "marks a token as invalid if the canonical ID already exists" do  
#    Notifiable::DeviceToken.create(:token => "GHJ12345", :provider => :gcm)
     
#    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 1, "results": [{ "message_id": "1:08", "registration_id": "GHJ12345" }]}')  
        
#    n1.batch do |n|
#      n.add_device_token(d)
#    end
        
#    Notifiable::NotificationStatus.count.should == 1
#    Notifiable::NotificationStatus.first.status = 0
#    Notifiable::DeviceToken.count.should == 2
#    d.is_valid.should be_false
#  end 
  
  it "deals gracefully with an unauthenticated key" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '<html>Message</html>', :status => 401)  
        
    n1.batch {|n| n.add_device_token(d)}

    Notifiable::NotificationStatus.count.should == 0
  end 
  
end