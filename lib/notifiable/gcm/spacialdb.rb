require 'notifiable'
require "notifiable/gcm/spacialdb/version"
require "notifiable/gcm/spacialdb/batch"

module Notifiable
  module Gcm
    module Spacialdb
    end
  end
end

Notifiable.notifier_classes[:gcm] = Notifiable::Gcm::Spacialdb::Batch
