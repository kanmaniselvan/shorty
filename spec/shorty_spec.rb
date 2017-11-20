require_relative '../app/lib/shorty'

describe Shorty do
  before(:all) do
    Redis.new.flushall

    iso_8601_time_format = Shorty.new({}).send(:iso_8601_time_format)
    @shorty_attributes = {
        url: 'https://www.example.com/',
        shortcode: 'HI_you',
        redirect_count: 0,
        start_date: iso_8601_time_format,
        last_seen_date: iso_8601_time_format
    }
  end

  context 'find' do
    it 'finds and returns shorty object for the given shortcode' do
      Shorty.new(@shorty_attributes).save

      expect(Shorty.find(@shorty_attributes[:shortcode]).shortcode).to eq(@shorty_attributes[:shortcode])
    end

    it 'returns nil if the given shortcode is invalid' do
      expect(Shorty.find('hello')).to eq(nil)
    end
  end

  context 'save' do
    let(:shorty) { Shorty.new(url: @shorty_attributes[:url], shortcode: @shorty_attributes[:shortcode]) }

    it 'saves shorty with the given valid shortcode param' do
      expect(shorty.save.shortcode).to eq(@shorty_attributes[:shortcode])
    end

    it 'saves shorty with new shortcode, if given shortcode is blank' do
      shorty.shortcode = nil
      shorty_record = shorty.save

      expect(shorty_record.shortcode).to eq(Shorty.find(shorty_record.shortcode).shortcode)
    end

    it 'sets redirect_count as zero on save' do
      expect(shorty.save.redirect_count).to eq(0)
    end

    it 'sets start_date on save' do
      expect(shorty.save.start_date).to include(Time.now.strftime('%Y-%m-%d'))
    end
  end

  context 'support methods' do
    let(:shorty) { Shorty.new(@shorty_attributes).save }

    context 'update_last_seen_and_redirect_count' do
      it 'updates redirect_count by 1' do
        expect{shorty.update_last_seen_and_redirect_count}.to change{shorty.redirect_count}.by(1)
      end

      it 'updates last_seen_date' do
        expect{shorty.update_last_seen_and_redirect_count}.to change{shorty.last_seen_date}
      end
    end

    context 'has_valid_shortcode?' do
      it 'returns true if shortcode matches `/^[0-9a-zA-Z_]{4,}$/` pattern' do
        expect(shorty.has_valid_shortcode?).to be_truthy
      end

      it 'returns false if shortcode doesn\'t match `/^[0-9a-zA-Z_]{4,}$/` pattern' do
        shorty.shortcode = '#hello'
        expect(shorty.has_valid_shortcode?).to be_falsey
      end
    end

    it 'returns startDate, lastSeenDate and redirectCount as hash on calling stats_attributes' do
      expect(shorty.stats_attributes).to eq({
                                                startDate: shorty.start_date,
                                                lastSeenDate: shorty.last_seen_date,
                                                redirectCount: shorty.redirect_count,
                                            })
    end

    it 'generate a valid shortcode which matches `/^[0-9a-zA-Z_]{4,}$/` pattern on calling generate_shortcode' do
      expect(shorty.send(:generate_shortcode)).to match(Shorty::SHORTCODE_SAVE_REGEX)
    end

    it 'returns ISO 8601 time format on calling iso_8601_time_format' do
      expect(shorty.send(:iso_8601_time_format)).to match(/[\d+\-]+T[\d+:]+\.\d+\w+/)
    end

    it 'returns all its attributes as hash when calling attributes method' do
      expect(shorty.send(:attributes).keys.sort).to eq(@shorty_attributes.keys.sort)
    end
  end

  context 'utils' do
    it 'symbolizes all the hash keys' do
      expect(Shorty.send(:symbolize_hash_keys, {'a'=> 1, b: 1})).to eq(a: 1, b: 1)
    end
  end
end
