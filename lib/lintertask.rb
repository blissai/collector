# Stats class for collecting git LOC and other stats
class LinterTask
  include Common
  include Gitbase

  def execute(top_dir_name, api_key, host)
    agent = Mechanize.new
    auth_headers = { 'X-User-Token' => api_key }

    repos = read_bliss_file(top_dir_name)
    dir_names = []

    dir_list = get_directory_list(top_dir_name)
    dir_list.each do |git_dir|
      name = git_dir.split('/').last
      repo = repos[name]
      organization = repo['full_name'].split('/').first
      repo_key = repo['repo_key']

      repo_return = agent.get(
        "#{host}/api/gitlog/linters_todo?repo_key=#{repo_key}",
        auth_headers)
      json_return = JSON.parse(repo_return.body)

      linters = json_return['linters']
      lint_installer = LintInstaller.new(linters, git_dir)
      lint_installer.install_dependencies
      linters.each do |linter|
        ext = linter['output_format']
        cd_first = linter['cd_first']
        quality_tool = linter['quality_tool']
        quality_command = linter ['quality_command']
        metrics = json_return['metrics']

        puts "Working on repo: #{git_dir}"
        metrics.each do |metric|
          Dir.mktmpdir do |dir_name|
            commit = metric['commit']
            checkout_commit(git_dir, commit)

            remove_open_source_files(git_dir)

            proj_filename = nil

            file_name = File.join(dir_name, "#{quality_tool}.#{ext}")

            cmd = quality_command.gsub('git_dir', git_dir).gsub('file_name', file_name).gsub('proj_filename', proj_filename.to_s)
            cmd = get_cmd("cd #{git_dir};#{cmd}") if cd_first
            puts "Running: #{cmd}"
            `#{cmd}`

            s3 = Aws::S3::Resource.new(region: 'us-east-1')
            bucket = s3.bucket('founderbliss-temp-storage')
            obj = bucket.object("#{organization}_#{name}_#{commit}.#{ext}")

            # string data
            obj.put(body: File.open(file_name, 'r').read)
            lint_file_url = obj.presigned_url(:get, expires_in: 86_400)

            lint_payload = {
              commit: commit,
              repo_key: repo_key,
              linter_id: linter['id'],
              lint_file_location: lint_file_url }

            lint_response = agent.post(
                "#{host}/api/commit/lint",
                lint_payload,
                auth_headers)

            lint_return = JSON.parse(lint_response.body)
            puts "\t\tlint_response: #{lint_return.inspect}"
          end

        end
      end

      # Go back to master at the end
      checkout_commit(git_dir, 'master')
    end

    puts dir_names.join
  end
end