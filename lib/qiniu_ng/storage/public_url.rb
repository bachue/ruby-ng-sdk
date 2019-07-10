# frozen_string_literal: true

require 'webrick'

module QiniuNg
  module Storage
    # 七牛文件的公开下载地址
    #
    # 该类是 String 的子类，因此可以被当成 String 直接使用，不必调用 #to_s 方法。
    #
    # @example 下载公开空间中的文件
    #   Faraday.get(client.bucket('<Bucket Name>')
    #                     .entry('<key>')
    #                     .download_url)
    # @example 下载私有空间中的文件
    #   Faraday.get(client.bucket('<Bucket Name>')
    #                     .entry('<key>')
    #                     .download_url.private)
    # @example 下载 CDN 中 生成带有时间戳鉴权的文件
    #   Faraday.get(client.bucket('<Bucket Name>')
    #                     .entry('<key>')
    #                     .download_url
    #                     .timestamp_anti_leech(encrypt_key: '<EncryptKey>'))
    #
    # @!attribute [r] domain
    #   @return [String] 下载地址中的域名
    # @!attribute [r] key
    #   @return [String] 文件名
    # @!attribute filename
    #   @return [String] 文件下载后的文件名。该参数仅对由浏览器打开的地址有效
    # @!attribute fop
    #   @return [String] 数据处理参数。
    #     {参考文档}[https://developer.qiniu.com/dora/manual/1204/processing-mechanism]
    class PublicURL < URL
      attr_reader :domain, :key, :filename, :fop

      # @!visibility private
      def initialize(domain, key, auth, https: nil, filename: nil, fop: nil)
        @domain = domain
        @key = key
        @auth = auth
        @https = https.nil? ? Config.use_https : https
        @filename = filename
        @fop = fop
        @random = nil
        generate_public_url!
      end

      def filename=(filename)
        @filename = filename
        generate_public_url!
      end

      def fop=(fop)
        @fop = fop
        generate_public_url!
      end

      # 设置下载地址的下载后的文件名和数据处理参数
      #
      # @param [String] fop 数据处理参数
      #   {参考文档}[https://developer.qiniu.com/dora/manual/1204/processing-mechanism]
      # @param [String] filename 文件下载后的文件名。该参数仅对由浏览器打开的地址有效
      # @return [QiniuNg::Storage::PublicURL] 返回上下文
      def set(fop: nil, filename: nil)
        @filename = filename unless filename.nil?
        @fop = fop unless fop.nil?
        generate_public_url!
        self
      end

      # 为私有空间生成下载地址
      #
      # @example
      #   client.bucket('<Bucket Name>').entry('<key>').download_url.private
      #
      # @param [Integer, Hash] lifetime 下载地址有效期，与 duration 参数不要同时使用
      #   参数细节可以参考 {Duration}[https://www.rubydoc.info/gems/ruby-duration/Duration] 库文档
      # @param [Time] deadline 下载地址过期时间，与 lifetime 参数不要同时使用
      # @return [QiniuNg::Storage::PrivateURL] 返回私有空间的文件下载地址
      def private(lifetime: nil, deadline: nil)
        PrivateURL.new(self, @auth, lifetime, deadline)
      end

      # 为 CDN 生成带有时间戳鉴权的下载地址
      #
      # @example
      #   client.bucket('<Bucket Name>').entry('<key>').download_url.timestamp_anti_leech(encrypt_key: '<EncryptKey>')
      # @see https://developer.qiniu.com/kodo/manual/1657/download-anti-leech
      #
      # @param [String] encrypt_key CDN Key
      #   {参考文档}[https://developer.qiniu.com/fusion/kb/1670/timestamp-hotlinking-prevention]
      # @param [Integer, Hash] lifetime 下载地址有效期，与 duration 参数不要同时使用
      #   参数细节可以参考 {Duration}[https://www.rubydoc.info/gems/ruby-duration/Duration] 库文档
      # @param [Time] deadline 下载地址过期时间，与 lifetime 参数不要同时使用
      # @return [QiniuNg::Storage::TimestampAntiLeechURL] 返回带有时间戳鉴权的下载地址
      def timestamp_anti_leech(encrypt_key:, lifetime: nil, deadline: nil)
        TimestampAntiLeechURL.new(self, encrypt_key, lifetime, deadline)
      end

      # 为下载地址带一个随机参数，可以绕过缓存
      #
      # @return [QiniuNg::Storage::PublicURL] 返回上下文
      def refresh
        @random = Time.now.usec
        generate_public_url!
        self
      end

      private

      def generate_public_url!
        replace(generate_public_url_without_path + generate_public_url_without_domain)
      end

      def generate_public_url_without_path
        url = @https ? 'https://' : 'http://'
        url += @domain
        url
      end

      def generate_public_url_without_domain
        path = '/' + WEBrick::HTTPUtils.escape(@key)
        params = []
        params << [@fop] unless @fop.nil? || @fop.empty?
        params << ['attname', @filename] unless @filename.nil? || @filename.empty?
        params << ['tt', @random] unless @random.nil? || @random.zero?
        path += "?#{Faraday::Utils.build_query(params)}" unless params.empty?
        path
      end
    end
  end
end
