# Stats class for collecting git LOC and other stats
class Collector < Cliqr.command
  include Common
  include Gitbase

  def git_init(git_dir)
    cmd = get_cmd("cd #{git_dir};git init")
    `#{cmd}`
  end

  def git_log(_git_dir)
    log_fmt = '%H|%P|%ai|%aN|%aE|%s'
    cmd = get_cmd("cd #{dir_name};git log --all --pretty=format:'#{log_fmt}'")
    puts "\tRunning: #{cmd}"
    `#{cmd}`
  end

  def prepare_log(organization, name, _lines)
    s3 = Aws::S3::Resource.new(region: 'us-east-1')
    bucket = s3.bucket('founderbliss-temp-storage')
    obj = bucket.object("#{organization}_#{name}_git.log")

    # string data
    obj.put(body: @lines)
    obj.presigned_url(:get, expires_in: 86_400)
  end

  def execute(context)
    top_dir_name = context.option('dir_name').value
    organization = context.option('organization').value
    git_base = context.option('git_base').value
    api_key = context.option('api_key').value
    host = context.option('host').value
    aws_credentials = Aws::Credentials.new(
      context.option('aws_key').value,
      context.option('aws_secret').value)
    Aws.config.update(region: 'us-east-1', credentials: aws_credentials)

    agent = Mechanize.new
    auth_headers = { 'X-User-Token' => api_key }

    repos = {}

    dir_list = get_directory_list(top_dir_name)
    dir_list.each do |dir_name|
      name = dir_name.split('/').last
      puts "Working on: #{name}"
      params = {
        name: name,
        full_name: "#{organization}/#{name}",
        git_url: File.join(git_base.to_s, name)
      }

      checkout_commit(dir_name, 'master')
      cmd = get_cmd("cd #{dir_name};git pull")
      puts "\tRunning: #{cmd}"
      `#{cmd}`

      lines = git_log(git_dir)

      repo_return = agent.post("#{host}/api/repo.json", params, auth_headers)
      puts "\tCreate repo: #{repo_return.body}"
      json_return = JSON.parse(repo_return.body)
      repos[name] = json_return
      repo_key = json_return['repo_key']

      log_url = prepare_log(organization, name, lines)

      agent.post(
        "#{host}/api/gitlog",
        { repo_key: repo_key, git_log_url: log_url },
        auth_headers)
    end

    save_bliss_file(top_dir_name, repos)
  end
end
