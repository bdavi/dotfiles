# frozen_string_literal: true

require 'fileutils'

# Installs/uninstalls dotfiles
class DotFileManager
  DEFAULT_BACKUP_PATH = '~/original_dotfile_backup'
  DEFAULT_CONFIG_FILES_PATH = '~/code/dotfiles/config_files'

  def install(*args)
    init(*args)
    prepare_backup_dir
    move_existing_dotfiles_to_backup
    create_symbolic_links_to_new_files
  end

  def uninstall(*args)
    init(*args)
    remove_symbolic_links
    copy_dotfile_backups_to_home
    remove_dotfile_backup
  end

  private

  attr_reader :_backup_path, :_config_files_path

  def init(
    config_files_path = DEFAULT_CONFIG_FILES_PATH,
    backup_path = DEFAULT_BACKUP_PATH
  )
    @_config_files_path = File.expand_path(config_files_path)
    @_backup_path       = File.expand_path(backup_path)
  end

  ############################################################################
  # Path Helpers
  ############################################################################
  def file_names
    Dir.new(_config_files_path).reject { |f| f =~ /\A\.{1,2}\z/ }
  end

  def home_path(file_name)
    File.join(Dir.home, file_name)
  end

  def backup_path(file_name = '')
    File.join(_backup_path, file_name)
  end

  def config_path(file_name = '')
    File.join(_config_files_path, file_name)
  end

  ############################################################################
  # Actions to take
  ############################################################################
  def prepare_backup_dir
    Dir.mkdir(backup_path) unless Dir.exist?(backup_path)
  end

  def move_existing_dotfiles_to_backup
    file_names.each do |filename|
      next unless File.exist?(home_path(filename))

      FileUtils.mv(home_path(filename), backup_path(filename))
    end
  end

  def create_symbolic_links_to_new_files
    file_names.each do |filename|
      FileUtils.ln_s(config_path(filename), home_path(filename))
    end
  end

  def remove_symbolic_links
    file_names.each do |filename|
      FileUtils.rm home_path(filename), force: true
    end
  end

  def copy_dotfile_backups_to_home
    return unless Dir.exist?(backup_path)

    file_names.each do |filename|
      next unless File.exist?(backup_path(filename))

      FileUtils.cp(backup_path(filename), home_path(filename))
    end
  end

  def remove_dotfile_backup
    FileUtils.rm_rf(backup_path) if Dir.exist?(backup_path)
  end
end
