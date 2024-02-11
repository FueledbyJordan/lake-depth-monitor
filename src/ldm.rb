#!/usr/bin/env ruby

require 'date'
require 'json'
require 'logger'
require 'net/http'
require 'uri'

require 'sendgrid-ruby'

def send_email(to, from, subject, body, sendgrid_api_key)
  from = SendGrid::Email.new(email: from)
  to = SendGrid::Email.new(email: to)
  content = SendGrid::Content.new(type: 'text/plain', value: body)
  mail = SendGrid::Mail.new(from, subject, to, content)
  sg = SendGrid::API.new(api_key: sendgrid_api_key)

  response = sg.client.mail._('send').post(request_body: mail.to_json)
  raise 'failed to send email' unless response.status_code.match?(/^2[0-9]{2}$/)
end

def ping_healthcheck(url)
  raise 'ping url cannot be empty' if url.empty?

  res = Net::HTTP.get_response(URI(url))
  raise 'healthcheck ping failure' unless res.is_a?(Net::HTTPSuccess)
end

def get_current_pool(url)
  res = Net::HTTP.get_response(URI(url))
  raise 'failed to get current pool' unless res.is_a?(Net::HTTPSuccess)

  today = Date.today
  JSON.parse(res.body)['charts']
      .find { |item| item['date'].to_s == today.to_s }[today.year.to_s]
      .to_f
end

def get_full_pool(url)
  uri = URI(url)
  res = Net::HTTP.get_response(uri)
  raise 'failed to get full pool' unless res.is_a?(Net::HTTPSuccess)

  full_match_regex = /pool of (?<full_pool>[0-9.]+)/
  full_pool_match = res.body.match(full_match_regex)
  raise "#{url} seems malformed." unless full_pool_match

  full_pool_match[:full_pool].to_f
end

if __FILE__ == $PROGRAM_NAME
  begin
    $stdout.sync = true
    log = Logger.new($stdout)

    begin_time = Time.now
    log.info 'lake depth monitor invoked'

    lake_name = ENV['LAKE_NAME']
    current_pool_url = ENV['CURRENT_POOL_URL']
    full_pool_url = ENV['FULL_POOL_URL']
    floor_threshold = ENV['FLOOR_THRESHOLD']
    ceiling_threshold = ENV['CEILING_THRESHOLD']
    ping_url = ENV['PING_URL']
    sendgrid_api_key = ENV['SENDGRID_API_KEY']
    mail_to = ENV['MAIL_TO']
    mail_from = ENV['MAIL_FROM']

    raise 'current_pool_url not set.' if current_pool_url.empty?
    raise 'full_pool_url not set.' if full_pool_url.empty?
    raise 'mail_to not set.' if mail_to.empty?
    raise 'mail_from not set.' if mail_from.empty?
    raise 'sendgrid_api_key not set.' if sendgrid_api_key.empty?
    raise 'floor_threshold not set.' if floor_threshold.empty?
    raise 'ceiling_threshold not set.' if ceiling_threshold.empty?

    @floor_threshold = floor_threshold.to_f
    @ceiling_threshold = ceiling_threshold.to_f

    current_pool = get_current_pool(current_pool_url)
    full_pool_feet = get_full_pool(full_pool_url)
    floor_threshold = full_pool_feet - floor_threshold.to_f
    ceiling_threshold = full_pool_feet + ceiling_threshold.to_f

    log.info "current pool is #{current_pool}"

    if current_pool <= floor_threshold
      subject = "#{lake_name} is at drought level"
      body = "Pool is #{current_pool} / #{full_pool_feet}.\n\nSincerely,\n\nThe Water Bot."
    elsif current_pool >= ceiling_threshold
      subject = "#{lake_name} is at flood level"
      body = "Pool is #{current_pool} / #{full_pool_feet}.\n\nSincerely,\n\nThe Water Bot."
    end

    if !subject.nil? && !body.nil?
      send_email(mail_to, mail_from, subject, body, sendgrid_api_key)
      log.info "sent email to #{mail_to}"
    end

    ping_healthcheck(ping_url)
  rescue StandardError => e
    log.error e.message
    exit_status = 1
  else
    exit_status = 0
  end

  end_time = Time.now
  run_duration = end_time.to_i - begin_time.to_i
  log.info "lake depth monitor complete. took #{run_duration}s"
  exit exit_status
end
