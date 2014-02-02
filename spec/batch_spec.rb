require 'spec_helper'

describe Notifiable::Gcm::Spacialdb::Batch do
  
  let(:g) { Notifiable::Gcm::Spacialdb::Batch.new }
  let(:n) { Notifiable::Notification.create(:message => "Test message") }
  let(:d) { Notifiable::DeviceToken.create(:token => "ABC123", :provider => :gcm) }
  let(:u) { User.new(d) }
  
  it "sends a single gcm notification" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}')   
    
    g.send_notification(n, d)
    g.close
    
    Notifiable::NotificationDeviceToken.count.should == 1
  end
  
  it "sends a single gcm notification in a batch" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 0, "results": [{ "message_id": "1:08" }]}')  
        
    Notifiable.batch {|b| b.add(n, u)}
    
    Notifiable::NotificationDeviceToken.count.should == 1
  end 
  
  it "invalidates a token" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 0, "failure": 1, "canonical_ids": 0, "results": [{ "error": "NotRegistered" }]}')  
        
    Notifiable.batch {|b| b.add(n, u)}
    
    Notifiable::NotificationDeviceToken.count.should == 0
    d.is_valid.should == false
  end 
  
  it "updates a token to the canonical ID" do    
    stub_request(:post, "https://android.googleapis.com/gcm/send").to_return(:body => '{ "multicast_id": 108, "success": 1, "failure": 0, "canonical_ids": 1, "results": [{ "message_id": "1:08", "registration_id": "GHJ12345" }]}')  
        
    Notifiable.batch {|b| b.add(n, u)}
    
    Notifiable::NotificationDeviceToken.count.should == 1
    d.token.should eql "GHJ12345"
  end 
  
end

User = Struct.new(:device_token) do
  def device_tokens
    [device_token]
  end
end