require 'maily/version'
require 'maily/engine'
require 'maily/mailer'
require 'maily/email'
require 'maily/generator'

module Maily
  class << self
    attr_accessor :enabled, :allow_edition, :allow_delivery, :available_locales,
                  :base_controller, :http_authorization, :hooks_path, :welcome_message,
                  :mailer_root_path, :mailer_paths, :explicit_hooks_only

    def init!
      self.enabled            = Rails.env.production? ? false : true
      self.allow_edition      = Rails.env.production? ? false : true
      self.allow_delivery     = Rails.env.production? ? false : true
      self.available_locales  = Rails.application.config.i18n.available_locales || I18n.available_locales
      self.base_controller    = 'ActionController::Base'
      self.http_authorization = nil
      self.hooks_path         = "lib/maily_hooks.rb"
      self.welcome_message    = nil

      self.mailer_root_path   = Rails.root + 'app/mailers/'
      self.mailer_paths       = [Rails.root + 'app/mailers/*.rb']
      self.explicit_hooks_only = false
    end

    def load_emails_and_hooks
      # Load emails from file system
      Dir.glob(mailer_paths).each do |mailer|
        absolute_path = Pathname.new(File.expand_path(mailer))
        relative_path = absolute_path.relative_path_from(mailer_root_path)
        klass_name = relative_path.to_s.split('/').map {|part| File.basename(part, '.rb').camelize }.join('::')
        Maily::Mailer.new(klass_name)
      end

      # Load hooks
      hooks_file_path = File.join(Rails.root, hooks_path)
      require hooks_file_path if File.exist?(hooks_file_path)
    end

    def hooks_for(klass_name)
      mailer = Maily::Mailer.find(klass_name) || Maily::Mailer.new(klass_name)

      yield(mailer) if block_given?
    end

    def setup
      init!
      yield(self) if block_given?
    end

    def allowed_action?(action)
      case action.to_sym
      when :edit
        allow_edition
      when :update
        allow_edition && !Rails.env.production?
      when :deliver
        allow_delivery
      end
    end
  end
end
