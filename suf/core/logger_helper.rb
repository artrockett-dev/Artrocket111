require 'logger'

module SU_Furniture
  module LoggerHelper
    def self.logger
      return @logger if defined?(@logger) && @logger
      require 'logger'
      log_dir = File.join(Dir.tmpdir, 'SUF')
      Dir.mkdir(log_dir) unless File.directory?(log_dir)
      @logger = Logger.new(File.join(log_dir, 'suf.log'), 5, 1_048_576) # 1 MB, 5 files
      @logger.level = Logger::DEBUG
      @logger
    rescue
      # last-ditch fallback so rescue blocks never raise
      @logger = Logger.new($stdout)
    end

    def self.safe_log(ex)
      logger.info("#{ex.class}: #{ex.message}\n#{Array(ex.backtrace).join("\n")}")
    rescue
      # swallow
    end
  end
end
