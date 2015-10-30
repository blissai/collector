# Stats class for collecting git LOC and other stats
class LinterTask
  include Common
  include Gitbase

  def execute(top_dir_name, api_key, host)
    $logger.info("Starting Linter.")
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    auth_headers = { 'X-User-Token' => api_key }

    repos = read_bliss_file(top_dir_name)
    dir_names = []

    dir_list = get_directory_list(top_dir_name)

    # Count number of lints to process in total
    total_lints_count = 0
    dir_list.each do |git_dir|
      name = git_dir.split('/').last
      repo = repos[name]
      repo_key = repo['repo_key']
      count_response = agent.get("#{host}/api/gitlog/linters_todo_count?repo_key=#{repo_key}", auth_headers)
      count_json = JSON.parse(count_response.body)
      count = count_json["linters_todo"].to_i
      total_lints_count += count
    end

    total_lints_done = 0

    dir_list.each do |git_dir|
      name = git_dir.split('/').last
      puts "Working on: #{name}".green
      $logger.info("Running Linter on #{name}...")
      repo = repos[name]
      organization = repo['full_name'].split('/').first
      repo_key = repo['repo_key']
      loop do
        repo_return = agent.get(
        "#{host}/api/gitlog/linters_todo?repo_key=#{repo_key}",
        auth_headers)
        json_return = JSON.parse(repo_return.body)
        metrics = json_return['metrics']
        break if metrics.empty?
        linters = json_return['linters']
        linters.each do |linter|
          ext = linter['output_format']
          cd_first = linter['cd_first']
          quality_tool = linter['quality_tool']
          quality_command = linter['quality_command']
          metrics.each do |metric|
            Dir.mktmpdir do |dir_name|
              commit = metric['commit']
              checkout_commit(git_dir, commit)

              remove_open_source_files(git_dir)

              proj_filename = nil

              file_name = File.join(dir_name, "#{quality_tool}.#{ext}")
              cmd = quality_command.gsub('git_dir', git_dir).gsub('file_name', file_name).gsub('proj_filename', proj_filename.to_s)
              cmd = get_cmd("cd #{git_dir};#{cmd}") if cd_first
              puts "\tRunning linter: #{quality_tool}... This may take a while... (#{total_lints_done + 1} / #{total_lints_count})".blue
              $logger.info("Running #{quality_tool} on #{commit}...")
              begin
                lint_output = `#{cmd}`
                if !quality_tool.include? 'cpd'
                  lint_output = File.open(file_name, 'r').read
                end
                puts "\tUploading lint results to AWS...".blue
                key = "#{organization}_#{name}_#{commit}_#{quality_tool}.#{ext}"
                object_params = {
                  bucket: 'founderbliss-temp-storage',
                  key: key,
                  body: lint_output,
                  requester_pays: true,
                  acl: 'bucket-owner-read'
                }
                $aws_client.put_object(object_params)
                lint_payload = { commit: commit, repo_key: repo_key, linter_id: linter['id'], lint_file_location: key }

                lint_response = agent.post("#{host}/api/commit/lint", lint_payload, auth_headers)
                lint_return = JSON.parse(lint_response.body)
              rescue Exception => e
                puts "Your AWS Access Key is invalid...".red if e.is_a? Aws::S3::Errors::InvalidAccessKeyId
                $logger.error("Your AWS Access Key is invalid...") if e.is_a? Aws::S3::Errors::InvalidAccessKeyId
                if e.is_a? Errno::ENOENT
                  puts "#{quality_tool} is not installed. Please refer to the docs at https://github.com/founderbliss/collector to ensure all dependencies are installed.".red
                  $logger.info("Dependency Error: #{quality_tool} not installed...")
                end
              end
              total_lints_done += 1
              percent_done = ((total_lints_done.to_f / total_lints_count.to_f) * 100).to_i rescue 100
              puts "\n\n Finished #{total_lints_done} of #{total_lints_count} lint tasks (#{percent_done}%)\n\n".green
            end
          end
        end
        # Go back to master at the end
        checkout_commit(git_dir, 'master')
      end
      puts dir_names.join
    end
    puts "Linter finished.".green
    $logger.info("Linter finished...")
  end
end
