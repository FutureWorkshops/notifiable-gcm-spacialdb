require 'notifiable'
require 'gcm'

module Notifiable
  module Gcm
    module Spacialdb
  		class Batch < Notifiable::NotifierBase
        
        attr_accessor :api_key, :batch_size
        
        def initialize(env, notification)
          super(env, notification)
          @batch = []
          @batch_size = 1000          
        end
        
        protected 
    			def enqueue(device_token)
            @batch << device_token        								
            if @batch.count >= @batch_size
              send_batch
            end
      		end
      
          def flush
            send_batch unless @batch.empty?
          end

  			private
    			def send_batch
            if Notifiable.delivery_method == :test
              @batch.each {|d| processed(d, 0)}
            else
      				gcm = ::GCM.new(self.api_key)
            
              data = {:message => notification.message}.merge(notification.send_params)            
      				response = gcm.send_notification(@batch.collect{|dt| dt.token}, {:data => data})
              
              if response[:status_code] == 200
        				process_success_response(response)
              else
                Rails.logger.error "Sending notification id: #{notification.id} code: #{response[:status_code]} response: #{response[:response]}"
              end         
            end
            @batch = []
    			end
          
          def process_success_response(response)
    				body = JSON.parse(response.fetch(:body, "{}"))
    				results = body.fetch("results", [])
    				results.each_with_index do |result, i|
              dt = @batch[i]
              
              # Remove the token if it is marked NotRegistered (user deleted the App for example)
    					if ["InvalidRegistration", "NotRegistered"].include? result["error"] 
    						dt.update_attribute('is_valid', false)
            
              # Process canonical IDs
              elsif result["registration_id"] && Notifiable::DeviceToken.exists?(:token => result["registration_id"])
                dt.update_attribute('is_valid', false)                                        
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
      