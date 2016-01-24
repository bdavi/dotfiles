require 'fileutils'

################################################################################
# DotFileManager
################################################################################
class DotFileManager
  DEFAULT_DOTFILE_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "files")
  BACKUP_DOTFILE_PATH = File.join(Dir.home, 'original_dotfile_backup')
  
  def initialize path_to_dotfiles = nil 
    @path_to_dotfiles = (path_to_dotfiles || DEFAULT_DOTFILE_PATH)
    @files_to_install = Dir.new(@path_to_dotfiles)
                           .reject {|f| f =~ /\A\.{1,2}\z/ }
  end

  def install
    puts "Installing dotfiles."
    prepare_backup_dir_for_existing_dotfiles
    move_existing_dotfiles_to_backup
    create_symbolic_links_to_new_files
    puts "Complete"
  end

  def uninstall
    puts "Uninstalling dotfiles."
    remove_symbolic_links
    copy_dotfile_backups_to_home
    remove_dotfile_backup
    puts "Complete"
  end
  
private
  def prepare_backup_dir_for_existing_dotfiles
      Dir.mkdir(BACKUP_DOTFILE_PATH) unless Dir.exist?(BACKUP_DOTFILE_PATH)
  end

  def move_existing_dotfiles_to_backup
    @files_to_install.each do |filename|
      from = File.join(Dir.home, filename)
      to = File.join(BACKUP_DOTFILE_PATH, filename)
      FileUtils.mv(from, to) if File.exist?(from)
    end
  end

  def create_symbolic_links_to_new_files 
    @files_to_install.each do |filename|
      link_from = File.join(Dir.home, filename)  
      link_to = File.join(@path_to_dotfiles, filename)
      FileUtils.ln_s(link_to, link_from) 
    end
  end

  def remove_symbolic_links
    links_to_remove = @files_to_install.map {|filename| File.join(Dir.home, filename)}
    FileUtils.rm links_to_remove, force: true
  end

  def copy_dotfile_backups_to_home
    @files_to_install.each do |filename|
      from = File.join(BACKUP_DOTFILE_PATH, filename)
      to = File.join(Dir.home, filename)
      FileUtils.cp(from, to) if File.exist?(from) 
    end
  end
  
  def remove_dotfile_backup
    FileUtils.rm_rf BACKUP_DOTFILE_PATH
  end
end

################################################################################
# Main / Script
################################################################################
INVALID_PARAMETERS_MESSAGE = "Invalid parameters."
VALID_FIRST_ARGS = DotFileManager.new.public_methods(false)

def args_are_valid
  VALID_FIRST_ARGS.include? ARGV[0].to_sym
end

def main
  abort(INVALID_PARAMETERS_MESSAGE) unless args_are_valid
  DotFileManager.new.send(ARGV[0])
end

if __FILE__ == $0
  main
end
