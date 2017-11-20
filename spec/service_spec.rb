require_relative '../app/service'
require_relative '../spec/support/json_response'

describe 'Shorty Service' do
  before(:all) { Redis.new.flushall }

  context 'POST /shorten' do
    context 'on success' do
      context 'with shortcode' do
        before(:all) do
          post '/shorten', { shortcode: 'HI_you', url: 'https://www.example.com/' }
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 201

        it 'shortens and responds with valid shortcode' do
          expect(JSON.parse(last_response.body)['shortcode']).to eq('HI_you')
        end
      end

      context 'without shortcode' do
        before(:all) do
          post '/shorten', { url: 'https://www.example.com/' }
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 201

        it 'shortens and responds with valid shortcode' do
          expect(JSON.parse(last_response.body)['shortcode']).to match(Shorty::SHORTCODE_SAVE_REGEX)
        end
      end
    end

    context 'on failure' do
      context 'when `url` is invalid/not present' do
        before(:all) do
          post '/shorten', { shortcode: 'HI_you' }
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 400
        it_behaves_like 'a response with message', '`url` is not present'
      end

      context 'when duplicate shortcode is given' do
        before(:all) do
          post '/shorten', { url: 'https://www.example.com/', shortcode: 'HI_you' }
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 409
        it_behaves_like 'a response with message', 'The desired shortcode is already in use. Shortcodes are case-sensitive.'
      end

      context 'when invalid shortcode is given' do
        before(:all) do
          post '/shorten', { url: 'https://www.example.com/', shortcode: 'HI_oo!' }
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 422
        it_behaves_like 'a response with message', 'The shortcode fails to meet the following regexp: `^[0-9a-zA-Z_]{4,}$`'
      end
    end
  end

  context 'GET /:shortcode' do
    context 'on success' do
      before(:all) do
        get '/HI_you'
      end

      it_behaves_like 'an application/json content_type response'
      it_behaves_like 'a response with status code', 302

      it 'redirects to shortcode\'s url' do
        expect(last_response.location).to eq('https://www.example.com/')
      end
    end

    context 'on failure' do
      before(:all) do
        get '/HI_oo!'
      end

      it_behaves_like 'an application/json content_type response'
      it_behaves_like 'a response with status code', 404
      it_behaves_like 'a response with message', 'The `shortcode` cannot be found in the system'
    end
  end

  context 'GET /:shortcode/stats' do
    context 'on success' do
      before(:all) do
        Redis.new.flushall
        post '/shorten', { shortcode: 'HI_you', url: 'https://www.example.com/' }
      end

      context 'returns initial values if the shortcode url is not visited' do
        before(:all) do
          get '/HI_you/stats'
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 200

        it 'returns JSON containing startDate, lastSeenDate and redirectCount with initial values' do
          expect(JSON.parse(last_response.body)['startDate']).to match(/[\d+\-]+T[\d+:]+\.\d+\w+/)
          expect(JSON.parse(last_response.body)['lastSeenDate']).to be_nil
          expect(JSON.parse(last_response.body)['redirectCount']).to eq(0)
        end
      end

      context 'returns next of set values if the shortcode url is visited again' do
        before(:all) do
          get '/HI_you'
          get '/HI_you/stats'
        end

        it_behaves_like 'an application/json content_type response'
        it_behaves_like 'a response with status code', 200

        it 'increments the redirectCount by 1 on get/:shortcode' do
          expect(JSON.parse(last_response.body)['redirectCount']).to eq(1)
        end

        it 'returns the last seen date when the shortcode visited' do
          expect(JSON.parse(last_response.body)['lastSeenDate']).to match(/[\d+\-]+T[\d+:]+\.\d+\w+/)
        end
      end
    end

    context 'on failure' do
      before(:all) do
        get '/HI_oo!/stats'
      end

      it_behaves_like 'an application/json content_type response'
      it_behaves_like 'a response with status code', 404
      it_behaves_like 'a response with message', 'The `shortcode` cannot be found in the system'
    end
  end
end
