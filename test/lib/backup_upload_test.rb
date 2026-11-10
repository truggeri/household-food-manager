require "test_helper"
require "open3"
require "tmpdir"
require "fileutils"

class BackupUploadTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("household-upload")
    FileUtils.mkdir_p([ "#{@directory}/script", "#{@directory}/tools" ])
    FileUtils.cp(Rails.root.join("script/backup"), "#{@directory}/script/backup")
    @backup = "#{@directory}/storage/backups/household-test.sqlite3"
    @aws_log = "#{@directory}/aws.log"
    @docker_log = "#{@directory}/docker.log"
    write_tool("docker", <<~SH)
      printf '%s\\n' "$@" > "$DOCKER_LOG"
      if [ "${FAIL_LOCAL:-0}" = 1 ]; then echo "database failure" >&2; exit 1; fi
      mkdir -p storage/backups
      printf 'fake backup' > storage/backups/household-test.sqlite3
      echo storage/backups/household-test.sqlite3
    SH
    write_tool("aws", <<~SH)
      printf '%s\\n' "$@" > "$AWS_LOG"
      if [ "${FAIL_UPLOAD:-0}" = 1 ]; then echo "upload failure" >&2; exit 1; fi
    SH
    @env = {
      "PATH" => "#{@directory}/tools:#{ENV.fetch('PATH')}",
      "AWS_LOG" => @aws_log, "DOCKER_LOG" => @docker_log,
      "B2_BUCKET" => "private-household", "B2_ENDPOINT_URL" => "https://s3.us-west-004.backblazeb2.com",
      "AWS_DEFAULT_REGION" => "us-west-004"
    }
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "local mode backs up through Compose without invoking AWS" do
    output, error, status = run_script
    assert status.success?, error
    assert_match(/Local backup available:/, output)
    assert File.file?(@backup)
    assert_not File.exist?(@aws_log)
    assert_equal %w[compose exec -T web bin/backup], File.readlines(@docker_log, chomp: true)
  end

  test "B2 upload uses the endpoint and a unique backup object key" do
    output, error, status = run_script("--upload-b2")
    assert status.success?, error
    assert_match(/B2 upload complete:/, output)
    assert_equal [
      "--endpoint-url", @env["B2_ENDPOINT_URL"], "s3", "cp",
      "storage/backups/household-test.sqlite3",
      "s3://private-household/household-food-manager/household-test.sqlite3", "--only-show-errors"
    ], File.readlines(@aws_log, chomp: true)
  end

  test "local failure is nonzero and does not upload" do
    @env["FAIL_LOCAL"] = "1"
    output, error, status = run_script("--upload-b2")
    assert_not status.success?
    assert_match(/Local backup failed/, error)
    assert_no_match(/upload complete/, output)
    assert_not File.exist?(@aws_log)
  end

  test "upload failure is nonzero and preserves the local backup" do
    @env["FAIL_UPLOAD"] = "1"
    output, error, status = run_script("--upload-b2")
    assert_not status.success?
    assert_match(/B2 upload failed; local backup retained:/, error)
    assert_no_match(/upload complete/, output)
    assert File.file?(@backup)
  end

  test "missing configuration fails before running the backup" do
    @env["B2_BUCKET"] = nil
    _output, error, status = run_script("--upload-b2")
    assert_not status.success?
    assert_match(/B2_BUCKET/, error)
    assert_not File.exist?(@docker_log)
  end

  test "non-B2 endpoints are rejected before any data is read" do
    @env["B2_ENDPOINT_URL"] = "http://example.com"
    _output, error, status = run_script("--upload-b2")
    assert_not status.success?
    assert_match(/HTTPS endpoint/, error)
    assert_not File.exist?(@docker_log)
  end

  private

  def write_tool(name, body)
    path = "#{@directory}/tools/#{name}"
    File.write(path, "#!/bin/sh\nset -eu\n#{body}")
    File.chmod(0o700, path)
  end

  def run_script(*arguments)
    Open3.capture3(@env, "sh", "#{@directory}/script/backup", *arguments)
  end
end
