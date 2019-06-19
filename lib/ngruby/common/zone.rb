# frozen_string_literal: true

module Ngruby
  module Common
    # 多区域上传域名
    class Zone
      attr_reader :region
      attr_reader :up_http
      attr_reader :up_https
      attr_reader :up_backup_http
      attr_reader :up_backup_https
      attr_reader :up_ip_http
      attr_reader :up_ip_https
      attr_reader :io_vip_http
      attr_reader :io_vip_https
      attr_reader :rs_http
      attr_reader :rs_https
      attr_reader :rsf_http
      attr_reader :rsf_https
      attr_reader :api_http
      attr_reader :api_https

      def initialize(
        region:,
        up_http: nil,
        up_https: nil,
        up_backup_http: nil,
        up_backup_https: nil,
        up_ip_http: nil,
        up_ip_https: nil,
        io_vip_http: nil,
        io_vip_https: nil,
        rs_http: 'http://rs.qiniu.com',
        rs_https: 'https://rs.qbox.me',
        rsf_http: 'http://rsf.qiniu.com',
        rsf_https: 'https://rsf.qbox.me',
        api_http: 'http://api.qiniu.com',
        api_https: 'https://api.qiniu.com'
      )
        @region = region
        @up_http = up_http
        @up_https = up_https
        @up_backup_http = up_backup_http
        @up_backup_https = up_backup_https
        @up_ip_http = up_ip_http
        @up_ip_https = up_ip_https
        @io_vip_http = io_vip_http
        @io_vip_https = io_vip_https
        @rs_http = rs_http
        @rs_https = rs_https
        @rsf_http = rsf_http
        @rsf_https = rsf_https
        @api_http = api_http
        @api_https = api_https
      end

      class << self
        def auto(api_server: AutoZone::API_SERVER)
          AutoZone.new(api_server: api_server)
        end

        def huadong
          new(region: 'z0',
              up_http: 'http://up.qiniu.com',
              up_https: 'https://up.qbox.me',
              up_backup_http: 'http://upload.qiniu.com',
              up_backup_https: 'https://upload.qbox.me',
              io_vip_http: 'http://iovip.qbox.me',
              io_vip_https: 'https://iovip.qbox.me',
              rs_http: 'http://rs.qiniu.com',
              rs_https: 'https://rs.qbox.me',
              rsf_http: 'http://rsf.qiniu.com',
              rsf_https: 'https://rsf.qbox.me',
              api_http: 'http://api.qiniu.com',
              api_https: 'https://api.qiniu.com').freeze
        end
        alias zone0 huadong

        def qvm_huadong
          new(region: 'z0',
              up_http: 'http://free-qvm-z0-xs.qiniup.com',
              up_https: 'https://free-qvm-z0-xs.qiniup.com',
              up_backup_http: 'http://free-qvm-z0-xs.qiniup.com',
              up_backup_https: 'https://free-qvm-z0-xs.qiniup.com',
              io_vip_http: 'http://iovip.qbox.me',
              io_vip_https: 'https://iovip.qbox.me',
              rs_http: 'http://rs.qiniu.com',
              rs_https: 'https://rs.qbox.me',
              rsf_http: 'http://rsf.qiniu.com',
              rsf_https: 'https://rsf.qbox.me',
              api_http: 'http://api.qiniu.com',
              api_https: 'https://api.qiniu.com').freeze
        end
        alias qvm_zone0 qvm_huadong

        def huabei
          new(region: 'z1',
              up_http: 'http://up-z1.qiniu.com',
              up_https: 'https://up-z1.qbox.me',
              up_backup_http: 'http://upload-z1.qiniu.com',
              up_backup_https: 'https://upload-z1.qbox.me',
              io_vip_http: 'http://iovip-z1.qbox.me',
              io_vip_https: 'https://iovip-z1.qbox.me',
              rs_http: 'http://rs-z1.qiniu.com',
              rs_https: 'https://rs-z1.qbox.me',
              rsf_http: 'http://rsf-z1.qiniu.com',
              rsf_https: 'https://rsf-z1.qbox.me',
              api_http: 'http://api-z1.qiniu.com',
              api_https: 'https://api-z1.qiniu.com').freeze
        end
        alias zone1 huabei

        def qvm_huabei
          new(region: 'z1',
              up_http: 'http://free-qvm-z1-zz.qiniup.com',
              up_https: 'https://free-qvm-z1-zz.qiniup.com',
              up_backup_http: 'http://free-qvm-z1-zz.qiniup.com',
              up_backup_https: 'https://free-qvm-z1-zz.qiniup.com',
              io_vip_http: 'http://iovip-z1.qbox.me',
              io_vip_https: 'https://iovip-z1.qbox.me',
              rs_http: 'http://rs-z1.qiniu.com',
              rs_https: 'https://rs-z1.qbox.me',
              rsf_http: 'http://rsf-z1.qiniu.com',
              rsf_https: 'https://rsf-z1.qbox.me',
              api_http: 'http://api-z1.qiniu.com',
              api_https: 'https://api-z1.qiniu.com').freeze
        end
        alias qvm_zone1 qvm_huabei

        def huanan
          new(region: 'z2',
              up_http: 'http://up-z2.qiniu.com',
              up_https: 'https://up-z2.qbox.me',
              up_backup_http: 'http://upload-z2.qiniu.com',
              up_backup_https: 'https://upload-z2.qbox.me',
              io_vip_http: 'http://iovip-z2.qbox.me',
              io_vip_https: 'https://iovip-z2.qbox.me',
              rs_http: 'http://rs-z2.qiniu.com',
              rs_https: 'https://rs-z2.qbox.me',
              rsf_http: 'http://rsf-z2.qiniu.com',
              rsf_https: 'https://rsf-z2.qbox.me',
              api_http: 'http://api-z2.qiniu.com',
              api_https: 'https://api-z2.qiniu.com').freeze
        end
        alias zone2 huanan

        def beimei
          new(region: 'na0',
              up_http: 'http://up-na0.qiniu.com',
              up_https: 'https://up-na0.qbox.me',
              up_backup_http: 'http://upload-na0.qiniu.com',
              up_backup_https: 'https://upload-na0.qbox.me',
              io_vip_http: 'http://iovip-na0.qbox.me',
              io_vip_https: 'https://iovip-na0.qbox.me',
              rs_http: 'http://rs-na0.qiniu.com',
              rs_https: 'https://rs-na0.qbox.me',
              rsf_http: 'http://rsf-na0.qiniu.com',
              rsf_https: 'https://rsf-na0.qbox.me',
              api_http: 'http://api-na0.qiniu.com',
              api_https: 'https://api-na0.qiniu.com').freeze
        end
        alias zone_na0 beimei
        alias north_america beimei

        def xinjiapo
          new(region: 'as0',
              up_http: 'http://up-as0.qiniu.com',
              up_https: 'https://up-as0.qbox.me',
              up_backup_http: 'http://upload-as0.qiniu.com',
              up_backup_https: 'https://upload-as0.qbox.me',
              io_vip_http: 'http://iovip-as0.qbox.me',
              io_vip_https: 'https://iovip-as0.qbox.me',
              rs_http: 'http://rs-as0.qiniu.com',
              rs_https: 'https://rs-as0.qbox.me',
              rsf_http: 'http://rsf-as0.qiniu.com',
              rsf_https: 'https://rsf-as0.qbox.me',
              api_http: 'http://api-as0.qiniu.com',
              api_https: 'https://api-as0.qiniu.com').freeze
        end
        alias zone_as0 xinjiapo
        alias singapore xinjiapo
      end
    end
  end
end
