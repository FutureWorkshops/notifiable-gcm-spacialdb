require 'notifiable'
require 'gcm'

module Notifiable
  module Gcm
    module Spacialdb
  		class Batch < Notifiable::NotifierBase
        def batch
          @batch ||= {}
        end
        
        # todo should be made threadsafe
        protected 
  			def enqueue(notification, device_token)
          self.batch[notification.id] = [] if self.batch[notification.id].nil?
          self.batch[notification.id] << device_token        								
          tokens = self.batch[notification.id]
          if tokens.count >= Notifiable.gcm_batch_size
            send_batch(notification, tokens)
          end
    		end
      
        def flush
          self.batch.each_pair do |notification_id, device_tokens|
            send_batch(Notifiable::Notification.find(notification_id), device_tokens)
          end
        end

  			private
  			def send_batch(notification, device_tokens)
          if Notifiable.delivery_method == :test
            device_tokens.each {|d| processed(notification, d)}
          else
    				gcm = ::GCM.new(Notifiable.gcm_api_key)
    				response = gcm.send_notification(device_tokens.collect{|dt| dt.token}, {:data => {:message => notification.message}})
    				body = JSON.parse(response.fetch(:body, "{}"))
    				results = body.fetch("results", [])
    				results.each_with_index do |result, idx|
              # Remove the token if it is marked NotRegistered (user deleted the App for example)
    					if result["error"].eql? "NotRegistered"
    						device_tokens[idx].update_attribute('is_valid', false)
              else
                
                # Update the token if a canonical ID is returned
                if result["registration_id"]
                  device_tokens[idx].update_attribute('token', result["registration_id"])
                end
                
                # Mark as processed
                processed(notification, device_tokens[idx])
              end
    				end          
          end
          self.batch.delete(notification.id)
  			end
      end
    end
  end
end
      