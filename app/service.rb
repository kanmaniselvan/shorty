require 'sinatra'
require 'pry'

require_relative 'lib/shorty'

before do
  content_type :json
end

def short_code_not_found_response
  status 404
  {message: 'The `shortcode` cannot be found in the system'}.to_json
end

def send_json_response(status, hash)
  status status
  hash.to_json
end

post '/shorten' do
  url = params[:url]
  shortcode = params[:shortcode]

  # Handles if `url` param is present and it just has empty strings and quotes.
  # Also, handles if the `url` param is not even present.
  if url.to_s.gsub(/[\'\" ]/, '').length.zero?
    return send_json_response(400, message: '`url` is not present')
  end

  # Return short code already present error message. If the given short code is already in use.
  if Shorty.find(shortcode)
    return send_json_response(409, message: 'The desired shortcode is already in use. Shortcodes are case-sensitive.')
  end

  # Checks if the given short follows the specified regex rules.
  if !shortcode.nil? && !Shorty.new(shortcode: shortcode).has_valid_shortcode?
    return send_json_response(422, message: 'The shortcode fails to meet the following regexp: `^[0-9a-zA-Z_]{4,}$`')
  end

  shorty = Shorty.new(url: url, shortcode: shortcode).save

  send_json_response(201, shortcode: shorty.shortcode)
end

get '/:shortcode' do
  shortcode = params[:shortcode]

  shorty_record = Shorty.find(shortcode)
  if shorty_record
    shorty_record.update_last_seen_and_redirect_count

    status 302
    headers 'Location' => shorty_record.url

    return
  end

  short_code_not_found_response
end

get '/:shortcode/stats' do
  shortcode = params[:shortcode]

  shorty_record = Shorty.find(shortcode)
  if shorty_record
    return send_json_response(200, shorty_record.stats_attributes)
  end

  short_code_not_found_response
end
