require 'notifiable'
require 'gcm'

module Notifiable
  module Gcm
    module Spacialdb
  		class Batch < Notifiable::NotifierBase
        
        notifier_attribute :api_key, :batch_size
                
        def batch_size
          @batch_size || 1000
        end
        
        def batch
          @batch ||= []
        end
        
        protected        
        
  			def enqueue(device_token, notification)
          raise "API Key missing" if @api_key.nil?

          @batch_notification = notification
          batch << device_token        								
          send_batch(notification) if batch.count >= batch_size
    		end
    
        def flush
          send_batch(@batch_notification) unless batch.empty?
        end

  			private
        
  			def send_batch(notification)
  				gcm = ::GCM.new(@api_key)
        
          
          data = {message: notification.message}
          data[:title] = notification.title if notification.title
          data = data.merge(notification.send_params)          
  				response = gcm.send_notification(batch.collect{|dt| dt.token}, {:data => data})

          if response[:status_code] == 200
    				process_success_response(response)
          else
            logger.error "Sending notification id: #{notification.id} code: #{response[:status_code]} response: #{response[:response]}"
          end         
          @batch = []
  			end
        
        def process_success_response(response)
  				body = JSON.parse(response.fetch(:body, "{}"))
  				results = body.fetch("results", [])
  				results.each_with_index do |result, i|
            dt = batch[i]
            
            # Remove the token if it is marked NotRegistered (user deleted the App for example)
  					if ["InvalidRegistration", "NotRegistered"].include? result["error"] 
  					  dt.destroy
            # Process canonical IDs
            elsif result["registration_id"] && Notifiable::DeviceToken.exists?(:token => result["registration_id"])
              dt.destroy
            elsif result["registration_id"]
              dt.update_attribute('token', result["registration_id"])                    
            end

            processed(dt, error_code(result["error"]))
  				end

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
      