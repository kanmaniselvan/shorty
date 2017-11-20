require 'securerandom'
require 'redis'

class Shorty
  attr_reader :url
  attr_accessor :shortcode, :last_seen_date, :redirect_count, :start_date

  SHORTCODE_POST_REGEX = /^[0-9a-zA-Z_]{4,}$/
  SHORTCODE_SAVE_REGEX = /^[0-9a-zA-Z_]{6}$/

  def initialize(attributes)
    @url = attributes[:url]
    @shortcode = attributes[:shortcode]
    @start_date = attributes[:start_date]
    @last_seen_date = attributes[:last_seen_date]
    @redirect_count = attributes[:redirect_count]
  end

  # Save the Shorty attributes and return the saved Shorty record.
  def save
    # Check if the Shorty has a valid shortcode with the matching pattern.
    # If not, then generate a new one.
    shortcode = self.has_valid_shortcode? ? self.shortcode : self.generate_shortcode

    self.shortcode = shortcode
    self.redirect_count = 0
    self.start_date = self.iso_8601_time_format

    Shorty.redis_conn.set(shortcode, self.attributes.to_json)

    Shorty.find(shortcode)
  end

  # Return the Shorty object from Redis.
  def self.find(shortcode)
    shorty_record = Shorty.redis_conn.get(shortcode)
    return nil unless shorty_record

    # Hash keys will be strings when parsed from Redis result, so convert it to symbols and
    # then initialize the record.
    Shorty.new(symbolize_hash_keys(JSON.parse(shorty_record)))
  end

  def update_last_seen_and_redirect_count
    self.last_seen_date = self.iso_8601_time_format
    self.redirect_count += 1
    Shorty.redis_conn.set(self.shortcode, self.attributes.to_json)
  end

  def has_valid_shortcode?
    self.shortcode.to_s.match(SHORTCODE_POST_REGEX)
  end

  def stats_attributes
    {
        startDate: self.start_date,
        lastSeenDate: self.last_seen_date,
        redirectCount: self.redirect_count,
    }
  end

  protected

  def iso_8601_time_format
    Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%Z')
  end

  def attributes
    {
        url: self.url,
        shortcode: self.shortcode,
        redirect_count: self.redirect_count,
        start_date: self.start_date,
        last_seen_date: self.last_seen_date
    }
  end

  # Returns uniq shortcode which matches ^[0-9a-zA-Z_]{6}$ pattern
  def generate_shortcode
    shortcode = SecureRandom.urlsafe_base64(4)

    # It's possible for the shortcode to have '-' character or the shortcode might already exist.
    # On such cases, do the regeneration.
    if shortcode.match(SHORTCODE_SAVE_REGEX).nil? || Shorty.find(shortcode)
      return self.generate_shortcode
    end

    shortcode
  end

  private
  # Establish Redis connection
  def self.redis_conn
    @redis_conn ||= Redis.new
  end

  # Convert all the keys of the hash to symbols.
  def self.symbolize_hash_keys(hash)
    hash.each_with_object({}) do |(k, v), temp_hash|
      temp_hash[k.to_s.to_sym] = v
    end
  end
end
