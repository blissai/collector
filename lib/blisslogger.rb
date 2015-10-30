class BlissLogger
  def initialize(org_name)
    @logger = Logger.new("#{File.expand_path('~/collector/logs/blisslog.txt')}", 'daily')
    @aws_log = ""
    @org_name = org_name
  end

  def log_to_aws(line)
    log_line = "#{Time.now.strftime("%d-%m-%y-T%H-%M")} - #{line}"
    @aws_log += log_line + "\n"
  end

  def error(line)
    @logger.error(line)
    log_to_aws("Error: #{line}")
  end

  def info(line)
    @logger.info(line)
    log_to_aws("Info: #{line}")
  end

  def warn(line)
    @logger.warn(line)
    log_to_aws("Warn: #{line}")
  end

  def save_log
    if !@aws_log.empty?
      object_params = {
        bucket: 'bliss-collector-logs',
        key: "#{@org_name}-#{Time.now.strftime("%d-%m-%y-T%H-%M")}",
        body: @aws_log,
        requester_pays: true,
        acl: 'bucket-owner-read'
      }
      $aws_client.put_object(object_params)
    end
  end
end
