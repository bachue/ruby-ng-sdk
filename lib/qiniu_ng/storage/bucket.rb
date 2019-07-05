# frozen_string_literal: true

module QiniuNg
  module Storage
    # 七牛空间
    class Bucket
      def initialize(bucket_name, zone, http_client_v1, http_client_v2, auth)
        @bucket_name = bucket_name.freeze
        @http_client_v1 = http_client_v1
        @http_client_v2 = http_client_v2
        @auth = auth
        @zone = zone
      end

      def name
        @bucket_name
      end

      def zone
        @zone ||= begin
          Common::Zone.auto.query(access_key: @auth.access_key, bucket: @bucket_name)
        end
      end
      attr_writer :zone

      def drop(rs_zone: nil, https: nil, **options)
        BucketManager.new(@http_client_v1, @http_client_v2, @auth)
                     .drop_bucket(@bucket_name, rs_zone: rs_zone, https: https, **options)
      end
      alias delete drop

      def domains(api_zone: nil, https: nil, **options)
        params = { tbl: @bucket_name }
        @http_client_v1.get('/v6/domain/list', get_api_url(api_zone, https), params: params, **options).body
      end

      def set_image(source_url, uc_url: nil, source_host: nil, https: nil, **options)
        encoded_url = Base64.urlsafe_encode64(source_url)
        path = "/image/#{@bucket_name}/from/#{encoded_url}"
        path += "/host/#{Base64.urlsafe_encode64(source_host)}" unless source_host.nil? || source_host.empty?
        @http_client_v1.post(path, uc_url || get_uc_url(https), **options)
        nil
      end

      def unset_image(uc_url: nil, https: nil, **options)
        @http_client_v1.post("/unimage/#{@bucket_name}", uc_url || get_uc_url(https), **options)
        nil
      end

      def public!(uc_url: nil, https: nil, **options)
        update_acl(private_access: false, uc_url: uc_url, https: https, **options)
      end

      def private!(uc_url: nil, https: nil, **options)
        update_acl(private_access: true, uc_url: uc_url, https: https, **options)
      end

      def private?(uc_url: nil, https: nil, **options)
        info(uc_url: uc_url, https: https, **options)['private'] == 1
      end

      ImageInfo = Struct.new(:source_url, :source_host)

      def image(uc_url: nil, https: nil, **options)
        result = info(uc_url: uc_url, https: https, **options)
        ImageInfo.new(result['source'], result['host']) if result['source']
      end

      def enable_index_page(uc_url: nil, https: nil, **options)
        set_index_page(true, uc_url: uc_url, https: https, **options)
      end

      def disable_index_page(uc_url: nil, https: nil, **options)
        set_index_page(false, uc_url: uc_url, https: https, **options)
      end

      def has_index_page?(uc_url: nil, https: nil, **options)
        info(uc_url: uc_url, https: https, **options)['no_index_page'].zero?
      end

      def entry(key)
        Entry.new(self, key, @http_client_v1, @http_client_v2, @auth)
      end

      def files(rsf_zone: nil, prefix: nil, limit: nil, marker: nil, https: nil, **options)
        FilesEnumerable.new(@http_client_v1, @http_client_v2, @auth,
                            self, prefix, limit, marker, rsf_zone, https, options)
      end

      # 文件列举迭代器
      class FilesEnumerable
        include Enumerable

        def initialize(http_client_v1, http_client_v2, auth, bucket, prefix, limit, marker, rsf_zone, https, options)
          @http_client_v1 = http_client_v1
          @http_client_v2 = http_client_v2
          @auth = auth
          @bucket = bucket
          @prefix = prefix
          @limit = limit
          @marker = marker
          @got = 0
          @rsf_url = get_rsf_url(rsf_zone, https)
          @options = options
        end

        def each
          enumerator.each do |entry|
            yield entry
          end
        end

        private

        def enumerator
          Enumerator.new do |yielder|
            loop do
              params = { bucket: @bucket.name }
              params[:prefix] = @prefix unless @prefix.nil? || @prefix.empty?
              params[:limit] = @limit unless @limit.nil? || !@limit.positive?
              params[:marker] = @marker unless @marker.nil? || @marker.empty?
              body = @http_client_v1.post('/list', @rsf_url, params: params, **@options).body
              @marker = body['marker']
              break if body['items'].size.zero?

              body['items'].each do |item|
                break unless @limit.nil? || @got < @limit

                entry = Entry.new(@bucket, item['key'], @http_client_v1, @http_client_v2, @auth)
                yielder << Model::ListedEntry.new(
                  entry, mime_type: item['mimeType'], hash: item['hash'], file_size: item['fsize'],
                         created_at: Time.at(0, item['putTime'].to_f / 10), end_user: item['endUser'],
                         storage_type: item['type'], status: item['status']
                )
                @got += 1
              end
              break if @marker.nil? || @marker.empty? || (!@limit.nil? && @got >= @limit)
            end
          end
        end

        def get_rsf_url(rsf_zone, https)
          https = Config.use_https if https.nil?
          rsf_zone ||= @bucket.zone
          rsf_zone.rsf_url(https)
        end
      end

      def uploader(block_size: Config.default_upload_block_size)
        Uploader.new(self, @http_client_v1, @auth, block_size: block_size)
      end

      def upload_token(key: nil, key_prefix: nil)
        return upload_token_for_key(key) unless key.nil?
        return upload_token_for_key_prefix(key_prefix) unless key_prefix.nil?

        upload_token_for_bucket
      end

      def upload_token_for_bucket
        policy = Model::UploadPolicy.new(bucket: @bucket_name)
        yield policy if block_given?
        UploadToken.from_policy(policy, @auth)
      end

      def upload_token_for_key(key)
        policy = Model::UploadPolicy.new(bucket: @bucket_name, key: key)
        yield policy if block_given?
        UploadToken.from_policy(policy, @auth)
      end

      def upload_token_for_key_prefix(key_prefix)
        policy = Model::UploadPolicy.new(bucket: @bucket_name, key_prefix: key_prefix)
        yield policy if block_given?
        UploadToken.from_policy(policy, @auth)
      end

      def batch
        BatchOperations.new(self, @http_client_v1, @http_client_v2, @auth)
      end

      def life_cycle_rules
        LifeCycleRules.new(self, @http_client_v1, @auth)
      end

      private

      def set_index_page(enabled, uc_url: nil, https: nil, **options)
        no_index_page = Utils::Bool.to_int(!enabled)
        params = { bucket: @bucket_name, noIndexPage: no_index_page }
        @http_client_v1.post('/noIndexPage', uc_url || get_uc_url(https), params: params, **options)
        nil
      end

      def update_acl(private_access:, uc_url: nil, https: nil, **options)
        private_access = Utils::Bool.to_int(private_access)
        params = { bucket: @bucket_name, private: private_access }
        @http_client_v1.post('/private', uc_url || get_uc_url(https), params: params, **options)
        nil
      end

      def info(uc_url: nil, https: nil, **options)
        @http_client_v1.get('/v2/bucketInfo', uc_url || get_uc_url(https), params: { bucket: @bucket_name },
                                                                           **options).body
      end

      def get_api_url(api_zone, https)
        https = Config.use_https if https.nil?
        api_zone ||= zone
        api_zone.api_url(https)
      end

      def get_rs_url(rs_zone, https)
        https = Config.use_https if https.nil?
        rs_zone ||= zone
        rs_zone.rs_url(https)
      end

      def get_uc_url(https)
        Utils::Bool.to_bool(https) ? 'https://uc.qbox.me' : 'http://uc.qbox.me'
      end
    end
  end
end
