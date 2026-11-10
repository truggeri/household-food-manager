require "test_helper"
require "open3"
require "tmpdir"
require "fileutils"

class BackupTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("household-backup")
    @source_path = File.join(@directory, "production.sqlite3")
    @backups = File.join(@directory, "backups")
  end

  teardown do
    @source&.close
    FileUtils.remove_entry(@directory)
  end

  test "online backup restores committed WAL data while excluding an open transaction" do
    @source = SQLite3::Database.new(@source_path)
    @source.execute("PRAGMA journal_mode=WAL")
    @source.execute("CREATE TABLE inventory (name TEXT)")
    @source.execute("INSERT INTO inventory VALUES ('Frozen soup')")
    @source.execute("BEGIN IMMEDIATE")
    @source.execute("INSERT INTO inventory VALUES ('Uncommitted meal')")
    assert File.size("#{@source_path}-wal").positive?

    output, error, status = run_backup

    assert status.success?, error
    backup_path = output.strip
    assert_match(/Backup saved:/, error)
    assert_equal 0o600, File.stat(backup_path).mode & 0o777
    assert_equal 0o700, File.stat(@backups).mode & 0o777
    assert_empty Dir.glob(File.join(@backups, "*.partial"))
    @source.execute("ROLLBACK")
    @source.close
    @source = nil
    FileUtils.rm_f([ @source_path, "#{@source_path}-wal", "#{@source_path}-shm" ])
    FileUtils.cp(backup_path, @source_path)

    SQLite3::Database.new(@source_path) do |restored|
      assert_equal "ok", restored.get_first_value("PRAGMA integrity_check")
      assert_equal [ [ "Frozen soup" ] ], restored.execute("SELECT name FROM inventory")
    end
  end

  test "backups get unique names and never overwrite previous snapshots" do
    SQLite3::Database.new(@source_path) { |db| db.execute("CREATE TABLE items (id INTEGER)") }
    first, error, status = run_backup
    assert status.success?, error
    second, error, status = run_backup
    assert status.success?, error
    assert_not_equal first, second
    assert File.file?(first.strip)
    assert File.file?(second.strip)
  end

  test "missing source fails without creating an empty database" do
    output, error, status = run_backup
    assert_not status.success?
    assert_empty output
    assert_match(/Backup failed: Database does not exist/, error)
    assert_not File.exist?(@source_path)
  end

  test "corrupt source fails without publishing or leaving a partial backup" do
    File.write(@source_path, "not a SQLite database")
    output, error, status = run_backup
    assert_not status.success?
    assert_empty output
    assert_match(/Backup failed:/, error)
    assert_empty Dir.children(@backups)
  end

  test "unwritable destination fails explicitly" do
    SQLite3::Database.new(@source_path) { |db| db.execute("CREATE TABLE items (id INTEGER)") }
    File.write(@backups, "not a directory")
    output, error, status = run_backup
    assert_not status.success?
    assert_empty output
    assert_match(/Backup failed:/, error)
  end

  private

  def run_backup
    Open3.capture3(RbConfig.ruby, Rails.root.join("bin/backup").to_s, @source_path, @backups)
  end
end
