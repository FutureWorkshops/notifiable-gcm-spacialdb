require 'notifiable'
require 'gcm'

module Notifiable
  module Gcm
    module Spacialdb
  		class Batch < Notifiable::NotifierBase
        
        attr_accessor :api_key, :batch_size
        
        def initialize
          @batch_size = 1000          
        end
                
        def batch
          @batch ||= {}
        end
        
        # todo should be made threadsafe
        protected 
  			def enqueue(notification, device_token, params)
          self.batch[notification.id] = [] if self.batch[notification.id].nil?
          self.batch[notification.id] << device_token        								
          tokens = self.batch[notification.id]
          if tokens.count >= self.batch_size
            send_batch(notification, tokens, params)
          end
    		end
      
        def flush
          self.batch.each_pair do |notification_id, device_tokens|
            notification = Notifiable::Notification.find(notification_id)
            send_batch(notification, device_tokens, custom_params(notification))
          end
        end

  			private
  			def send_batch(notification, device_tokens, params)
          if Notifiable.delivery_method == :test
            device_tokens.each {|d| processed(notification, d, 0)}
          else
    				gcm = ::GCM.new(self.api_key)
            
            data = {:message => notification.message}
            data.merge! params    
            
            # send
    				response = gcm.send_notification(device_tokens.collect{|dt| dt.token}, {:data => data})
            if response[:status_code] == 200
      				body = JSON.parse(response.fetch(:body, "{}"))
      				results = body.fetch("results", [])
      				results.each_with_index do |result, idx|
                # Remove the token if it is marked NotRegistered (user deleted the App for example)
      					if ["InvalidRegistration", "NotRegistered"].include? result["error"] 
      						device_tokens[idx].update_attribute('is_valid', false)
                
                # Process canonical IDs
                elsif result["registration_id"] && Notifiable::DeviceToken.exists?(:token => result["registration_id"])
                  device_tokens[idx].update_attribute('is_valid', false)                                        
                elsif result["registration_id"]
                  device_tokens[idx].update_attribute('token', result["registration_id"])                    
                end

                processed(notification, device_tokens[idx], error_code(result["error"]))
      				end 
            else
              Rails.logger.error "Sending notification id: #{notification.id} code: #{response[:status_code]} response: #{response[:response]}"
            end         
          end
          self.batch.delete(notification.id)
  			end
        
        def error_code(error_message)
          case error_message
          when "MissingRegistration"
            1
          when "InvalidRegistration"
            2
          when "MismatchSenderId"
            3
          when "NotRegistered"
            4
          when "MessageTooBig"
            5
          when "InvalidDataKey"
            6
          when "InvalidTtl"
            7
          when "Unavailable"
            8
          when "InternalServerError" 
            9   
          when "InvalidPackageName"
            10
          else
            0
          end
        end
      end
    end
  end
end
      