# frozen_string_literal: true

RSpec.describe Ngqiniu::Storage::Model do
  describe Ngqiniu::Storage::Model::Entry do
    it 'should be able to parse entry from string' do
      entry = Ngqiniu::Storage::Model::Entry.parse('test:filename')
      expect(entry.bucket).to eq('test')
      expect(entry.key).to eq('filename')
    end

    it 'should be able to decode entry from string' do
      entry = Ngqiniu::Storage::Model::Entry.decode(Base64.urlsafe_encode64('test:filename'))
      expect(entry.bucket).to eq('test')
      expect(entry.key).to eq('filename')
    end
  end

  describe Ngqiniu::Storage::Model::UploadPolicy do
    it 'should be able to create upload token with only bucket' do
      policy = Ngqiniu::Storage::Model::UploadPolicy.new bucket: 'test'
      h = policy.to_h
      expect(h[:scope]).to eq Base64.urlsafe_encode64('test')
    end

    it 'should be able to create upload token with bucket and key' do
      policy = Ngqiniu::Storage::Model::UploadPolicy.new bucket: 'test', key: 'filename'
      h = policy.to_h
      expect(h[:scope]).to eq Base64.urlsafe_encode64('test:filename')
    end

    it 'should be able to create upload token with bucket and key prefix' do
      policy = Ngqiniu::Storage::Model::UploadPolicy.new bucket: 'test', key_prefix: 'filename'
      h = policy.to_h
      expect(h[:scope]).to eq Base64.urlsafe_encode64('test:filename')
      expect(h[:isPrefixalScope]).to eq 1
    end

    it 'could set lifetime of the uptoken' do
      policy = Ngqiniu::Storage::Model::UploadPolicy.new bucket: 'test'
      policy.lifetime = Duration.new seconds: 30
      expect(policy.deadline).to be_within(1).of(Time.now + 30)
      h = policy.to_h
      expect(h[:deadline]).to be_within(1).of(Time.now.to_i + 30)
      sleep(1)
      expect(policy.lifetime.to_i).to be <= 29
    end

    it 'could set to infrequent storage' do
      policy = Ngqiniu::Storage::Model::UploadPolicy.new bucket: 'test'
      expect(policy).not_to be_infrequent
      policy.infrequent!
      expect(policy).to be_infrequent
    end
  end
end
