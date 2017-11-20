shared_examples_for 'an application/json content_type response' do
  it 'responds with application/json content_type' do
    expect(last_response.content_type).to eq('application/json')
  end
end

shared_examples_for 'a response with status code' do |status|
  it "responds with status #{status}" do
    expect(last_response.status).to eq(status)
  end
end

shared_examples_for 'a response with message' do |message|
  it "responds with #{message} message" do
    expect(JSON.parse(last_response.body)['message']).to match(message)
  end
end
