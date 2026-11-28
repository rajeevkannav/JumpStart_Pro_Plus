# Sudo mode: sensitive actions require the user to have entered their
# password recently (see Session::SUDO_DURATION).
#
#   class EmailsController < ApplicationController
#     require_sudo only: %i[ edit update ]
#   end
module RequireSudo
  extend ActiveSupport::Concern

  class_methods do
    def require_sudo(**options)
      before_action :enforce_sudo, **options
    end
  end

  private
    def enforce_sudo
      return if Current.session&.sudo?

      redirect_to new_sudo_path(return_to: sudo_return_to)
    end

    # Where to send the user after they confirm their password. Non-GET
    # actions (e.g. DELETE) can't be replayed by a redirect, so controllers
    # protecting them should override this with a page to come back to.
    def sudo_return_to
      request.fullpath
    end

    # Only same-origin, relative paths are accepted ("/settings"), never
    # protocol-relative ("//evil.com"), backslash tricks or absolute URLs.
    def safe_return_to(value)
      path = value.to_s
      return unless path.start_with?("/")
      return if path.start_with?("//", "/\\") || path.match?(/[\\\r\n\t]/)

      uri = URI.parse(path)
      path if uri.scheme.nil? && uri.host.nil?
    rescue URI::InvalidURIError
      nil
    end
end
