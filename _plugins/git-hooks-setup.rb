# Jekyll plugin to automatically configure git hooks for the repository.
# This ensures that all developers have the same pre-commit checks without manual setup.

Jekyll::Hooks.register :site, :after_init do |site|
  # Only run in development or when explicitly requested
  next if ENV['JEKYLL_ENV'] == 'production'

  begin
    repo_root = `git rev-parse --show-toplevel 2>/dev/null`.strip
    if !repo_root.empty?
      current_hooks_path = `git config core.hooksPath`.strip
      
      # If not already set to .githooks, set it
      if current_hooks_path != '.githooks'
        system("git config core.hooksPath .githooks")
        Jekyll.logger.info "Git Hooks:", "Configured core.hooksPath to .githooks automatically."
      end
      
      # Ensure hook is executable
      pre_commit_path = File.join(repo_root, '.githooks', 'pre-commit')
      if File.exist?(pre_commit_path) && !File.executable?(pre_commit_path)
        File.chmod(0755, pre_commit_path)
        Jekyll.logger.info "Git Hooks:", "Ensured .githooks/pre-commit is executable."
      end
    end
  rescue => e
    Jekyll.logger.warn "Git Hooks:", "Failed to configure hooks automatically: #{e.message}"
  end
end
