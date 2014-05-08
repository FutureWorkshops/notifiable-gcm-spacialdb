require 'spec_helper'

describe Notifiable::Gcm::Spacialdb::Batch do
  
  let(:a) { Notifiable::App.create }  
  let(:n1) { Notifiable::Notification.create(:message => "Test message", :app => a) }
  let(:n1_with_params) { Notifiable::Notification.create(:message => "Test message", :app => a, :params => {:flag => true}) }
  let(:d) { Notifiable::DeviceToken.create(:token => "ABC123", :provider => :gcm, :app => a) }
  
  it "sends a single gcm notification" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}')   
    
    n1.batch do |n|
      n.add_device_token(d)
    end
    
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 0
  end
  
  it "sends custom attributes" do        
    stub_request(:post, "https://android.googleapis.com/gcm/send")
      .with(:body => {:registration_ids => ["ABC123"], :data => {:message => n1.message, :flag => true, :notification_id => n1_with_params.id}})
      .to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}')   
    
    n1_with_params.batch do |n|
      n.add_device_token(d)
    end
      
    Notifiable::NotificationStatus.count.should == 1
    Notifiable::NotificationStatus.first.status = 0
  end
  
  it "delete an unregistered token" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "NotRegistered" }]}')  
        
    n1.batch do |n|
      n.add_device_token(d)
    end
        
    Notifiable::DeviceToken.count == 0
    Notifiable::NotificationStatus.count.should == 0
  end 
  
  it "delete an invalid token" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "InvalidRegistration" }]}')  
        
    n1.batch do |n|
      n.add_device_token(d)
    end
        
    Notifiable::DeviceToken.count == 0
    Notifiable::NotificationStatus.count.should == 0
  end 
  
  it "updates a token to the canonical ID if it does not exist" do   
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 1, "results": [{ "message_id": "1:08", "registration_id": "GHJ12345" }]}')  
        
    n1.batch do |n|
      n.add_device_token(d)
    end
        
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
        
    n1.batch do |n|
      n.add_device_token(d)
    end
        
    Notifiable::NotificationStatus.count.should == 0
  end 
  
end