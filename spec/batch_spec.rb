require 'spec_helper'

describe Notifiable::Gcm::Spacialdb::Batch do
  
  let(:g) { Notifiable::Gcm::Spacialdb::Batch.new }
  let(:n) { Notifiable::Notification.create(:message => "Test message") }
  let(:d) { Notifiable::DeviceToken.create(:token => "ABC123", :provider => :gcm) }
  let(:u) { User.new(d) }
  
  it "sends a single gcm notification" do    
          
    
    g.send_notification(n, d)
    g.close
    Notifiable::NotificationDeviceToken.count.should == 1
    # todo check stub
    
  end
  
  it "sends a single gcm notification in a batch" do    
    
    Notifiable.batch do |b|
      b.add(n, u)
    end
    Notifiable::NotificationDeviceToken.count.should == 1
    
    # todo check stub
  end 
  
end

User = Struct.new(:device_token) do
  def device_tokens
    [device_token]
  end
end