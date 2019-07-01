# frozen_string_literal: true

RSpec.describe QiniuNg::Client do
  describe QiniuNg::Storage::BucketManager do
    it 'should get all bucket names' do
      client = QiniuNg::Client.new(access_key: access_key, secret_key: secret_key)
      expect(client.bucket_names).to include('z0-bucket', 'z1-bucket', 'na-bucket')
    end

    it 'should create / drop bucket' do
      client = QiniuNg::Client.new(access_key: access_key, secret_key: secret_key)
      bucket = client.create_bucket("test-bucket-#{time_id}")
      begin
        expect(client.bucket_names).to include(bucket.name)
      ensure
        client.drop_bucket(bucket.name)
      end
    end
  end

  describe QiniuNg::Storage::Bucket do
    client = nil
    bucket = nil

    before :all do
      client = QiniuNg::Client.new(access_key: access_key, secret_key: secret_key)
      bucket = client.create_bucket("test-bucket-#{time_id}")
    end

    after :all do
      bucket.drop
    end

    it 'should get bucket domains' do
      expect(client.bucket('z0-bucket').domains).to include('z0-bucket.kodo-test.qiniu-solutions.com')
    end

    it 'should set / unset image for bucket' do
      expect(bucket.image).to be_nil
      begin
        bucket.set_image 'http://www.qiniu.com', source_host: 'z0-bucket.kodo-test.qiniu-solutions.com'
        expect(bucket.image.source_url).to eq('http://www.qiniu.com')
        expect(bucket.image.source_host).to eq('z0-bucket.kodo-test.qiniu-solutions.com')
      ensure
        bucket.unset_image
      end
    end

    it 'should update bucket acl' do
      expect(bucket).not_to be_private
      begin
        bucket.private!
        expect(bucket).to be_private
      ensure
        bucket.public!
        expect(bucket).not_to be_private
      end
    end

    it 'should update bucket noIndexPage' do
      expect(bucket).to have_index_page
      begin
        bucket.disable_index_page
        expect(bucket).not_to have_index_page
      ensure
        bucket.enable_index_page
        expect(bucket).to have_index_page
      end
    end
  end

  describe QiniuNg::Storage::Entry do
    client = nil
    bucket = nil
    entry = nil

    before :all do
      client = QiniuNg::Client.new(access_key: access_key, secret_key: secret_key)
      bucket = client.bucket('z0-bucket')
    end

    describe 'Basic' do
      before :all do
        entry = bucket.entry("16k-#{Time.now.usec}")
        bucket.uploader.upload(filepath: create_temp_file(kilo_size: 16), upload_token: entry.upload_token)
      end

      after :all do
        entry.try_delete
      end

      it 'should disable / enable the entry' do
        public_url = entry.download_url.public
        private_url = entry.download_url.private
        expect(head(public_url + "?t=#{Time.now.usec}")).to be_success
        expect(head(private_url + "&t=#{Time.now.usec}")).to be_success
        begin
          entry.disable!
          expect(head(public_url + "?t=#{Time.now.usec}").status).to eq 403
          expect(head(private_url + "&t=#{Time.now.usec}").status).to eq 403
        ensure
          entry.enable!
          expect(head(public_url + "?t=#{Time.now.usec}")).to be_success
          expect(head(private_url + "&t=#{Time.now.usec}")).to be_success
        end
      end

      it 'should set entry to infrequent / normal storage' do
        expect(entry.stat).to be_normal_storage
        expect(entry.stat).not_to be_infrequent_storage
        begin
          entry.infrequent_storage!
          expect(entry.stat).not_to be_normal_storage
          expect(entry.stat).to be_infrequent_storage
        ensure
          entry.normal_storage!
          expect(entry.stat).to be_normal_storage
          expect(entry.stat).not_to be_infrequent_storage
        end
      end

      it 'should change mime_type' do
        original_mime_type = entry.stat.mime_type
        expect(entry.stat.mime_type).not_to eq 'application/json'
        begin
          entry.change_mime_type 'application/json'
          expect(entry.stat.mime_type).to eq 'application/json'
        ensure
          entry.change_mime_type original_mime_type
          expect(entry.stat.mime_type).not_to eq 'application/json'
        end
      end

      it 'should rename the entry' do
        old_public_url = entry.download_url.public
        expect(head(old_public_url + "?t=#{Time.now.usec}")).to be_success
        new_entry = bucket.entry("16K-#{Time.now.usec}")
        new_public_url = new_entry.download_url.public
        begin
          entry.rename_to(new_entry.key)
          expect(head(old_public_url + "?t=#{Time.now.usec}").status).to eq 404
          expect(head(new_public_url + "?t=#{Time.now.usec}")).to be_success
        ensure
          new_entry.rename_to(entry.key)
          expect(head(old_public_url + "?t=#{Time.now.usec}")).to be_success
          expect(head(new_public_url + "?t=#{Time.now.usec}").status).to eq 404
        end
      end

      it 'should copy / delete the entry' do
        old_public_url = entry.download_url.public
        expect(head(old_public_url + "?t=#{Time.now.usec}")).to be_success
        new_entry = bucket.entry("16K-#{Time.now.usec}")
        new_public_url = new_entry.download_url.public
        begin
          entry.copy_to(bucket.name, new_entry.key)
          expect(head(old_public_url + "?t=#{Time.now.usec}")).to be_success
          expect(head(new_public_url + "?t=#{Time.now.usec}")).to be_success
        ensure
          new_entry.delete
          expect(head(old_public_url + "?t=#{Time.now.usec}")).to be_success
          expect(head(new_public_url + "?t=#{Time.now.usec}").status).to eq 404
        end
      end
    end

    describe 'Fetch' do
      it 'should fetch the entry from the url' do
        src_entry = client.bucket('z1-bucket').entry('1m')
        src_url = src_entry.download_url.private
        expect(head(src_url)).to be_success
        entry = bucket.entry("16k-#{Time.now.usec}")
        begin
          dest_entry = entry.fetch_from(src_url)
          expect(dest_entry.file_size).to eq(1 << 20)
          expect(head("#{dest_entry.download_url.public}?t=#{Time.now.usec}")).to be_success
        ensure
          entry.try_delete
        end
      end

      it 'should fetch the entry from the url async' do
        src_entry = client.bucket('z1-bucket').entry('1m')
        src_url = src_entry.download_url.private
        expect(head(src_url)).to be_success
        entry = bucket.entry("16k-#{Time.now.usec}")
        begin
          result = entry.fetch_from(src_url, async: true)
          expect { result }.to eventually be_done
          expect(head("#{entry.download_url.public}?t=#{Time.now.usec}")).to be_success
        ensure
          entry.try_delete
        end
      end
    end
  end

  describe QiniuNg::Storage::BatchOperations do
    client = nil

    before :all do
      client = QiniuNg::Client.new(access_key: access_key, secret_key: secret_key)
    end

    it 'should get all stats of a bucket' do
      files = %w[4k 16k 1m].freeze
      batch = client.bucket('z0-bucket').batch
      files.each do |file|
        batch = batch.stat(file)
      end
      results = batch.do
      expect(results.select(&:success?).size).to eq files.size
      expect(results.reject(&:success?).size).to be_zero
      expect(results.map { |result| result.response.file_size }).to eq(
        [4 * (1 << 10), 16 * (1 << 10), 1 * (1 << 20)]
      )
    end

    it 'should do batch operations more than limits' do
      size = (QiniuNg::Config.batch_max_size * 2.5).to_i
      batch = client.bucket('z0-bucket').batch
      size.times do
        batch = batch.stat('16k')
      end
      expect(batch.do.size).to eq size
    end
  end
end
