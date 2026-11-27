module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_session
    helper_method :authenticated?
  end

  def authenticated?
    Current.session.present?
  end

  private

  def set_current_session
    Current.session = Session.find_by(id: cookies.signed[:session_id])
  end
end
