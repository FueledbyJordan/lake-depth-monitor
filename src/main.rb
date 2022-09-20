#!/usr/local/bin/ruby

require 'json'
require 'net/http'
require 'uri'
require 'open3'

def send_email(to, from, subject, body, smtp_host, smtp_port, smtp_security, smtp_username, smtp_password, smtp_auth_mechanism)
  stdout, rc = Open3.capture2('/usr/bin/mailx', '-S', "smtp=smtp://#{smtp_host}:#{smtp_port}", '-S', "from=#{from}", '-S', "smtp-auth=#{smtp_auth_mechanism}", '-S', "smtp-auth-user=#{smtp_username}", '-S', "smtp-auth-password=#{smtp_password}", '-s', subject, to, :stdin_data=>body)
  if rc == 0
    puts "#{Time.now} Mail sent to #{to}."
  else
    puts "#{Time.now} Failed to send mail to #{to}"
  end
  rc
end

def ping_healthcheck(url)
  rc = 0
  unless url.empty?
    stdout, rc = Open3.capture2('/usr/bin/wget', url, '-T', '15', '-t', '10', '-O', '/dev/null', '-q')
    if rc == 0
      puts "#{Time.now} Success ping sent to #{url}"
    else
      puts "#{Time.now} Failed to send success ping to #{url} with rc: #{rc}"
    end
  end
  rc
end

def exit_with_message(message, rc)
  puts message
  exit rc
end

def get_pool_stats(url, route)
  uri = URI("#{url}/#{route}/")
  res = Net::HTTP.get_response(uri)
  exit_with_message("#{url} => #{res.code}.", 1) unless res.is_a?(Net::HTTPSuccess)

  num_match_regex = %r{Level is (?<delta>[0-9.]+) (feet|inches)}
  num_match = res.body.match(num_match_regex)
  exit_with_message("#{url} seems malformed.", 1) unless num_match
  pool_delta_num = num_match[:delta].to_f

  delta_regex = %r{(?<pool_delta>(below|above|from)) full pool of [0-9.]+}
  delta_match = res.body.match(delta_regex)
  exit_with_message("#{url} seems malformed.", 1) unless delta_match
  pool_delta = delta_match[:pool_delta]

  pool_delta_num = pool_delta_num * -1 if pool_delta.downcase == 'below'

  full_match_regex = %r{pool of (?<full_pool>[0-9.]+)}
  full_pool_match = res.body.match(full_match_regex)
  exit_with_message("#{url} seems malformed.", 1) unless full_pool_match
  full_pool = full_pool_match[:full_pool].to_f

  pool_num = pool_delta_num + full_pool

  return pool_num, full_pool
end

if __FILE__ == $PROGRAM_NAME
  @LAKE_NAME = ENV['LAKE_NAME']
  @LAKE_URL = ENV['LAKE_URL']

  @FLOOR_THRESHOLD = ENV['FLOOR_THRESHOLD']
  @CEILING_THRESHOLD = ENV['CEILING_THRESHOLD']

  @PING_URL = ENV['PING_URL']

  @MAIL_TO = ENV['MAIL_TO']
  @MAIL_SMTP_HOST = ENV['MAIL_SMTP_HOST']
  @MAIL_SMTP_FROM = ENV['MAIL_SMTP_FROM']
  @MAIL_SMTP_PORT = ENV['MAIL_SMTP_PORT']
  @MAIL_SMTP_SECURITY = ENV['MAIL_SMTP_SECURITY']
  @MAIL_SMTP_USERNAME = ENV['MAIL_SMTP_USERNAME']
  @MAIL_SMTP_PASSWORD = ENV['MAIL_SMTP_PASSWORD']
  @MAIL_SMTP_AUTH_MECHANISM = ENV['MAIL_SMTP_AUTH_MECHANISM']

  exit_with_message('LAKE_URL not set.', 1) if @LAKE_URL.empty?
  exit_with_message('MAIL_TO not set.', 1) if @MAIL_TO.empty?
  exit_with_message('MAIL_SMTP_HOST not set.', 1) if @MAIL_SMTP_HOST.empty?
  exit_with_message('MAIL_SMTP_FROM not set.', 1) if @MAIL_SMTP_FROM.empty?
  exit_with_message('MAIL_SMTP_PORT not set.', 1) if @MAIL_SMTP_PORT.empty?
  exit_with_message('MAIL_SMTP_SECURITY not set.', 1) if @MAIL_SMTP_SECURITY.empty?
  exit_with_message('MAIL_SMTP_USERNAME not set.', 1) if @MAIL_SMTP_USERNAME.empty?
  exit_with_message('MAIL_SMTP_PASSWORD not set.', 1) if @MAIL_SMTP_PASSWORD.empty?
  exit_with_message('MAIL_SMTP_AUTH_MECHANISM not set.', 1) if @MAIL_SMTP_AUTH_MECHANISM.empty?

  @FLOOR_THRESHOLD = @FLOOR_THRESHOLD.empty? ? 3.0 : @FLOOR_THRESHOLD.to_f
  @CEILING_THRESHOLD = @CEILING_THRESHOLD.empty? ? 0.2 : @CEILING_THRESHOLD.to_f

  pool_elevation, full_pool_feet = get_pool_stats(@LAKE_URL, '/Level/')

  floor_feet = full_pool_feet - @FLOOR_THRESHOLD
  ceiling_feet = full_pool_feet + @CEILING_THRESHOLD

  if pool_elevation < floor_feet
    subject = "#{@LAKE_NAME} is at drought level"
    body = "Pool is #{pool_elevation} / #{full_pool_feet}.\n\nSincerely,\n\nThe Water Bot."
    rc = send_email(@MAIL_TO, @MAIL_SMTP_FROM, subject, body, @MAIL_SMTP_HOST, @MAIL_SMTP_PORT, @MAIL_SMTP_SECURITY, @MAIL_SMTP_USERNAME, @MAIL_SMTP_PASSWORD, @MAIL_SMTP_AUTH_MECHANISM)
    exit_with_message('Email send failed.', 1) if rc != 0
  elsif pool_elevation > ceiling_feet
    subject = "#{@LAKE_NAME} is at flood level"
    body = "Pool is #{pool_elevation} / #{full_pool_feet}.\n\nSincerely,\n\nThe Water Bot."
    rc = send_email(@MAIL_TO, @MAIL_SMTP_FROM, subject, body, @MAIL_SMTP_HOST, @MAIL_SMTP_PORT, @MAIL_SMTP_SECURITY, @MAIL_SMTP_USERNAME, @MAIL_SMTP_PASSWORD, @MAIL_SMTP_AUTH_MECHANISM)
    exit_with_message('Email send failed.', 1) if rc != 0
  end

  ping_healthcheck(@PING_URL)
  exit 0
end
