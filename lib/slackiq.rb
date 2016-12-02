require 'slackiq/version'

require 'net/http'
require 'json'
require 'httparty'

require 'slackiq/time_helper'

require 'active_support' #for Hash#except

module Slackiq

  class << self

    # Configure all of the webhook URLs you're going to use
    # @author Jason Lew
    def configure(webhook_urls={})
      raise 'Argument must be a Hash' unless webhook_urls.class == Hash
      @@webhook_urls = webhook_urls
    end

    # Send a notification to Slack with Sidekiq info about the batch
    # @author Jason Lew
    def notify(options={})
      url = @@webhook_urls[options[:webhook_name]]
      title = options[:title]
      status = options[:status]
      color = options[:color] || color_for(status)
      duration = Slackiq::TimeHelper.elapsed_time_humanized(options[:created_at], Time.current)
      extra_fields = options.except(:webhook_name, :title, :status, :color, :created_at)

      fields = [
        {
          'title' => 'Résultat',
          'value' => status == :success ? 'Succès' : 'Échec',
          'short' => true
        },
        {
          'title' => "Temps d'exécution",
          'value' => duration,
          'short' => true
        }
      ]

      # add extra fields
      fields += extra_fields.map do |title, value|
        {
          'title' => title,
          'value' => value,
          'short' => false
        }
      end

      attachments = [
        {
          'fallback' => title,
          'color' => color,
          'title' => title,
          'fields' => fields,
        }
      ]

      body = {attachments: attachments}.to_json

      HTTParty.post(url, body: body)
    end

    # Send a notification without Sidekiq batch info
    # @author Jason Lew
    def message(text, options)
      url = @@webhook_urls[options[:webhook_name]]

      body = { 'text' => text }.to_json

      HTTParty.post(url, body: body)
    end

  private

    def color_for(status)
      case status
      when :success then '#21BA45'
      when :failure then '#DB2828'
      else               '#FBBD08'
      end
    end

  end

end
