require 'tty-prompt'
require 'tty-progressbar'

module Ulock
  PROMPT = TTY::Prompt.new
  EXCLUDE_EXTENSIONS = ['.md', '.txt']
  class << self
    def files(glob)
      Dir.glob(glob).reject { |f| File.directory?(f) }
    end

    def encrypted_files
      files('**/*.gpg')
    end

    def other_files
      glb = "**/*[!.gpg,#{EXCLUDE_EXTENSIONS.join(",")}]"
      files(glb) 
    end

    def missing_decrypted_version
      of = other_files
      encrypted_files.select { |filename| !of.include?(filename.gsub(/.gpg/, '')) }
    end

    def missing_encrypted_version
      ef = encrypted_files
      other_files.select { |filename| !ef.include?(filename + '.gpg') }
    end

    def encrypt_file(filename, recipient)
      `gpg -r #{recipient} -e #{filename}`
    end

    def decrypt_file(encrypted_filename)
      dest_filename = encrypted_filename.gsub('.gpg', '')
      `gpg -d #{encrypted_filename} > #{dest_filename}`
    end

    def decrypt_multiple(filenames)
      bar = TTY::ProgressBar.new("Decrypting :filename [:bar]", total: filenames.length * 5)
      filenames.each do |file|
        decrypt_file file
        bar.advance 5, filename: file
      end
      bar.finish
    end

    def encrypt_multiple(filenames, recipient)
      bar = TTY::ProgressBar.new("Encrypting :filename [:bar]", total: filenames.length * 5)
      filenames.each do |file|
        bar.advance 5, filename: file
        encrypt_file file, recipient
      end
      bar.finish
    end
  end

  class Interface
    def initialize(recipient=nil)
      @recipient = recipient
    end

    def status
      ef = Ulock.missing_decrypted_version
      if ef.any?
        PROMPT.say "#{ef.count} files to be decrypted:", color: :bright_magenta
        PROMPT.say ef.join("\n"), color: :magenta
        puts "\n"
      else
        PROMPT.say "No files to be decrypted"
      end

      df = Ulock.missing_encrypted_version
      if df.any?
        PROMPT.say "#{df.count} files to be encrypted: \r", color: :bright_blue
        PROMPT.say df.join("\n"), color: :blue
        puts "\n"
      else
        PROMPT.say "No files to be encrypted"
      end

    end

    def shorthelp
      if any?
        PROMPT.say "#{$0} fix all #encrypt and decrypt all", color: :red
        PROMPT.say "#{$0} interactive #encrypt and decrypt interactively", color: :red
      end

      PROMPT.say "#{$0} --help #for more", color: :red
    end

    def any?
      Ulock.missing_encrypted_version.any? || Ulock.missing_decrypted_version.any?
    end

    def get_recipient!
      if !@recipient
        @recipient = PROMPT.ask("Encryption recipient: ")
      end
    end

    def fix_all
      get_recipient!
      PROMPT.say "Encrypting and Decrypting all the files"
      Ulock.encrypt_multiple(Ulock.missing_encrypted_version, @recipient) 
      Ulock.decrypt_multiple(Ulock.missing_decrypted_version) 
    end

    def encrypt(filename)
      get_recipient!
      PROMPT.say "adding an encrypted version of #{filename} (r: #{recipient})"
      Ulock.encrypt_file(filename, @recipient)
    end

    def decrypt(filename)
      PROMPT.say "decrypting #{encrypted_filename} to #{encrypted_filename.gsub('.gpg', '')}"
      Ulock.decrypt_file(filename)
    end

    private def prompt_encrypt
      PROMPT.multi_select "Select files for encryption", Ulock.missing_encrypted_version
    end

    private def prompt_decrypt
      PROMPT.multi_select "Select files for decryption", Ulock.missing_decrypted_version
    end

    def interactive
      get_recipient!
      to_encrypt = prompt_encrypt
      to_decrypt = prompt_decrypt
      Ulock.encrypt_multiple(to_encrypt, @recipient) 
      Ulock.decrypt_multiple(to_decrypt) 
    end
  end
end
